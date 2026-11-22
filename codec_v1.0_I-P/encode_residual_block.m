function rle_encoded = encode_residual_block(block, Q, T)

    % Convert block values to double for calculations
    block = double(block);

    % Apply DCT to convert spatial data into frequency components
    dct_Block = T * block * T';

    % Reduce precision by dividing with quantization matrix
    quantized_Block = round(dct_Block ./ Q);

    % Rearrange 8x8 block into 1D vector using zigzag order
    zigzag_vector = zigzag(quantized_Block);

    % Compress repeated values using Run Length Encoding
    rle_encoded = rle_encode(zigzag_vector);
end