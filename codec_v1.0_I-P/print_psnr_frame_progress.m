function print_psnr_frame_progress(frameIdx, numFrames, frameTypeLabel, compressedSize, psnrVal, targetPSNR, oldScale, newScale)

    % Display current frame compression and PSNR information
    fprintf('Frame %3d/%3d [%s] | Bits: %7d | PSNR: %5.2f dB | Target: %.2f dB | Scale: %.3f -> %.3f\n', ...
        frameIdx, numFrames, frameTypeLabel, compressedSize, psnrVal, targetPSNR, oldScale, newScale);
end