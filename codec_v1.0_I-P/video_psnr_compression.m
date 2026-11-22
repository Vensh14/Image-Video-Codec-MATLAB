function video_psnr_compression(fullVideoPath, targetPSNR, filename, pathname)

    % Add codec function path if provided
    if nargin >= 3 && ~isempty(pathname)
        addpath(pathname);
    end

    % Read input video frames
    tic;
    [frames, numFrames, frameRate] = read_video_frames(fullVideoPath);
    
    % Display video information
    fprintf('Total frames read: %d | Frame Rate: %.2f fps\n', numFrames, frameRate);

    % Define GOP parameters
    GOP = 9;
    refSpacing = 1;

    % Classify frames into I, P and B frames
    [~, refFrameIdx, iFrameIdx, pFrameIdx] = ...
        classify_gop_frames(numFrames, GOP, refSpacing);

    % Count frame types
    numI = length(iFrameIdx);
    numP = length(pFrameIdx);

    % Define compression parameters
    T = dctmtx(8);
    blockSize = 16;
    searchRange = 8;

    % Start initial scale calibration
    fprintf('\n--- Calibrating Initial Scales for Target PSNR (%.2f dB) ---\n', targetPSNR);

    % Find initial quantization scales for each frame type
    [initScaleI, initScaleP] = calibrate_initial_scales(frames, T, blockSize, searchRange, ...
        iFrameIdx, pFrameIdx, @calibrate_scale_psnr_loglinear, targetPSNR, targetPSNR, targetPSNR);

    % Display initial scale values
    fprintf('Initial Scales -> I: %.3f | P: %.3f\n', initScaleI, initScaleP);

    % Create storage for reconstructed frames
    reconstructedFrames = cell(numFrames,1);

    % Store PSNR value of each frame
    psnrList = zeros(numFrames,1);

    % Store bits used for each frame
    bitsUsedPerFrame = zeros(numFrames,1);

    % Define controller parameters
    kpSmall = 0.03;
    kpMedium = 0.08;
    kpLarge = 0.18;
    tolerance = 0.05;

    % Encode all I frames
    fprintf('\n--- Encoding Stage 1: All I-Frames ---\n');

    % Set initial I frame scale
    scale = initScaleI;

    % Process each I frame
    for idx = 1:numI
        
        % Get current I frame index
        i = iFrameIdx(idx);

        % Store previous scale value
        oldScale = scale;

        % Compress I frame
        [compressedSize, psnrVal, reconstructedRGB] = intra_compression(frames{i}, scale, T);

        % Store reconstructed frame
        reconstructedFrames{i} = reconstructedRGB;

        % Store PSNR result
        psnrList(i) = psnrVal;

        % Store compressed bits
        bitsUsedPerFrame(i) = compressedSize;

        % Update scale based on PSNR error
        scale = update_scale_psnr_control(scale, psnrVal, targetPSNR, tolerance, kpSmall, kpMedium, kpLarge);

        % Display frame progress
        print_psnr_frame_progress(i, numFrames, 'I', compressedSize, psnrVal, targetPSNR, oldScale, scale);
    end

    % Encode all P frames
    fprintf('\n--- Encoding Stage 2: All P-Frames ---\n');

    % Set initial P frame scale
    scale = initScaleP;

    % Process each P frame
    for idx = 1:numP
        
        % Get current P frame index
        i = pFrameIdx(idx);

        % Store previous scale
        oldScale = scale;

        % Find reference frame position
        refPos = find(refFrameIdx == i);

        % Get previous reconstructed reference frame
        prevRecon = reconstructedFrames{refFrameIdx(refPos - 1)};

        % Compress P frame
        [compressedSize, psnrVal, reconstructedRGB] = compress_p_frame(frames{i}, prevRecon, scale, T, blockSize, searchRange);

        % Store reconstructed frame
        reconstructedFrames{i} = reconstructedRGB;

        % Store PSNR value
        psnrList(i) = psnrVal;

        % Store compressed bits
        bitsUsedPerFrame(i) = compressedSize;

        % Update scale
        scale = update_scale_psnr_control(scale, psnrVal, targetPSNR, tolerance, kpSmall, kpMedium, kpLarge);

        % Display progress
        print_psnr_frame_progress(i, numFrames, 'P', compressedSize, psnrVal, targetPSNR, oldScale, scale);
    end
    
    % Write reconstructed compressed video
    outputPath = write_compressed_video(reconstructedFrames, numFrames, frameRate, filename, pathname, 'compressed_psnr');

    % Calculate total execution time
    timeElapsed = toc / 60;

    % Calculate compression performance values
    [totalBits, achievedBitrate, avgPSNR, compressionRatio] = compute_summary_stats(bitsUsedPerFrame, psnrList, numFrames, frameRate, frames);

    % Display final performance summary
    fprintf('\n==========================================================\n');
    fprintf('            PSNR COMPRESSION PERFORMANCE SUMMARY          \n');
    fprintf('==========================================================\n');
    fprintf('Target PSNR Quality      : %.2f dB\n', targetPSNR);
    fprintf('Achieved Average PSNR    : %.2f dB (Error: %.2f dB)\n', avgPSNR, avgPSNR - targetPSNR);
    fprintf('Resulting Bitrate        : %.2f Mbps\n', achievedBitrate / 1e6);
    fprintf('Compression Ratio        : %.2f : 1\n', compressionRatio);
    fprintf('Time Elapsed             : %.2f minutes\n', timeElapsed);
    fprintf('Output Saved To          : %s\n', outputPath);
    fprintf('==========================================================\n');
end