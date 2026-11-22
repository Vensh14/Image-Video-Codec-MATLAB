function [Y, Cb, Cr, originalRows, originalCols] = prepare_ycbcr_channels(rgbFrame, blockSizeY, blockSizeC)

    % Convert RGB image into YCbCr color format
    ycbcr_Img = rgb2ycbcr(rgbFrame);

    % Store original image size before adding padding
    [originalRows, originalCols, ~] = size(ycbcr_Img);

    % Separate Y, Cb and Cr channels
    Y  = ycbcr_Img(:,:,1);
    Cb = ycbcr_Img(:,:,2);
    Cr = ycbcr_Img(:,:,3);

    % Reduce Cb and Cr resolution by half (chroma subsampling)
    Cb = imresize(Cb, 0.5, 'bilinear');
    Cr = imresize(Cr, 0.5, 'bilinear');

    % Add padding so channel sizes are multiples of block size
    Y  = pad_to_multiple(Y, blockSizeY);
    Cb = pad_to_multiple(Cb, blockSizeC);
    Cr = pad_to_multiple(Cr, blockSizeC);
end