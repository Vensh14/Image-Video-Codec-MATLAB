function newScale = update_scale_bitrate_control(scale, compressedSize, targetThisFrame, kpSmall, kpMedium, kpLarge)

    % Calculate how much the actual bits differ from the target bits
    bitErrRel = (compressedSize - targetThisFrame) / targetThisFrame;

    % Get the size of the error without considering its direction
    absErr = abs(bitErrRel);

    % Update scale only if error is larger than 5%
    if absErr > 0.05

        % Select correction strength based on error size
        if absErr > 0.30
            gain = kpLarge;
        elseif absErr > 0.10
            gain = kpMedium;
        else
            gain = kpSmall;
        end

        % Adjust scale based on bitrate error
        scale = scale + gain * bitErrRel * scale;
    end

    % Keep scale within allowed range
    newScale = max(0.001, min(50.0, scale));
end