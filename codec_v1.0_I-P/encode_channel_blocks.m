function [all_rle, rle_lengths] = encode_channel_blocks(channel, Q, T)

    % Calculate number of 8x8 blocks in the channel
    numBlocks = (size(channel,1)/8) * (size(channel,2)/8);

    % Store RLE data of each block and its length
    all_rle = cell(numBlocks,1);
    rle_lengths = zeros(numBlocks,1);

    blockIndex = 1;

    % Process the channel block by block (8x8 blocks)
    for row = 1:8:size(channel,1)
        for col = 1:8:size(channel,2)

            % Extract current 8x8 block
            block = channel(row:row+7, col:col+7);

            % Apply DCT, quantization, zigzag scan and RLE encoding
            rle = encode_process(block, Q, T);

            % Store RLE result of this block
            all_rle{blockIndex} = rle;

            % Store number of RLE pairs in this block
            rle_lengths(blockIndex) = size(rle,1);

            blockIndex = blockIndex + 1;
        end
    end

    % Combine all block RLE data into one array
    all_rle = vertcat(all_rle{:});
end