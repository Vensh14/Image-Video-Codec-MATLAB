function predictedBlock = intra_predict_dc(reconstructedSoFar, row, col, blockSize)

    % Check whether top and left neighbouring pixels are available
    hasTop  = (row > 1);
    hasLeft = (col > 1);

    % Get pixels from the block above
    if hasTop
        topRow = reconstructedSoFar(row-1, col:col+blockSize-1);
    else
        topRow = [];
    end

    % Get pixels from the block on the left
    if hasLeft
        leftCol = reconstructedSoFar(row:row+blockSize-1, col-1);
    else
        leftCol = [];
    end

    % Combine available neighbouring pixels
    neighborPixels = [topRow(:); leftCol(:)];

    % Calculate prediction value
    if isempty(neighborPixels)

        % No neighbours (first block), use middle gray value
        dcValue = 128;

    else

        % Use average of neighbouring pixels as prediction value
        dcValue = mean(double(neighborPixels));
    end

    % Create predicted block using the same value for all pixels
    predictedBlock = ones(blockSize, blockSize) * dcValue;
end