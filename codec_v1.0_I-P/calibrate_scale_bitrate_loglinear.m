function calibratedScale = calibrate_scale_bitrate_loglinear(encodeFcn, targetBits)

    % Find the compression scale that gives the required bitrate
    % using logarithmic linear estimation
    % encodeFcn  -> function that compresses the image/frame using a scale
    % targetBits -> required compressed size in bits
    calibratedScale = calibrate_scale_core(encodeFcn, targetBits, 1, true);
end
