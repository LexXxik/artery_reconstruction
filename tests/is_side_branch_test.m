% Make a test function for is_side_branch
function is_side_branch_test()
    % Sample data for testing
    %
    %           5
    %         /
    %       2 - 10
    %     /
    %   1 - 3 - 6
    %
    ids = [1; 2; 3; 10; 5; 6];
    parents = [-1; 1; 1; 2; 2; 3]; % Node 1 is the root, nodes 2 and 3 are children of node 1, etc.
    radii = [5; 3; 4; 2; 1; 6]; % Radii for each node

    % Test cases
    test_cases = [
        struct('node_id', 10, 'expected', false),   % Node 10 is a side branch (smaller radius than sibling)
        struct('node_id', 5, 'expected', true),   % Node 5 is not a side branch (larger radius than sibling)
        struct('node_id', 6, 'expected', false)    % Node 6 is not a side branch (no siblings)
    ];

    for i = 1:length(test_cases)
        test_case = test_cases(i);
        result = is_side_branch(test_case.node_id, ids, parents, radii);
        assert(result == test_case.expected, ...
            sprintf('Test failed for node_id %d: expected %d, got %d', ...
            test_case.node_id, test_case.expected, result));
    end

    disp('PASS: is_side_branch_test identified side branches successfully.');
end