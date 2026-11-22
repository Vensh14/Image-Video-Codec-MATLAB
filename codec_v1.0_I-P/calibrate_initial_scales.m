function [initScaleI, initScaleP] = calibrate_initial_scales(frames, T, blockSize, searchRange, iFrameIdx, pFrameIdx,  refFrameIdx, calibrateFcn, targetI, targetP)

    % Count number of P frames and B frames
    numP = length(pFrameIdx);
    %numB = length(bFrameIdx);

    % Select the first I frame as a sample for calibration
    sampleI = iFrameIdx(1);

    % Find the best I-frame scale that reaches the target
    initScaleI = calibrateFcn(@(s) intra_compression(frames{sampleI}, s, T), targetI);

    % Compress the sample I frame again using the selected scale
    % This reconstructed frame will be used as a reference frame
    [~, ~, sampleI_Recon] = intra_compression(frames{sampleI}, initScaleI, T);

    % Check whether P frames exist
    if numP > 0

        % Select a middle P frame as the sample
        sampleP = pFrameIdx(max(1, round(numP / 2)));

        % Find where this P frame appears in the reference frame list
        refPos = find(refFrameIdx == sampleP);

        % Get the previous reference frame used for this P frame
        prevRef = refFrameIdx(refPos - 1);

        % If previous reference is the I frame, use the already reconstructed I frame
        if prevRef == sampleI
            prevReconP = sampleI_Recon;
        else
            % Otherwise reconstruct the previous reference frame
            % using the I-frame scale
            [~, ~, prevReconP] = intra_compression(frames{prevRef}, initScaleI, T);
        end

        % Find the best P-frame scale using the sample P frame
        initScaleP = calibrateFcn(@(s) compress_p_frame(frames{sampleP}, prevReconP, s, T, blockSize, searchRange), targetP);
    else
        % If there are no P frames, use the I-frame scale
        initScaleP = initScaleI;
    end
