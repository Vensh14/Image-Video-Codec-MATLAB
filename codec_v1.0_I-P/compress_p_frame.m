function [compressedSizeBits, psnrVal, reconstructedRGB] = compress_p_frame(currFrame, prevFrame, scale, T, blockSize, searchRange)

    % Chroma blocks are half the size because of 4:2:0 chroma subsampling
    chromaBlockSize = blockSize / 2;

    % Convert current and previous frames into YCbCr channels
    [Y_curr, Cb_curr, Cr_curr, originalRows, originalCols] = prepare_ycbcr_channels(currFrame, blockSize, chromaBlockSize);
    [Y_prev, Cb_prev, Cr_prev, ~, ~]                        = prepare_ycbcr_channels(prevFrame, blockSize, chromaBlockSize);

    % Generate quantization matrices according to compression scale
    [Q_Y, Q_C] = quantization_matrix(scale);

    % Get image dimensions
    [rows, cols] = size(Y_curr);
    [rowsC, colsC] = size(Cb_curr);

    % Store RLE data and reconstructed channels
    all_rle_Y  = {};
    all_rle_Cb = {};
    all_rle_Cr = {};

    Y_reconstructed  = zeros(size(Y_curr));
    Cb_reconstructed = zeros(size(Cb_curr));
    Cr_reconstructed = zeros(size(Cr_curr));

    motionBits = 0;

    % Process each macroblock in the frame
    for row = 1:blockSize:rows
        for col = 1:blockSize:cols

            % Extract current luminance block
            currMB_Y = Y_curr(row:row+blockSize-1, col:col+blockSize-1);

            % Find the best matching block in previous frame
            % and generate motion vector
            [dx, dy] = motion_estimation(currMB_Y, Y_prev, row, col, blockSize, searchRange);
            motionBits = motionBits + 16;       % Store bits needed for motion vector

            % Get predicted block from previous frame
            matchedMB_Y = Y_prev(row+dy:row+dy+blockSize-1, col+dx:col+dx+blockSize-1);
            residual_Y = double(currMB_Y) - double(matchedMB_Y);        % Calculate prediction error (residual)

            % Encode and decode residual blocks to simulate reconstruction
            reconMB_Y = zeros(blockSize, blockSize);

            for sr = 1:8:blockSize
                for sc = 1:8:blockSize
                    subY = residual_Y(sr:sr+7, sc:sc+7);

                    % Compress residual using DCT, quantization, zigzag and RLE
                    rleY = encode_residual_block(subY, Q_Y, T);
                    all_rle_Y{end+1} = rleY;

                    % Decode residual to reconstruct the block
                    decY = decode_residual_block(rleY, Q_Y, T);
                    reconMB_Y(sr:sr+7, sc:sc+7) = decY;
                end
            end

            % Reconstruct Y block using predicted block + decoded residual
            Y_reconstructed(row:row+blockSize-1, col:col+blockSize-1) = double(matchedMB_Y) + reconMB_Y;

            % Convert motion vector to chroma position
            chromaRow = (row+1)/2;
            chromaCol = (col+1)/2;

            dxC = round(dx/2);
            dyC = round(dy/2);

            % Find corresponding reference position in chroma channels
            refRowC = chromaRow + dyC;
            refColC = chromaCol + dxC;

            % Keep chroma reference block inside image boundary
            refRowC = max(1, min(refRowC, rowsC - chromaBlockSize + 1));
            refColC = max(1, min(refColC, colsC - chromaBlockSize + 1));

            % Extract current chroma blocks
            currMB_Cb = Cb_curr(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1);
            currMB_Cr = Cr_curr(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1);

            % Get predicted chroma blocks from previous frame
            matchedMB_Cb = Cb_prev(refRowC:refRowC+chromaBlockSize-1, refColC:refColC+chromaBlockSize-1);
            matchedMB_Cr = Cr_prev(refRowC:refRowC+chromaBlockSize-1, refColC:refColC+chromaBlockSize-1);

            % Calculate chroma residuals
            residual_Cb = double(currMB_Cb) - double(matchedMB_Cb);
            residual_Cr = double(currMB_Cr) - double(matchedMB_Cr);

            % Encode chroma residual blocks
            rleCb = encode_residual_block(residual_Cb, Q_C, T);
            rleCr = encode_residual_block(residual_Cr, Q_C, T);

            all_rle_Cb{end+1} = rleCb;
            all_rle_Cr{end+1} = rleCr;

            % Decode residuals for reconstructed frame
            decCb = decode_residual_block(rleCb, Q_C, T);
            decCr = decode_residual_block(rleCr, Q_C, T);

            % Reconstruct chroma channels
            Cb_reconstructed(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1) = double(matchedMB_Cb) + decCb;
            Cr_reconstructed(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1) = double(matchedMB_Cr) + decCr;

        end
    end

    % Combine all block RLE results into one array per channel
    all_rle_Y  = vertcat(all_rle_Y{:});
    all_rle_Cb = vertcat(all_rle_Cb{:});
    all_rle_Cr = vertcat(all_rle_Cr{:});

    % Apply Huffman coding to RLE values of each channel
    [dict_Y,  encoded_data_Y]  = huffman_encode_channel(all_rle_Y(:,1));
    [dict_Cb, encoded_data_Cb] = huffman_encode_channel(all_rle_Cb(:,1));
    [dict_Cr, encoded_data_Cr] = huffman_encode_channel(all_rle_Cr(:,1));

    % Total compressed size includes residual data and motion vector bits
    compressedSizeBits = length(encoded_data_Y) + length(encoded_data_Cb) + length(encoded_data_Cr) + motionBits;

    % Convert reconstructed YCbCr channels back to RGB and calculate PSNR
    [reconstructedRGB, psnrVal] = finalize_reconstruction(Y_reconstructed, Cb_reconstructed, Cr_reconstructed, ...
        originalRows, originalCols, currFrame, true);
end
