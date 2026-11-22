function newScale = update_scale_psnr_control(scale, psnrVal, targetPSNR, tolerance, kpSmall, kpMedium, kpLarge)

    % Calculate difference between required PSNR and achieved PSNR
    qualityErr = targetPSNR - psnrVal;

    % Get the size of the quality error
    absErr = abs(qualityErr);

    % Update scale only if PSNR error is larger than allowed tolerance
    if absErr > tolerance

        % Select correction strength based on PSNR error size
        if absErr > 5.0
            gain = kpLarge;
        elseif absErr > 2.0
            gain = kpMedium;
        else
            gain = kpSmall;
        end

        % Adjust scale based on PSNR error
        scale = scale - gain * qualityErr;
    end

    % Keep scale within valid range
    newScale = max(0.001, min(50.0, scale));
end