function reconstructed_block = decode_residual_block(decoded_rle, Q, T)

    % Convert RLE data back into the 1D zigzag scanned vector
    r_zigzag_vector = rle_decode(decoded_rle);

    % Convert 1D zigzag vector back into an 8x8 block
    r_quantized_block = reverse_zigzag(r_zigzag_vector);

    % Reverse quantization to recover approximate DCT coefficients
    r_dct_block = r_quantized_block .* Q;

    % Apply inverse DCT to convert frequency data back to spatial block
    reconstructed_block = T' * r_dct_block * T;
end