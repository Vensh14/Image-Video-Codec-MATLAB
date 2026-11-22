function bitstream = fast_huffman_encode(values, dict)

    if size(dict,1) == 1 && isempty(dict{1,2})
        bitstream = [];   % single symbol — no bits needed to encode anything
        return;
    end

    % take the first column
    symbols = cell2mat(dict(:,1));

    % take the second column
    codes = dict(:,2);

    % position of each input symbol
    [~, idx] = ismember(values, symbols);

    % gets corresponding code
    matchedCodes = codes(idx);

    %Combine code to bitstream
    bitstream = [matchedCodes{:}];
end