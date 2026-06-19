function select_bifurcation_test()
    % Sample data for testing
    %
    %           5                    17
    %         /                     /
    %       2 - 4      13 - 14 - 15 - 16    
    %     /           /
    %   1 - 3 - 6 - 11 - 12 - 18 - 19 - 20
    %
    ids =      [1; 2; 3; 4; 5; 6; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
    radii =  [6.6; 1.0; 6.6; 1.0; 0.5; 6.6; 6.6; 6.6; 1.0; 1.0; 1.0; 0.5; 0.25; 6.6; 6.6; 6.6];
    parents = [-1; 1; 1; 2; 2; 3; 6; 11; 11; 13; 14; 15; 15; 12; 18; 19]; % Node 1 is the root, nodes 2 and 3 are children of node 1, etc.
    
    % Test cases
    apex_id = 11; % Apex node
    expected_output.id_p = [3; 6; 11];
    expected_output.id_d1 = [11; 12; 18; 19; 20]; % Main branch
    expected_output.id_d2 = [11; 13; 14]; % Side branch

    % Call the function
    output = select_bifurcation(apex_id, ids, radii, parents);

    % Verify the output
    assert(isequal(output.id_p, expected_output.id_p), 'id_p does not match expected output');
    assert(isequal(output.id_d1, expected_output.id_d1), 'id_d1 does not match expected output');
    assert(isequal(output.id_d2, expected_output.id_d2), 'id_d2 does not match expected output');

    disp('PASS: all tests passed for select_bifurcation_test.');
end