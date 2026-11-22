function [dict, encoded_data] = huffman_encode_channel(values)

    % Find all different values present in the input data
    unique_symbols = unique(values);

    % Count how many times each unique value appears
    % The result shows the frequency of each symbol
    probabilities = histcounts(values, [unique_symbols; max(unique_symbols) + 1]);

    % Convert the frequency counts into probability values
    % (Total probability will become 1)
    probabilities = probabilities / length(values);

    % Create the Huffman dictionary using symbols and their probabilities
    % This gives each symbol a binary code
    dict = create_huffman_dict(unique_symbols, probabilities);

    % Replace each symbol in the input with its Huffman code
    % and create the final compressed bitstream
    encoded_data = fast_huffman_encode(values, dict);
end
