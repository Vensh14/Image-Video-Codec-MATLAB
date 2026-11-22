function encoded = rle_encode(vector)

    if isempty(vector)
        encoded = [];
        return;
        % Nothing to encode
    end

    vector = vector(:)';    % Force to a row vector

    % Mark every position where the value differs from the previous one
    % (the first element is always marked true, since it always starts a new run)
    change_idx = [true, vector(1:end-1) ~= vector(2:end)];

    idx = find(change_idx);         % Positions where each new run begins

    % Run length = distance to the start of the next run
    counts = diff([idx, length(vector)+1]);

    % The value at the start of each run
    values = vector(idx);

    % Combine into the [Value, Count] output format
    %This will send to huffman encoding
    encoded = [values(:), counts(:)];
end
