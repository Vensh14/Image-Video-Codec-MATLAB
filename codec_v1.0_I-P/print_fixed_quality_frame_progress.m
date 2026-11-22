function print_fixed_quality_frame_progress(frameIdx, numFrames, frameTypeLabel, compressedSize, psnrVal, scale)

    % Display current frame compression information in the command window
    fprintf('Frame %3d/%3d [%s] | Bits: %7d | PSNR: %5.2f dB | Fixed Scale: %.3f\n', ...
        frameIdx, numFrames, frameTypeLabel, compressedSize, psnrVal, scale);

end