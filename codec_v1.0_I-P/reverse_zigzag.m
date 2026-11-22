function matrix = reverse_zigzag(zigzag_vector)
    % REVERSE_ZIGZAG_SCAN Reconstructs an 8x8 matrix from a 64-element 1D vector.
    % MATLAB 1-based, column-major lookup index map:
    ZIGZAG_MAP = [
         1,  9,  2,  3, 10, 17, 25, 18, ...
        11,  4,  5, 12, 19, 26, 33, 41, ...
        34, 27, 20, 13,  6,  7, 14, 21, ...
        28, 35, 42, 49, 57, 50, 43, 36, ...
        29, 22, 15,  8, 16, 23, 30, 37, ...
        44, 51, 58, 59, 52, 45, 38, 31, ...
        24, 32, 39, 46, 53, 60, 61, 54, ...
        47, 40, 48, 55, 62, 63, 56, 64
    ];

    % Ensure input vector has exactly 64 elements
    if length(zigzag_vector) ~= 64
        error('Input vector must have exactly 64 elements.');
    end
    
    % Initialize an empty 8x8 matrix
    matrix = zeros(8, 8);
    
    % Reconstruct the matrix using the inverse mapping
    matrix(ZIGZAG_MAP) = zigzag_vector;
end