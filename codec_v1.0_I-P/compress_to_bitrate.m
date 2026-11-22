function [bestScale, finalSize, finalPSNR, finalRGB] = compress_to_bitrate(rgb_Img, targetBits, T)

    % Initial search range for compression scale
    % Smaller scale = less compression, larger scale = more compression
    lowScale  = 0.05;
    highScale = 1;

    % Compress using the initial high scale and check the output size
    % Store the encoded result also
    [sizeBits, bestData] = image_compression_encode_only(rgb_Img, highScale, T);

    % Maximum number of times to increase the scale
    maxDoublings = 15;

    % Counting of how many times scale is increased
    doubling = 0;

    % Store previous size to check if compression stops changing
    prevSize = -1;

    % Increase compression until the file size becomes smaller than target
    while sizeBits > targetBits && doubling < maxDoublings
        if sizeBits == prevSize
            warning('Compressed size has stopped shrinking (%d bits) - target %d bits may be unreachable for this image.', sizeBits, targetBits);
            break;
        end

        % Save current size for next comparison
        prevSize = sizeBits;

        % Move current high scale to low scale
        lowScale  = highScale;

        % Increase scale to increase compression
        highScale = highScale * 2;

        % Compress again using the new scale and check size
        [sizeBits, bestData] = image_compression_encode_only(rgb_Img, highScale, T);
        
        doubling = doubling + 1;
    end

     % If maximum searching attempts reached but target is not achieved
    if doubling >= maxDoublings && sizeBits > targetBits
        warning('Target bitrate %d may be unreachable for this image even at high compression.', targetBits);
    end

    % Store current scale and size as the best available result
    bestScale = highScale;
    finalSize = sizeBits;

    % Accuracy allowed for binary search
    tol = 0.005;

    % Binary search between lowScale and highScale
    while (highScale - lowScale) > tol

        % Take the middle value of current scale range
        midScale = (lowScale + highScale) / 2;
        % Compress using middle scale and check size
        [sizeBits, midData] = image_compression_encode_only(rgb_Img, midScale, T);
        
        % If compressed size is smaller than target
        if sizeBits <= targetBits

            % This scale satisfies the target
            bestScale = midScale;

            % Save its size
            finalSize = sizeBits;

            % Save encoded data because this may be the final answer
            bestData = midData;

             % Try to find a smaller scale with better quality
            highScale = midScale;
        else

            % Size is too large, increase compression
            lowScale = midScale;
        end
    end

    % Decode the final selected compressed data
    % Calculate final image and PSNR
    [finalRGB, finalPSNR] = image_compression_decode_only(bestData, rgb_Img, T);
end