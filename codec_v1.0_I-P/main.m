clear; 
clc; 
close all; 

%% Select Processing Type
disp('======================================');
disp('        IMAGE / VIDEO COMPRESSION     ');
disp('======================================');

disp('1. Image Compression');
disp('2. Video Compression');

choice = input('Enter your choice: ');

switch choice
    %                 IMAGE COMPRESSION
    case 1
        % Print section header for Image Compression mode
        fprintf('\n--- IMAGE COMPRESSION ---\n');
        
        % Open a graphical file chooser dialog to pick source image
        [filename, pathname] = uigetfile({'*.png;*.jpg;*.jpeg;*.bmp;*.tif', 'Image Files'}, 'Select Colour Source Image');
        
        % Check if user canceled file dialog (returns 0)
        if isequal(filename,0)
            % Terminate execution with error message if no file chosen
            error('No image selected');
        end
        
        % Combine path and filename into a single full file path string
        imagePath = fullfile(pathname,filename);
        
        % Read pixel data from selected image path into array
        rgb_Img = imread(imagePath);
        
        % Check third dimension size to ensure image is full RGB (3 channels)
        if size(rgb_Img,3) < 3
            % Throw error if grayscale or single-channel image passed
            error('Please select RGB colour image');
        end
        
        % Confirm successful image loading in command window
        fprintf('Image selected successfully\n');
        
        % Generate standard 8x8 Discrete Cosine Transform (DCT) matrix
        T = dctmtx(8);
        
        disp(' ');
        disp('1. Fixed Quality');
        disp('2. Target Bitrate');
        
        imageMode = input('Select image mode: ');
        
        % Branch based on chosen image compression sub-mode
        switch imageMode
            case 1
                disp(' ');
                disp('1. Low Quality');
                disp('2. Medium Quality');
                disp('3. High Quality');

                % Prompt user to choose quality preset level
                q = input('Select quality: ');
                
                % Branch based on quality level selected
                switch q
                    case 1
                        % Set large quantization scale factor (heavy quantization / lower quality)
                        scale = 10;
                    case 2
                        % Set medium quantization scale factor
                        scale = 5;
                    case 3
                        % Set small quantization scale factor (fine quantization / high quality)
                        scale = 1;
                    otherwise
                        % Throw error for invalid menu input
                        error('Invalid selection');
                end
                
                % Execute image compression function with selected fixed scale
                [compressedSize, psnr_val, reconstructedRGB] = image_compression(rgb_Img,scale,T);
                
                % Store chosen scale as best scale output variable
                bestScale = scale;
                
            case 2
                % Prompt user to input target bit count budget
                targetBits = input('Enter target bits in Kbps: ');
                
                % Call iterative search function to find scale matching target bit budget
                [bestScale, compressedSize, psnr_val, reconstructedRGB] = compress_to_bitrate(rgb_Img,(targetBits*10e3),T);
                
            otherwise
                % Throw error for invalid image mode menu input
                error('Invalid image mode');
        end
        
        % Start stopwatch timer to measure total compression runtime
        tic

        % Calculate raw uncompressed size in bits (Total Pixels x 8 bits/byte)
        originalBits = numel(rgb_Img)*8;
        
        % Compute compression ratio (Original Bits / Compressed Bits)
        compressionRatio = originalBits/compressedSize;
        
        % Display summary results section header
        fprintf('\n========= IMAGE RESULT =========\n');
        fprintf('Scale              : %.4f\n', bestScale);
        fprintf('Compressed Size    : %d bits\n', compressedSize);
        fprintf('PSNR               : %.2f dB\n', psnr_val);
        fprintf('Compression Ratio  : %.2f : 1\n', compressionRatio);
        
        % Open new figure window for image visual inspection
        figure;
        
        % Create left subplot layout (1 row, 2 columns, position 1)
        subplot(1,2,1);
        % Render original input RGB image
        imshow(rgb_Img);
        % Add title to original image plot
        title('Original');
        
        % Create right subplot layout (1 row, 2 columns, position 2)
        subplot(1,2,2);
        % Render reconstructed output RGB image
        imshow(reconstructedRGB);
        % Add title to reconstructed image plot
        title('Reconstructed');
        
        % Stop stopwatch timer and store total elapsed execution time in seconds
        time = toc;
        
        % === ADD HERE: Save Compressed Image ===
        % Extract filename without extension and directory path
        [~, baseFileName, ~] = fileparts(filename);
        
        % Construct destination full path for output image file
        outputImagePath = fullfile(pathname, sprintf('%s_compressed.png', baseFileName));
        
        % Write reconstructed image array out to file as PNG
        imwrite(reconstructedRGB, outputImagePath);
        
        % Print output file path confirmation to command window
        fprintf('Saved Compressed Image To : %s\n', outputImagePath);
        
        % Print execution elapsed time to command window
        fprintf('Time: %f.2', time);
        
    %% =====================================================
    %                 VIDEO COMPRESSION
    % ======================================================
    case 2
        % Print section header for Video Compression mode
        fprintf('\n--- VIDEO COMPRESSION ---\n');
        
        % 1. Select Video File
        % Open graphical file chooser dialog to pick source video
        [filename, pathname] = uigetfile({'*.mp4;*.avi;*.mov', 'Video Files'}, 'Select Video');
            
        % Check if user canceled file dialog
        if isequal(filename, 0)
            % Terminate execution with error message if no file chosen
            error('No video selected.');
        end
        
        % Combine path and filename into a single full video path string
        fullVideoPath = fullfile(pathname, filename);
        
        % Confirm selected video name to command window
        fprintf('Video selected: %s\n\n', filename);
        
        % 3. Choose Video Mode
        disp('1. Fixed Quality');
        disp('2. Target Bitrate Mode');
        disp('3. Target PSNR Mode');

        videoMode = input('Select video mode: ');
        
        % Branch execution based on chosen video mode
        switch videoMode
            case 1
                disp(' ');
                disp('1. Low Quality');
                disp('2. Medium Quality');
                disp('3. High Quality');

                % Prompt user to choose quality preset level
                q = input('Select quality: ');
                
                % Branch based on quality level selected
                switch q
                    case 1
                        % Set large quantization scale factor (heavy quantization / lower quality)
                        scale = 10;
                    case 2
                        % Set medium quantization scale factor
                        scale = 5;
                    case 3
                        % Set small quantization scale factor (fine quantization / high quality)
                        scale = 1;
                    otherwise
                        % Throw error for invalid menu input
                        error('Invalid selection');
                end

                video_fixed_quality_compression(fullVideoPath, scale, filename, pathname)

            case 2
                % Prompt user to type target bitrate in Mbps
                userBitrateMbps = input('Enter target bitrate in Mbps: ');
                
                % Print status message before running bitrate control execution
                fprintf('\nRunning bitrate controlled compression...\n');
                
                % Execute video bitrate compression module with parameters
                video_bitrate_compression(fullVideoPath, userBitrateMbps, filename, pathname);
                
            case 3
                % Prompt user to type target PSNR in dB
                targetPSNR = input('Enter target PSNR in dB: ');
                
                % Print status message before running PSNR control execution
                fprintf('\nRunning PSNR controlled compression...\n');
                
                % Execute video PSNR compression module with parameters
                video_psnr_compression(fullVideoPath, targetPSNR, filename, pathname);
                
            otherwise
                % Throw error for invalid video mode selection
                error('Invalid video mode');
        end
        
    otherwise
        % Throw error for invalid main menu choice
        error('Invalid choice');
end