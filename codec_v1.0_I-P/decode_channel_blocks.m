function reconstructed = decode_channel_blocks(rle, rle_lengths, Q, T, channelSize)

    % Create empty matrix to store reconstructed channel
    reconstructed = zeros(channelSize);

    % Index for moving through RLE data
    idx = 1;

    % Index for moving through block lengths
    blockIndex = 1;

    % Process every 8x8 block in the channel
    for row = 1:8:channelSize(1)
        for col = 1:8:channelSize(2)

            % Get the number of RLE entries belonging to this block
            n = rle_lengths(blockIndex);

            % Extract this block's RLE data and decode it
            decoded = decode_process(rle(idx:idx+n-1, :), Q, T);

            % Place the reconstructed 8x8 block back into the channel
            reconstructed(row:row+7, col:col+7) = decoded;

            % Move to the next block's RLE data
            idx = idx + n;

            blockIndex = blockIndex + 1;
        end
    end
end