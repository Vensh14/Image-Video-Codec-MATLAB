function [reconstructedRGB, psnrVal] = finalize_reconstruction(Y_reconstructed, Cb_reconstructed, Cr_reconstructed, originalRows, originalCols, referenceRGB, clipChromaBeforeUpsample)

    % If clipping option is not provided, enable it by default
    if nargin < 7
        clipChromaBeforeUpsample = true;
    end

    % Keep Y channel values within valid image range
    Y_reconstructed = min(max(Y_reconstructed, 0), 255);

    % Limit chroma channel values before resizing if required
    if clipChromaBeforeUpsample
        Cb_reconstructed = min(max(Cb_reconstructed, 0), 255);
        Cr_reconstructed = min(max(Cr_reconstructed, 0), 255);
    end

    % Upsample chroma channels back to full image size
    Cb_reconstructed = imresize(Cb_reconstructed, [size(Y_reconstructed,1), size(Y_reconstructed,2)], 'bilinear');
    Cr_reconstructed = imresize(Cr_reconstructed, [size(Y_reconstructed,1), size(Y_reconstructed,2)], 'bilinear');

    % Clip chroma values after resizing if clipping was delayed
    if ~clipChromaBeforeUpsample
        Cb_reconstructed = min(max(Cb_reconstructed, 0), 255);
        Cr_reconstructed = min(max(Cr_reconstructed, 0), 255);
    end

    % Combine Y, Cb and Cr channels into one YCbCr image
    reconstructedYCbCr(:,:,1) = Y_reconstructed;
    reconstructedYCbCr(:,:,2) = Cb_reconstructed;
    reconstructedYCbCr(:,:,3) = Cr_reconstructed;

    % Convert YCbCr image back to RGB format
    reconstructedRGB = ycbcr2rgb(uint8(reconstructedYCbCr));

    % Remove padding and restore original image size
    reconstructedRGB = reconstructedRGB(1:originalRows, 1:originalCols, :);

    % Calculate PSNR between original and reconstructed image
    psnrVal = psnr(uint8(reconstructedRGB), uint8(referenceRGB));
end