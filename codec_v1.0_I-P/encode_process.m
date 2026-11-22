function rle_encoded = encode_process(block, Q, T)

    % Convert image pixel values from range 0-255 to range -128 to 127
    % by subtracting 128 before DCT processing
    shifted_block = double(block) - 128;

    % Perform the remaining encoding steps:
    % DCT → quantization → zigzag → RLE
    % using the shifted block, quantization matrix Q, and threshold T
    rle_encoded = encode_residual_block(shifted_block, Q, T);
end
