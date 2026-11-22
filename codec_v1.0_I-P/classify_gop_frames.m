function [frameTypes, refFrameIdx, iFrameIdx, pFrameIdx] = classify_gop_frames(numFrames, GOP, refSpacing)

    % Assign frame types (I, P, B) based on GOP structure
    frameTypes = cell(numFrames,1);

    for i = 1:numFrames
        % Position of current frame inside the GOP
        posInGOP = mod(i-1, GOP);

        % First frame of GOP is an I frame
        if posInGOP == 0
            frameTypes{i} = 'I';        % First frame of GOP is an I frame
        else
            frameTypes{i} = 'P';        % Remaining frames are P frames
        end
    end

    % Collect I and P frame positions as reference frames
    refFrameIdx = [];

    for i = 1:numFrames
        if strcmp(frameTypes{i}, 'I') || strcmp(frameTypes{i}, 'P')
            refFrameIdx(end+1) = i; %#ok<AGROW>
        end
    end

    % Separate frame indices according to their type
    refFrameIdx = []; 
    iFrameIdx = []; 
    pFrameIdx = [];


    for i = 1:numFrames
        if strcmp(frameTypes{i}, 'I')
            iFrameIdx(end+1) = i; refFrameIdx(end+1) = i; %#ok<AGROW>
        elseif strcmp(frameTypes{i}, 'P')
            pFrameIdx(end+1) = i; refFrameIdx(end+1) = i; %#ok<AGROW>
        end
    end

%{
%#ok<AGROW> is a MATLAB code analyzer warning suppression comment.
%}