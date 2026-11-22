% Create Huffman dictionary
% dict: Huffman dictionary output
function dict = create_huffman_dict(unique_symbols, probabilities)
    if isscalar(unique_symbols)
        % Only one symbol present — huffmandict can't build a tree for this.
        % Store the symbol with an empty code as a marker meaning "no bits needed."
        dict = {unique_symbols(1), []};
    else
        % symbols, probabilities exist
        % Ex: if RLE output [(5,3), (2,2), (7,2)] then it analyze through
        % probability of each symbol existance at make huffman dictionary
        dict = huffmandict(unique_symbols, probabilities);
    end
end


%%
%{
%case 1:
unique_symbols = 8;
probabilities = 1;

scalar_dict = create_huffman_dict(unique_symbols, probabilities)


%case 2:
unique_symbols = [1 2 3 4];
probabilities = [0.4 0.3 0.2 0.1];

probability_dict = create_huffman_dict(unique_symbols, probabilities)
%}