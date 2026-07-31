function tag_swc_endpoints_to_json_test()
    % Sample data for testing (same network as tag_swc_endpoints_test /
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
    swcFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents, 'bifurcation_11.swc', outputFolder);

    % Act
    jsonFile = tag_swc_endpoints_to_json(swcFile);

    % Assert: JSON file is created next to the SWC file, same base name.
    [folder, name] = fileparts(swcFile);
    assert(strcmp(jsonFile, fullfile(folder, [name '.json'])), 'JSON path does not match expected default location.');
    assert(isfile(jsonFile), 'Expected JSON file was not created');

    endpoints = jsondecode(fileread(jsonFile));

    % Node 3 is the only node whose parent (node 1) lies outside the
    % extracted bifurcation subgraph, so it becomes the inlet.
    expected_inlet_id = 3;
    orig_idx = find(ids == expected_inlet_id);
    assert(endpoints.inlet.id == expected_inlet_id, 'Inlet id does not match expected root.');
    assert(isequal([endpoints.inlet.x, endpoints.inlet.y, endpoints.inlet.z], coords(orig_idx, :)), 'Inlet coordinates do not match.');
    assert(endpoints.inlet.r == radii(orig_idx), 'Inlet radius does not match.');

    % Nodes 14 and 20 are the leaves of the two daughter branches.
    expected_outlet_ids = [14; 20];
    assert(numel(endpoints.outlets) == numel(expected_outlet_ids), 'Unexpected number of outlets.');
    assert(isequal([endpoints.outlets.id]', expected_outlet_ids), 'Outlet ids do not match expected leaves.');

    for k = 1:numel(expected_outlet_ids)
        orig_idx = find(ids == expected_outlet_ids(k));
        assert(isequal([endpoints.outlets(k).x, endpoints.outlets(k).y, endpoints.outlets(k).z], coords(orig_idx, :)), 'Outlet coordinates do not match.');
        assert(endpoints.outlets(k).r == radii(orig_idx), 'Outlet radius does not match.');
    end

    delete(swcFile);
    delete(jsonFile);
    rmdir(outputFolder);

    disp('PASS: tag_swc_endpoints_to_json_test wrote and verified endpoints JSON successfully.');
end
