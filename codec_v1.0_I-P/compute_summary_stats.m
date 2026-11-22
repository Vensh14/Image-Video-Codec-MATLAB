function [totalBits, achievedBitrate, avgPSNR, compressionRatio] = compute_summary_stats(bitsUsedPerFrame, psnrList, numFrames, frameRate, frames)

    % Calculate total compressed bits used for all frames
    totalBits = sum(bitsUsedPerFrame);

    % Calculate average bitrate in bits per second
    achievedBitrate = (totalBits / numFrames) * frameRate;

    % Calculate average PSNR value of all reconstructed frames
    avgPSNR = mean(psnrList);

    % Calculate total bits of original uncompressed video
    % Each pixel has 8 bits and numel(frames{1}) gives total values in one frame
    totalOriginalBits = numel(frames{1}) * 8 * numFrames;

    % Compression ratio = original video size / compressed video size
    compressionRatio = totalOriginalBits / totalBits;

end