function targetThisFrame = next_frame_bit_target(remainingBits, remainingCount, idx)

    % Calculate average bits available for the current frame
    % by dividing remaining bits among remaining frames
    targetThisFrame = remainingBits / (remainingCount - idx + 1);
end