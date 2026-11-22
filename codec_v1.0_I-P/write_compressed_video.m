function outputPath = write_compressed_video(reconstructedFrames, numFrames, frameRate, filename, pathname, suffix)

    % Get original file name without extension
    [~, baseFileName, ~] = fileparts(filename);

    % Create output file name
    outputFileName = sprintf('%s_%s.mp4', baseFileName, suffix);

    % Create full output file path
    outputPath = fullfile(pathname, outputFileName);

    % Create video writer object
    vidWriter = VideoWriter(outputPath, 'MPEG-4');

    % Set output video frame rate
    vidWriter.FrameRate = frameRate;

    % Open video writer
    open(vidWriter);

    % Write reconstructed frames into video
    for i = 1:numFrames
        
        % Write current frame
        writeVideo(vidWriter, reconstructedFrames{i});
    end

    % Close video writer
    close(vidWriter);
end