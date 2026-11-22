function [bestDx, bestDy] = motion_estimation(currentBlock, prevFrame, row, col, blockSize, searchRange)

    % Get previous frame size
    [frameRows, frameCols] = size(prevFrame);

    % Start from no movement position
    centerDx = 0;
    centerDy = 0;

    % Set initial search step size
    step = max(1, floor(searchRange / 2));

    % Store the smallest SAD value found
    minSAD = inf;

    % Continue searching until step becomes 1
    while step >= 1

        % Assume current center position is the best
        bestLocalDx = centerDx;
        bestLocalDy = centerDy;

        % Check 9 nearby positions around current center
        for dy = -step:step:step
            for dx = -step:step:step

                % Calculate new motion position
                testDx = centerDx + dx;
                testDy = centerDy + dy;

                % Calculate corresponding position in previous frame
                refRow = row + testDy;
                refCol = col + testDx;

                % Ignore positions outside the frame
                if refRow < 1 || refCol < 1 || ...
                   (refRow + blockSize - 1) > frameRows || ...
                   (refCol + blockSize - 1) > frameCols
                    continue;
                end

                % Get candidate block from previous frame
                candidateBlock = prevFrame(refRow:refRow+blockSize-1, ...
                                           refCol:refCol+blockSize-1);

                % Calculate difference between current and candidate block
                SAD = sum(abs(double(currentBlock(:)) - double(candidateBlock(:))));

                % Update best position if this match is better
                if SAD < minSAD
                    minSAD = SAD;
                    bestLocalDx = testDx;
                    bestLocalDy = testDy;
                end
            end
        end

        % Move search center to the best location found
        centerDx = bestLocalDx;
        centerDy = bestLocalDy;

        % Reduce step size for finer search
        step = floor(step / 2);
    end

    % Return final motion vector
    bestDx = centerDx;
    bestDy = centerDy;
end