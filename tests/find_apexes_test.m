% test for find_apexes.m
function find_apexes_test()
    % Arrange
    sample_nodes = [
        1, -1;  % Node 1 is a root node
        2, 1;   % Node 2 is a child of Node 1
        3, 1;   % Node 3 is a child of Node 1
        4, 2;   % Node 4 is a child of Node 2
        5, 2;   % Node 5 is a child of Node 2
        6, 3;   % Node 6 is a child of Node 3
        7, 2;   % Node 7 is a child of Node 3
        8, 7;
        9, 8;
        10, 3;
    ];
    
    expected_apex_ids = [1, 2, 3]; % Nodes with two or more children
    
    % Act
    apex_ids = find_apexes(sample_nodes);
    disp('Apex IDs found:');
    disp(apex_ids);
    
    % Assert
    assert(isequal(sort(apex_ids), sort(expected_apex_ids)), 'Apex IDs do not match expected values.');
    
    disp('PASS: find_apexes_test identified apex nodes successfully.');
end