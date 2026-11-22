function [frames, numFrames, frameRate] = read_video_frames(fullVideoPath)

    % Open the video file
    vidReader = VideoReader(fullVideoPath);

    % Create storage for video frames
    frames = {};
    frameIndex = 1;

    % Read and store each frame from the video
    while hasFrame(vidReader)
        frames{frameIndex} = readFrame(vidReader);
        frameIndex = frameIndex + 1;
    end

    % Calculate total number of frames
    numFrames = frameIndex - 1;

    % Get video frame rate
    frameRate = vidReader.FrameRate;
end