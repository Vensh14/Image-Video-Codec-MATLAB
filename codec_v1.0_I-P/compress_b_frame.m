%{
function [compressedSizeBits, psnrVal, reconstructedRGB] = compress_b_frame(currFrame, pastFrame, futureFrame, scale, T, blockSize, searchRange)

    % Chroma blocks are half the size due to 4:2:0 chroma subsampling
    chromaBlockSize = blockSize / 2;

    % Convert current, past reference, and future reference frames into YCbCr
    [Y_curr,   Cb_curr,   Cr_curr,   originalRows, originalCols] = prepare_ycbcr_channels(currFrame,   blockSize, chromaBlockSize);
    [Y_past,   Cb_past,   Cr_past,   ~, ~]                       = prepare_ycbcr_channels(pastFrame,   blockSize, chromaBlockSize);
    [Y_future, Cb_future, Cr_future, ~, ~]                       = prepare_ycbcr_channels(futureFrame, blockSize, chromaBlockSize);

    % Generate quantization matrices according to compression scale
    [Q_Y, Q_C] = quantization_matrix(scale);

    % Get image dimensions
    [rows, cols] = size(Y_curr);
    [rowsC, colsC] = size(Cb_curr);

    % Store RLE data and reconstructed channels
    all_rle_Y = {};
    all_rle_Cb = {};
    all_rle_Cr = {};

    Y_reconstructed  = zeros(size(Y_curr));
    Cb_reconstructed = zeros(size(Cb_curr));
    Cr_reconstructed = zeros(size(Cr_curr));

    motionBits = 0;

    % Process each macroblock
    for row = 1:blockSize:rows
        for col = 1:blockSize:cols

            % Extract current luminance block
            currMB_Y = Y_curr(row:row+blockSize-1, col:col+blockSize-1);

            % Find motion vectors from both past and future reference frames
            [dxPast, dyPast] = motion_estimation(currMB_Y, Y_past, row, col, blockSize, searchRange);
            [dxFuture, dyFuture] = motion_estimation(currMB_Y, Y_future, row, col, blockSize, searchRange);

            % Store bits required for two motion vectors
            motionBits = motionBits + 32;

            % Get matching blocks from past and future frames
            matchedMB_Y_past = Y_past(row+dyPast:row+dyPast+blockSize-1, col+dxPast:col+dxPast+blockSize-1);
            matchedMB_Y_future = Y_future(row+dyFuture:row+dyFuture+blockSize-1, col+dxFuture:col+dxFuture+blockSize-1);

            % Generate B-frame prediction by averaging both reference blocks
            predictedMB_Y = (double(matchedMB_Y_past) + double(matchedMB_Y_future)) / 2;

            % Calculate prediction error
            residual_Y = double(currMB_Y) - predictedMB_Y;

            % Encode and reconstruct luminance residual blocks
            reconMB_Y = zeros(blockSize, blockSize);

            for sr = 1:8:blockSize
                for sc = 1:8:blockSize
                    subY = residual_Y(sr:sr+7, sc:sc+7);
                    rleY = encode_residual_block(subY, Q_Y, T);
                    all_rle_Y{end+1} = rleY;
                    decY = decode_residual_block(rleY, Q_Y, T);
                    reconMB_Y(sr:sr+7, sc:sc+7) = decY;
                end
            end

            % Reconstruct luminance using prediction + decoded residual
            Y_reconstructed(row:row+blockSize-1, col:col+blockSize-1) = predictedMB_Y + reconMB_Y;

            % Convert motion vectors to chroma positions
            chromaRow = (row+1)/2;
            chromaCol = (col+1)/2;

            dxPastC = round(dxPast/2);
            dyPastC = round(dyPast/2);

            dxFutureC = round(dxFuture/2);
            dyFutureC = round(dyFuture/2);

            % Find reference positions for chroma blocks
            refRowPastC = max(1, min(chromaRow+dyPastC, rowsC-chromaBlockSize+1));
            refColPastC = max(1, min(chromaCol+dxPastC, colsC-chromaBlockSize+1));

            refRowFutureC = max(1, min(chromaRow+dyFutureC, rowsC-chromaBlockSize+1));
            refColFutureC = max(1, min(chromaCol+dxFutureC, colsC-chromaBlockSize+1));

            % Extract current chroma blocks
            currMB_Cb = Cb_curr(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1);
            currMB_Cr = Cr_curr(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1);

            % Get matching chroma blocks from both reference frames
            matchedMB_Cb_past = Cb_past(refRowPastC:refRowPastC+chromaBlockSize-1, refColPastC:refColPastC+chromaBlockSize-1);
            matchedMB_Cb_future = Cb_future(refRowFutureC:refRowFutureC+chromaBlockSize-1, refColFutureC:refColFutureC+chromaBlockSize-1);

            matchedMB_Cr_past = Cr_past(refRowPastC:refRowPastC+chromaBlockSize-1, refColPastC:refColPastC+chromaBlockSize-1);
            matchedMB_Cr_future = Cr_future(refRowFutureC:refRowFutureC+chromaBlockSize-1, refColFutureC:refColFutureC+chromaBlockSize-1);

            % Generate chroma prediction by averaging past and future blocks
            predictedMB_Cb = (double(matchedMB_Cb_past) + double(matchedMB_Cb_future)) / 2;
            predictedMB_Cr = (double(matchedMB_Cr_past) + double(matchedMB_Cr_future)) / 2;

            % Calculate chroma residuals
            residual_Cb = double(currMB_Cb) - predictedMB_Cb;
            residual_Cr = double(currMB_Cr) - predictedMB_Cr;

            % Encode chroma residuals
            rleCb = encode_residual_block(residual_Cb, Q_C, T);
            rleCr = encode_residual_block(residual_Cr, Q_C, T);

            all_rle_Cb{end+1} = rleCb;
            all_rle_Cr{end+1} = rleCr;

            % Decode residuals for reconstruction
            decCb = decode_residual_block(rleCb, Q_C, T);
            decCr = decode_residual_block(rleCr, Q_C, T);

            % Reconstruct chroma channels
            Cb_reconstructed(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1) = predictedMB_Cb + decCb;
            Cr_reconstructed(chromaRow:chromaRow+chromaBlockSize-1, chromaCol:chromaCol+chromaBlockSize-1) = predictedMB_Cr + decCr;
        end
    end

    % Combine block RLE data into complete channel data
    all_rle_Y  = vertcat(all_rle_Y{:});
    all_rle_Cb = vertcat(all_rle_Cb{:});
    all_rle_Cr = vertcat(all_rle_Cr{:});

    % Apply Huffman coding to RLE values
    [dict_Y, encoded_data_Y] = huffman_encode_channel(all_rle_Y(:,1));
    [dict_Cb, encoded_data_Cb] = huffman_encode_channel(all_rle_Cb(:,1));
    [dict_Cr, encoded_data_Cr] = huffman_encode_channel(all_rle_Cr(:,1));

    % Calculate total compressed size including motion vector information
    compressedSizeBits = length(encoded_data_Y) + length(encoded_data_Cb) + length(encoded_data_Cr) + motionBits;

    % Convert reconstructed YCbCr channels back to RGB and calculate PSNR
    [reconstructedRGB, psnrVal] = finalize_reconstruction(Y_reconstructed, Cb_reconstructed, Cr_reconstructed, ...
        originalRows, originalCols, currFrame, true);
end
%}