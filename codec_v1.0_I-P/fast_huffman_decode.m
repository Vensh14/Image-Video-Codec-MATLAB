function values = fast_huffman_decode(bitstream, table, lenTable, maxLen, numSymbols)
    
    % Check if there is only one symbol and no bits are needed
    if maxLen == 0
        values = repmat(table, numSymbols, 1);
        return;
    end

    % make row vector and change double to integer
    bitstream = uint32(bitstream(:)');

    % add padding zeros
    padded = [bitstream, zeros(1, maxLen, 'uint32')];

    % create a vector to store output, initially contains zeros
    values = zeros(numSymbols, 1);
    
    % initialize position
    pos = uint32(1);
    n = 1;              % symbol counter

   % Create the first group of bits to check
    window = uint32(0);

    % Take the first maxLen bits and make them one number
    for k = 1:maxLen

        % Shift existing bits left and add the new bit
        window = bitshift(window, 1) + padded(k);
    end

    % Position of the next bit that will enter the window
    nextBit = maxLen + 1;

    % Continue decoding until all symbols are recovered
    while n <= numSymbols

        % Convert the current bits into a table position
        idx = window + 1;

        % Get the symbol stored at that table position
        sym = table(idx);

        % Get how many bits were actually used for this symbol
        len = lenTable(idx);

        % Store the decoded symbol
        values(n) = sym;

        % Move the window forward by the number of bits used
        for k = 1:len

            % Assume the new bit is zero
            newBit = uint32(0);

            % If there are more bits available, take the next bit
            if nextBit <= numel(padded)
                newBit = padded(nextBit);
            end

            % Shift window left, add new bit, and keep only maxLen bits
            window = bitand(bitshift(window,1) + newBit, uint32(2^maxLen - 1));
            nextBit = nextBit + 1;
        end

        % Move to the next output symbol
        n = n + 1;
    end
end