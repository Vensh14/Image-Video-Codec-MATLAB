function video_fixed_quality_compression(fullVideoPath, scale, filename, pathname)

    % Read video frames
    [frames, numFrames, frameRate] = read_video_frames(fullVideoPath);

    % DCT and coding parameters
    T = dctmtx(8);
    blockSize = 16;
    searchRange = 8;

    % GOP configuration
    GOP = 9;
    refSpacing = 3;

    [~, refFrameIdx, iFrameIdx, pFrameIdx] = classify_gop_frames(numFrames, GOP, refSpacing);

    % Storage
    reconstructedFrames = cell(numFrames,1);
    psnrList = zeros(numFrames,1);
    bitsUsedPerFrame = zeros(numFrames,1);

    tic
    %% I Frames

    for idx = 1:length(iFrameIdx)
        i = iFrameIdx(idx);

        [bits, psnrVal, reconstructedRGB] = ...
            intra_compression(frames{i}, scale, T);

        reconstructedFrames{i} = reconstructedRGB;
        psnrList(i) = psnrVal;
        bitsUsedPerFrame(i) = bits;

        print_fixed_quality_frame_progress(i, numFrames, 'I', bits, psnrVal, scale);
    end

    %% P Frames

    for idx = 1:length(pFrameIdx)

        i = pFrameIdx(idx);

        refPos = find(refFrameIdx == i);

        prevRecon = reconstructedFrames{refFrameIdx(refPos-1)};

        [bits, psnrVal, reconstructedRGB] = ...
            compress_p_frame(frames{i}, prevRecon,...
            scale,T,blockSize,searchRange);

        reconstructedFrames{i}=reconstructedRGB;
        psnrList(i)=psnrVal;
        bitsUsedPerFrame(i)=bits;

        print_fixed_quality_frame_progress(i, numFrames, 'P', bits, psnrVal, scale);
    end

    % Save output video
    timeElapsed = toc/60;

    if scale == 1
        qualityLevel = 'High';
    elseif scale == 5
        qualityLevel = 'Medium';
    else
        qualityLevel = 'Low';
    end

    outputPath = write_compressed_video(...
        reconstructedFrames,...
        numFrames,...
        frameRate,...
        filename,...
        pathname,...
        sprintf('fixed_quality%s', qualityLevel));

    % Display results

    [~, bitrate, avgPSNR, compressionRatio] = ...
        compute_summary_stats(bitsUsedPerFrame,...
        psnrList,...
        numFrames,...
        frameRate,...
        frames);

    fprintf("\nFixed Quality Mode\n");
    fprintf("Quality : %s\n",qualityLevel);
    fprintf("Average PSNR : %.2f dB\n",avgPSNR);
    fprintf("Bitrate : %.2f Mbps\n",bitrate/1e6);
    fprintf("Compression Ratio : %.2f:1\n",compressionRatio);
    fprintf('Time Elapsed             : %.2f minutes\n',timeElapsed);
    fprintf('Output Saved To          : %s\n',outputPath);
    fprintf('==========================================================\n');
end