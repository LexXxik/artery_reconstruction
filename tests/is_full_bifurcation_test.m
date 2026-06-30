% test is_full_bifurcation
function is_full_bifurcation_test()
    % is_full_bifurcation only inspects the length of id_p, id_d1, id_d2,
    % so bifurcation structs here are built directly without a real network.
    test_cases = [
        struct('bifurcation', struct('id_p', [1;2;3;4],   'id_d1', [5;6;7;8],   'id_d2', [9;10;11;12]),   'expected', true),  % all three branches have 4 nodes
        struct('bifurcation', struct('id_p', [1;2;3],     'id_d1', [5;6;7;8],   'id_d2', [9;10;11;12]),   'expected', false), % id_p short by one
        struct('bifurcation', struct('id_p', [1;2;3;4],   'id_d1', [5;6;7],     'id_d2', [9;10;11;12]),   'expected', false), % id_d1 short by one
        struct('bifurcation', struct('id_p', [1;2;3;4],   'id_d1', [5;6;7;8],   'id_d2', [9;10;11]),      'expected', false), % id_d2 short by one
        struct('bifurcation', struct('id_p', [1;2;3;4;5], 'id_d1', [6;7;8;9],   'id_d2', [10;11;12;13]),  'expected', false)  % id_p longer than 4
    ];

    for i = 1:numel(test_cases)
        test_case = test_cases(i);
        result = is_full_bifurcation(test_case.bifurcation);
        assert(result == test_case.expected, ...
            sprintf('Test failed for case %d: expected %d, got %d', ...
            i, test_case.expected, result));
    end

    disp('PASS: is_full_bifurcation_test identified full bifurcations successfully.');
end
