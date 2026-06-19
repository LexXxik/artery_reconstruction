% test create_bifurcation_segment
function create_bifurcation_segment_test()
    % Sample data for testing
    %
    %           5                    17
    %         /                     /
    %       2 - 4      13 - 14 - 15 - 16    
    %     /           /
    %   1 - 3 - 6 - 11 - 12 - 18 - 19 - 20
    %
    ids =      [1; 2; 3; 4; 5; 6; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
    parents = [-1; 1; 1; 2; 2; 3; 6; 11; 11; 13; 14; 15; 15; 12; 18; 19]; % Node 1 is the root, nodes 2 and 3 are children of node 1, etc.
    
    % Test cases
    test_cases = [
        struct('target_id', 11, 'forward', false, 'expected', [3; 6; 11]),   % Bifurcation segment for target_id 11
        struct('target_id', 12, 'forward', true, 'expected', [12; 18; 19; 20]),   % Bifurcation segment for target_id 12
        struct('target_id', 13, 'forward', true, 'expected', [13; 14])    % Bifurcation segment for target_id 13
    ];

    for i = 1:length(test_cases)
        test_case = test_cases(i);
        result = create_bifurcation_segment(test_case.target_id, ids, parents, test_case.forward);
        assert(isequal(result, test_case.expected), ...
            sprintf('Test failed for target_id %d: expected [%s], got [%s]', ...
            test_case.target_id, num2str(test_case.expected), num2str(result)));
    end

    disp('PASS: create_bifurcation_segment_test created bifurcation segments successfully.');
end