function tag_swc_endpoints_test()
    % Sample data for testing (same network as select_bifurcation_test /
    % bifurcation_to_swc_test)
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
    swcFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents, 'test_tag_endpoints.swc', outputFolder);

    % Act
    [inlet, outlets] = tag_swc_endpoints(swcFile);

    % Assert: node 3 is the only node whose parent (node 1) lies outside
    % the extracted bifurcation subgraph, so it becomes the inlet.
    expected_inlet_id = 3;
    orig_idx = find(ids == expected_inlet_id);
    assert(inlet.id == expected_inlet_id, 'Inlet id does not match expected root.');
    assert(isequal([inlet.x, inlet.y, inlet.z], coords(orig_idx, :)), 'Inlet coordinates do not match.');
    assert(inlet.r == radii(orig_idx), 'Inlet radius does not match.');

    % Assert: nodes 14 and 20 are the leaves of the two daughter branches.
    expected_outlet_ids = [14; 20];
    assert(numel(outlets) == numel(expected_outlet_ids), 'Unexpected number of outlets.');
    assert(isequal([outlets.id]', expected_outlet_ids), 'Outlet ids do not match expected leaves.');

    for k = 1:numel(expected_outlet_ids)
        orig_idx = find(ids == expected_outlet_ids(k));
        assert(isequal([outlets(k).x, outlets(k).y, outlets(k).z], coords(orig_idx, :)), 'Outlet coordinates do not match.');
        assert(outlets(k).r == radii(orig_idx), 'Outlet radius does not match.');
    end

    delete(swcFile);
    rmdir(outputFolder);

    disp('PASS: tag_swc_endpoints_test identified inlet and outlets successfully.');
end
