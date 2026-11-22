function calibratedScale = calibrate_scale_psnr_loglinear(encodeFcn, targetPSNR)

    % Find the compression scale that achieves the required PSNR value
    % encodeFcn   -> compression function that accepts a scale value
    % targetPSNR -> required image quality in dB
    % Call the general calibration function:
    % metricIndex = 2 means use the second output (PSNR)
    % false means do not use logarithm for PSNR values
    calibratedScale = calibrate_scale_core(encodeFcn, targetPSNR, 2, false);
end
