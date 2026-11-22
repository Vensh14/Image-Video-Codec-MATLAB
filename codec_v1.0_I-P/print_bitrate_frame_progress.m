function print_bitrate_frame_progress(frameIdx, numFrames, frameTypeLabel, compressedSize, targetThisFrame, psnrVal, oldScale, newScale)

    % Display current frame compression information in the command window
    fprintf('Frame %3d/%3d [%s] | Bits: %7d | Target: %7.0f | PSNR: %5.2f dB | Scale: %.3f -> %.3f\n', ...
        frameIdx, numFrames, frameTypeLabel, compressedSize, targetThisFrame, psnrVal, oldScale, newScale);
end
