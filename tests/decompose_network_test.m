function decompose_network_test()
    
    % Arrange
    sample_data = [
        1, 1, 0.0, 0.0, 0.0, 1.0, -1;
        2, 3, 1.0, 0.0, 0.0, 0.5, 1;
        3, 3, 2.0, 0.0, 0.0, 0.5, 2;
    ];
    
    expected_ids = [1; 2; 3];
    expected_coords = [0.0, 0.0, 0.0; 
                       1.0, 0.0, 0.0; 
                       2.0, 0.0, 0.0];
    expected_radii = [1.0; 0.5; 0.5];
    expected_parents = [-1; 1; 2];
    
    % Act
    [ids, coords, radii, parents] = decompose_network(sample_data);
    
    % Assert
    assert(isequal(ids, expected_ids), 'IDs do not match expected values.');
    assert(isequal(coords, expected_coords), 'Coordinates do not match expected values.');
    assert(isequal(radii, expected_radii), 'Radii do not match expected values.');
    assert(isequal(parents, expected_parents), 'Parents do not match expected values.');
    
    disp('PASS: decompose_network_test interpreted data successfully.');
end