function [compressedSizeBits, psnrVal, reconstructedRGB] = intra_compression(rgb_Img, scale, T)

    % Convert RGB image into YCbCr channels
    [Y, Cb, Cr, originalRows, originalCols] = prepare_ycbcr_channels(rgb_Img, 8, 8);

    % Generate quantization matrices based on compression scale
    [Q_Y, Q_C] = quantization_matrix(scale);

    % Get Y channel size
    [rows, cols] = size(Y);

    % Store RLE data for each channel
    all_rle_Y = {};
    all_rle_Cb = {};
    all_rle_Cr = {};

    % Store reconstructed channels
    Y_reconstructed  = zeros(size(Y));
    Cb_reconstructed = zeros(size(Cb));
    Cr_reconstructed = zeros(size(Cr));

    % Process Y channel block by block
    for row = 1:8:rows
        for col = 1:8:cols

            % Predict current block using already reconstructed neighbouring pixels
            predictedBlock_Y = intra_predict_dc(Y_reconstructed, row, col, 8);

            % Get original 8x8 block
            actualBlock_Y = Y(row:row+7, col:col+7);

            % Calculate prediction error
            residual_Y = double(actualBlock_Y) - predictedBlock_Y;

            % Encode residual using DCT, quantization, zigzag and RLE
            rle_Y = encode_residual_block(residual_Y, Q_Y, T);

            % Store encoded block
            all_rle_Y{end+1} = rle_Y;

            % Decode residual to reconstruct this block
            decodedResidual_Y = decode_residual_block(rle_Y, Q_Y, T);

            % Reconstruct block using prediction + residual
            Y_reconstructed(row:row+7, col:col+7) = predictedBlock_Y + decodedResidual_Y;
        end
    end

    % Get chroma channel size (smaller due to subsampling)
    [rowsC, colsC] = size(Cb);

    % Process Cb and Cr channels
    for row = 1:8:rowsC
        for col = 1:8:colsC

            % Cb channel
            predictedBlock_Cb = intra_predict_dc(Cb_reconstructed, row, col, 8);
            actualBlock_Cb = Cb(row:row+7, col:col+7);
            residual_Cb = double(actualBlock_Cb) - predictedBlock_Cb;
            rle_Cb = encode_residual_block(residual_Cb, Q_C, T);
            all_rle_Cb{end+1} = rle_Cb;
            decodedResidual_Cb = decode_residual_block(rle_Cb, Q_C, T);
            Cb_reconstructed(row:row+7, col:col+7) = predictedBlock_Cb + decodedResidual_Cb;



            % Cr channel
            predictedBlock_Cr = intra_predict_dc(Cr_reconstructed, row, col, 8);
            actualBlock_Cr = Cr(row:row+7, col:col+7);
            residual_Cr = double(actualBlock_Cr) - predictedBlock_Cr;
            rle_Cr = encode_residual_block(residual_Cr, Q_C, T);
            all_rle_Cr{end+1} = rle_Cr;
            decodedResidual_Cr = decode_residual_block(rle_Cr, Q_C, T);
            Cr_reconstructed(row:row+7, col:col+7) = predictedBlock_Cr + decodedResidual_Cr;
        end
    end

    % Combine RLE data of all blocks into one array per channel
    all_rle_Y  = vertcat(all_rle_Y{:});
    all_rle_Cb = vertcat(all_rle_Cb{:});
    all_rle_Cr = vertcat(all_rle_Cr{:});

    % Apply Huffman coding to the RLE values of each channel
    [dict_Y, encoded_data_Y] = huffman_encode_channel(all_rle_Y(:,1));
    [dict_Cb, encoded_data_Cb] = huffman_encode_channel(all_rle_Cb(:,1));
    [dict_Cr, encoded_data_Cr] = huffman_encode_channel(all_rle_Cr(:,1));

    % Calculate total compressed size
    compressedSizeBits = length(encoded_data_Y) + length(encoded_data_Cb) + length(encoded_data_Cr);

    % Convert reconstructed channels back to RGB and calculate PSNR
    [reconstructedRGB, psnrVal] = finalize_reconstruction(Y_reconstructed, Cb_reconstructed, Cr_reconstructed, ...
        originalRows, originalCols, rgb_Img, false);
end