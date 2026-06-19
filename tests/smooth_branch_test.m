function smooth_branch_test()
    % Arrange
    coords = [0, 0, 0; 1, 1, 1; 2, 0, 2];
    radii = [1; 0.5; 0.25];
    num_out = 5;
    
    % Act
    [smoothed_coords, smoothed_radii] = smooth_branch(coords, radii, num_out);
    
    % Assert
    assert(size(smoothed_coords, 1) == num_out, 'Number of output coordinates does not match expected value.');
    assert(size(smoothed_radii, 1) == num_out, 'Number of output radii does not match expected value.');
    
    disp('PASS: smooth_branch_test executed successfully.');
end