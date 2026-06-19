% Write a test function for find_daughters.m. The function should take in a sample node id, ids, and parents as inputs and check that the function returns the correct daughter ids.
function find_daughters_test()
    % Arrange
    sample_nodes = [
        1, -1;  % Node 1 is a root node
        2, 1;   % Node 2 is a child of Node 1
        3, 1;   % Node 3 is a child of Node 1
        4, 2;   % Node 4 is a child of Node 2
        5, 2;   % Node 5 is a child of Node 2
        6, 3;   % Node 6 is a child of Node 3
        7, 3;   % Node 7 is a child of Node 3
        8, 7;
        9, 8;
        10, 3;
    ];
    
    sample_node_id = 2; % Test for node with id = 2
    expected_daughter_ids = [4; 5]; % Nodes with parent id = 2
    
    % Act
    daughter_ids = find_daughters(sample_node_id, sample_nodes(:, 1), sample_nodes(:, 2));
    
    % Assert
    assert(isequal(sort(daughter_ids), sort(expected_daughter_ids)), 'Daughter IDs do not match expected values.');
    
    disp('PASS: find_daughters_test identified daughter nodes successfully.');
end