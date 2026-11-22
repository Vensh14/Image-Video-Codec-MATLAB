function video_bitrate_compression(fullVideoPath, userBitrateMbps, filename, pathname)

    if nargin >= 3 && ~isempty(pathname)
        addpath(pathname);
        % Add folder containing codec functions
    end

    %% Step 1: Read Video Frames
    tic;

    [frames, numFrames, frameRate] = read_video_frames(fullVideoPath);
    % Read all video frames and get frame count and frame rate

    fprintf('Total frames read: %d | Frame Rate: %.2f fps\n', numFrames, frameRate);

    %% Step 2: GOP Configuration & Frame Classification
    GOP = 9;
    refSpacing = 1;
    % Define GOP size and distance between reference frames

    [~, refFrameIdx, iFrameIdx, pFrameIdx] = ...
        classify_gop_frames(numFrames, GOP, refSpacing);
    % Separate frames into I, P and B types and find their references

    numI = length(iFrameIdx);
    numP = length(pFrameIdx);

    %% Step 3: Bit Budget Allocation
    T = dctmtx(8);
    blockSize = 16;
    searchRange = 8;
    % Set DCT matrix and motion estimation parameters

    userBitrate = userBitrateMbps * 1e6;
    % Convert Mbps to bits per second

    weightI = 1.8;
    weightP = 1.0;
    % Give different importance to each frame type

    totalTargetBits = (userBitrate / frameRate) * numFrames;
    % Total number of bits allowed for the complete video

    totalWeightPool = (numI*weightI) + (numP*weightP);

    % Divide total bits between I, P and B frames
    totalTargetBitsI = totalTargetBits * ((numI*weightI) / totalWeightPool);
    totalTargetBitsP = totalTargetBits * ((numP*weightP) / totalWeightPool);

    % Find average bit budget for one frame of each type
    targetBitsI = totalTargetBitsI / max(1,numI);
    targetBitsP = totalTargetBitsP / max(1,numP);

    %% Step 4: Find Initial Compression Scales
    fprintf('\n--- Calibrating Initial Scales (Log-Linear Method) ---\n');

    [initScaleI, initScaleP] = calibrate_initial_scales(frames, T, blockSize, searchRange, ...
        iFrameIdx, pFrameIdx, refFrameIdx, @calibrate_scale_bitrate_loglinear, targetBitsI, targetBitsP);
    % Estimate starting compression scale for each frame type

    fprintf('Initial Scales -> I: %.3f | P: %.3f\n', ...
        initScaleI, initScaleP);

    %% Step 5: Encode Frames
    reconstructedFrames = cell(numFrames,1);
    % Store reconstructed frames for prediction of future frames

    psnrList = zeros(numFrames,1);
    bitsUsedPerFrame = zeros(numFrames,1);

    % Controller gains for bitrate correction
    kpSmall = 0.03;
    kpMedium = 0.08;
    kpLarge = 0.18;

    %% Encode I Frames
    fprintf('\n--- Encoding Stage 1: All I-Frames ---\n');

    remainingBitsI = totalTargetBitsI;
    scale = initScaleI;

    for idx = 1:numI

        i = iFrameIdx(idx);

        % Calculate bit target for this frame
        targetThisFrame = next_frame_bit_target(remainingBitsI, numI, idx);

        oldScale = scale;

        % Compress I frame using intra prediction
        [compressedSize, psnrVal, reconstructedRGB] = intra_compression(frames{i}, scale, T);

        reconstructedFrames{i} = reconstructedRGB;
        psnrList(i) = psnrVal;
        bitsUsedPerFrame(i) = compressedSize;

        remainingBitsI = remainingBitsI - compressedSize;

        % Adjust scale according to achieved bitrate
        scale = update_scale_bitrate_control(scale, compressedSize, ...
            targetThisFrame, kpSmall, kpMedium, kpLarge);

        print_bitrate_frame_progress(i, numFrames, 'I', compressedSize, ...
            targetThisFrame, psnrVal, oldScale, scale);
    end

    %% Encode P Frames
    fprintf('\n--- Encoding Stage 2: All P-Frames ---\n');

    remainingBitsP = totalTargetBitsP;
    scale = initScaleP;

    for idx = 1:numP

        i = pFrameIdx(idx);

        targetThisFrame = next_frame_bit_target(remainingBitsP, numP, idx);

        % Get previous reconstructed reference frame
        refPos = find(refFrameIdx == i);
        prevRecon = reconstructedFrames{refFrameIdx(refPos-1)};

        oldScale = scale;

        % Compress P frame using motion prediction
        [compressedSize, psnrVal, reconstructedRGB] = ...
            compress_p_frame(frames{i}, prevRecon, scale, T, blockSize, searchRange);

        reconstructedFrames{i} = reconstructedRGB;
        psnrList(i) = psnrVal;
        bitsUsedPerFrame(i) = compressedSize;

        remainingBitsP = remainingBitsP - compressedSize;

        % Update scale for next P frame
        scale = update_scale_bitrate_control(scale, compressedSize,...
            targetThisFrame, kpSmall, kpMedium, kpLarge);

        print_bitrate_frame_progress(i,numFrames,'P',compressedSize,...
            targetThisFrame,psnrVal,oldScale,scale);
    end

    %% Step 6: Save Output and Display Results
    outputPath = write_compressed_video(reconstructedFrames,...
        numFrames,frameRate,filename,pathname,'compressed_bitrate');
    % Write reconstructed frames into output video

    timeElapsed = toc/60;

    [totalBits, achievedBitrate, avgPSNR, compressionRatio] = ...
        compute_summary_stats(bitsUsedPerFrame,psnrList,...
        numFrames,frameRate,frames);

    fprintf('\n==========================================================\n');
    fprintf('           BITRATE COMPRESSION PERFORMANCE SUMMARY        \n');
    fprintf('==========================================================\n');
    fprintf('Target Bitrate           : %.2f Mbps\n',userBitrateMbps);
    fprintf('Achieved Bitrate         : %.2f Mbps\n',achievedBitrate/1e6);
    fprintf('Achieved Average PSNR    : %.2f dB\n',avgPSNR);
    fprintf('Compression Ratio        : %.2f : 1\n',compressionRatio);
    fprintf('Time Elapsed             : %.2f minutes\n',timeElapsed);
    fprintf('Output Saved To          : %s\n',outputPath);
    fprintf('==========================================================\n');
end