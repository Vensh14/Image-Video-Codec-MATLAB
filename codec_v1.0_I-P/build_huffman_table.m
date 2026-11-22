% builds a lookup table for fast prefix decoding from a Huffman dictionary
function [table, lenTable, maxLen] = build_huffman_table(dict)

    % Check if the dictionary consists of only a single unique symbol with no binary code assigned
    if size(dict,1) == 1 && isempty(dict{1,2})
        % Store the single symbol value directly in table output
        table = dict{1,1};   % just the single symbol value itself
        % Set code length to 0 because no actual bits are required for a single unique symbol
        lenTable = 0;
        % Set maxLen to 0 to signal a trivial single-symbol case to the downstream decoder
        maxLen = 0;           % maxLen = 0 signals "trivial case" to the decoder
        % Early exit from function for single-symbol dictionary
        return;
        % End conditional check for trivial dictionary
    end
    
    % Extract symbol values from first column of dictionary cell array into a numeric array
    symbols = cell2mat(dict(:,1));
    % Extract cell array of binary code vectors from second column of dictionary
    codes = dict(:,2);
    % Calculate length (number of bits) for each Huffman binary code
    lens = cellfun(@length, codes);
    % Find the maximum code length among all generated Huffman codes
    maxLen = max(lens);
    
    % Calculate size of dynamic decoding lookup table based on maximum bit depth (2^maxLen entries)
    tableSize = 2^maxLen;
    % Pre-allocate zero array for symbol lookup table
    table = zeros(tableSize, 1);
    % Pre-allocate zero array for bit length tracking table
    lenTable = zeros(tableSize, 1);
    
    % Loop through each symbol in the dictionary to populate the fast lookup table
    for i = 1:numel(symbols)
        % Retrieve the current binary code array (e.g., [1 0 1])
        code = codes{i};
        % Get length of current binary code
        len = lens(i);
        % Calculate number of right-padding bits needed to align code to maxLen
        padBits = maxLen - len;
        
        % Convert binary vector to decimal integer base index and left-shift by padBits
        base = bin2dec(char(code + '0')) * 2^padBits;
        
        % Generate range of 1-based table indices corresponding to all padded variations of this prefix
        idxRange = (base+1):(base + 2^padBits);
        
        % Assign symbol value to all index locations within the prefix range in lookup table
        table(idxRange) = symbols(i);
        % Assign corresponding bit length to matching index locations in length table
        lenTable(idxRange) = len;
    end
end


%%
%{
clc;
clear;

dict = {
    'A', [0];
    'B', [1 0];
    'C', [1 1 0];
    'D', [1 1 1]
};

% Build lookup table
[table, lenTable, maxLen] = build_huffman_table(dict);

% Display outputs

disp('Maximum Code Length:')
disp(maxLen)

disp('Lookup Table:')
for i = 1:length(table)
    fprintf('Index %d : Symbol = %s, Bits Used = %d\n', ...
        i, table(i), lenTable(i));
end
%}