function [compressedSize, psnr_val, reconstructedRGB] = image_compression(rgb_Img, scale, T)

    % Convert RGB image into Y, Cb, Cr channels and prepare image blocks
    [Y, Cb, Cr, originalRows, originalCols] = prepare_ycbcr_channels(rgb_Img, 8, 8);

    % Generate quantization matrices for brightness (Y) and color (Cb, Cr)
    % based on the selected compression scale
    [Q_Y, Q_C] = quantization_matrix(scale);

    % Encode each channel block:
    % DCT -> quantization -> zigzag -> RLE
    [all_rle_Y,  rle_lengths_Y]  = encode_channel_blocks(Y,  Q_Y, T);
    [all_rle_Cb, rle_lengths_Cb] = encode_channel_blocks(Cb, Q_C, T);
    [all_rle_Cr, rle_lengths_Cr] = encode_channel_blocks(Cr, Q_C, T);

    % Separate the run counts from RLE data
    count_Y  = all_rle_Y(:,2);
    count_Cb = all_rle_Cb(:,2);
    count_Cr = all_rle_Cr(:,2);

    % Create Huffman dictionary for each channel and encode the RLE values
    [dict_Y,  encoded_data_Y]  = huffman_encode_channel(all_rle_Y(:,1));
    [dict_Cb, encoded_data_Cb] = huffman_encode_channel(all_rle_Cb(:,1));
    [dict_Cr, encoded_data_Cr] = huffman_encode_channel(all_rle_Cr(:,1));

    % Calculate total compressed size from all three Huffman bitstreams
    compressedSize = length(encoded_data_Y) + length(encoded_data_Cb) + length(encoded_data_Cr);

    % Store compressed data and required information for decoding
    compressedData.Y = encoded_data_Y;
    compressedData.Cb = encoded_data_Cb;
    compressedData.Cr = encoded_data_Cr;

    compressedData.count_Y = count_Y;
    compressedData.count_Cb = count_Cb;
    compressedData.count_Cr = count_Cr;

    compressedData.dict_Y = dict_Y;
    compressedData.dict_Cb = dict_Cb;
    compressedData.dict_Cr = dict_Cr;

    compressedData.rle_lengths_Y = rle_lengths_Y;
    compressedData.rle_lengths_Cb = rle_lengths_Cb;
    compressedData.rle_lengths_Cr = rle_lengths_Cr;

    % Store image size information needed during reconstruction
    compressedData.image_size = size(Y);

    % For each channel (Y, Cb, Cr), create a Huffman lookup table and
    % decode the compressed bitstream back into RLE values
    [table_Y, lenTable_Y, maxLen_Y] = build_huffman_table(compressedData.dict_Y);
    value_Y = fast_huffman_decode(compressedData.Y, table_Y, lenTable_Y, maxLen_Y, numel(compressedData.count_Y));

    [table_Cb, lenTable_Cb, maxLen_Cb] = build_huffman_table(compressedData.dict_Cb);
    value_Cb = fast_huffman_decode(compressedData.Cb, table_Cb, lenTable_Cb, maxLen_Cb, numel(compressedData.count_Cb));

    [table_Cr, lenTable_Cr, maxLen_Cr] = build_huffman_table(compressedData.dict_Cr);
    value_Cr = fast_huffman_decode(compressedData.Cr, table_Cr, lenTable_Cr, maxLen_Cr, numel(compressedData.count_Cr));

    % Combine decoded Huffman values with their run counts
    % to recreate the RLE encoded data
    rle_Y  = [value_Y(:),  compressedData.count_Y(:)];
    rle_Cb = [value_Cb(:), compressedData.count_Cb(:)];
    rle_Cr = [value_Cr(:), compressedData.count_Cr(:)];

    % Decode each channel:
    % RLE decoding -> inverse zigzag -> dequantization -> IDCT
    Y_reconstructed  = decode_channel_blocks(rle_Y,  rle_lengths_Y,  Q_Y, T, size(Y));
    Cb_reconstructed = decode_channel_blocks(rle_Cb, rle_lengths_Cb, Q_C, T, size(Cb));
    Cr_reconstructed = decode_channel_blocks(rle_Cr, rle_lengths_Cr, Q_C, T, size(Cr));

    % Convert reconstructed YCbCr channels back to RGB image
    % and calculate PSNR compared with the original image
    [reconstructedRGB, psnr_val] = finalize_reconstruction(Y_reconstructed, Cb_reconstructed, Cr_reconstructed, ...
        originalRows, originalCols, rgb_Img, true);
end
