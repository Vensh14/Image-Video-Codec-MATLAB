function reconstructed_block = decode_process(decoded_rle, Q, T)

    % Reverse the encoding steps:
    % RLE decoding → inverse zigzag → dequantization → IDCT
    % to recover the shifted image block
    residual_block = decode_residual_block(decoded_rle, Q, T);

    % Add 128 back to return pixel values to the original range
    % (undo the subtraction done during encoding)
    reconstructed_block = residual_block + 128;

    % Round decimal pixel values and convert them back to uint8
    % so values are stored as normal image pixels (0 to 255)
    reconstructed_block = uint8(round(reconstructed_block));
end
