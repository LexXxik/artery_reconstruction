function bifurcation_to_swc_test()
    % Sample data for testing (same network as select_bifurcation_test)
    %
    %           5                    17
    %         /                     /
    %       2 - 4      13 - 14 - 15 - 16
    %     /           /
    %   1 - 3 - 6 - 11 - 12 - 18 - 19 - 20
    %
    ids =      [1; 2; 3; 4; 5; 6; 11; 12; 13; 14; 15; 16; 17; 18; 19; 20];
    radii =  [6.6; 1.0; 6.6; 1.0; 0.5; 6.6; 6.6; 6.6; 1.0; 1.0; 1.0; 0.5; 0.25; 6.6; 6.6; 6.6];
    parents = [-1; 1; 1; 2; 2; 3; 6; 11; 11; 13; 14; 15; 15; 12; 18; 19];
    coords  = [ids, zeros(numel(ids), 1), ids]; % arbitrary but unique coordinates

    apex_id = 11;
    bifurcation = select_bifurcation(apex_id, ids, radii, parents);

    outputFolder = tempname;
    outputFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents, 'test_bifurcation.swc', outputFolder);

    assert(isfile(outputFile), 'Expected SWC file was not created');

    written = read_swc(outputFile);
    [w_ids, w_coords, w_radii, w_parents] = decompose_network(written);
    w_types = written(:,2);

    expected_ids = sort(unique([bifurcation.id_p; bifurcation.apex_id; bifurcation.id_d1; bifurcation.id_d2]));
    assert(isequal(w_ids, expected_ids), 'Written ids do not match expected bifurcation node set');

    for k = 1:numel(expected_ids)
        orig_idx = find(ids == expected_ids(k));
        assert(isequal(w_coords(k,:), coords(orig_idx,:)), 'Coordinates were not preserved');
        assert(w_radii(k) == radii(orig_idx), 'Radius was not preserved');

        if k == 1
            assert(w_types(k) == 1, 'First row should be written as type 1');
            assert(w_parents(k) == -1, 'First row parent should be forced to -1');
        else
            assert(w_types(k) == 3, 'Non-first rows should be written as type 3');
            assert(w_parents(k) == parents(orig_idx), 'Parent id was not preserved');
        end
    end

    delete(outputFile);
    rmdir(outputFolder);

    disp('PASS: all tests passed for bifurcation_to_swc_test.');
end
