function decoded = rle_decode(encoded)

    % checking for empty
    if isempty(encoded)
        decoded = [];
        return;
        % Nothing to decode
    end

    % Column 1 = the symbol value for each run
    values = encoded(:,1);

    % Column 2 = how many times that value repeats
    counts = encoded(:,2);

    % Expand each value by its run length in one vectorized call
    decoded = repelem(values, counts);    

    % Ensure the output is always a column vector
    decoded = decoded(:);
end