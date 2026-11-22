function padded = pad_to_multiple(channel, blockSize)

    % Calculate number of rows needed to make height divisible by block size
    rowPad = mod(blockSize - mod(size(channel,1), blockSize), blockSize);

    % Calculate number of columns needed to make width divisible by block size
    colPad = mod(blockSize - mod(size(channel,2), blockSize), blockSize);

    % Add extra rows and columns by repeating the border pixels
    padded = padarray(channel, [rowPad, colPad], 'replicate', 'post');
end