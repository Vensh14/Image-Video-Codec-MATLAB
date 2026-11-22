function calibratedScale = calibrate_scale_core(encodeFcn, target, metricIndex, useLogMetric)

    % First test scale value
    s1 = 0.5;

    % Create a temporary storage for encoder outputs
    outputs1 = cell(1,3);

    % Run compression using first scale
    [outputs1{:}] = encodeFcn(s1);

    % Select the required output value (size/PSNR/etc.)
    metric1 = outputs1{metricIndex};

    % Second test scale value
    s2 = 3.0;

     % Create storage for second encoder output
    outputs2 = cell(1,3);

    % Run compression using second scale
    [outputs2{:}] = encodeFcn(s2);

    % Select the required output value
    metric2 = outputs2{metricIndex};

    % Convert scale values into logarithmic form
    logS1 = log(s1);
    logS2 = log(s2);

    % If metric changes exponentially, use logarithmic values
    if useLogMetric
        m1 = log(double(metric1));      % Convert first measurement into log scale
        m2 = log(double(metric2));      % Convert second measurement into log scale
        targetM = log(double(target));  % Convert target into log scale
        
    else
        % Use normal values directly
        m1 = metric1;
        m2 = metric2;
        targetM = target;
        
    end

    % Check if both measurements are almost the same
    if abs(m2 - m1) < 1e-4
        calibratedScale = s1;       % Cannot estimate properly, so keep first scale
    else
        slope = (m2 - m1) / (logS2 - logS1);        % Calculate the rate of change between the two tested points
        logEstS = logS1 + (targetM - m1) / slope;   % Estimate the scale that gives the target value
        calibratedScale = exp(logEstS);             % Convert back from log scale to normal scale 
    end

    % Limit scale value between 0.01 and 50
    calibratedScale = max(0.01, min(50.0, calibratedScale));
end
