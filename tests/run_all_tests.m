startup;
rawDataDir = fullfile(projectRoot, 'data', 'raw');
hello_world();
read_swc_test(rawDataDir);
decompose_network_test();
find_apexes_test();
find_daughters_test();
is_side_branch_test();
create_bifurcation_segment_test();
select_bifurcation_test();
bifurcation_to_swc_test();
is_full_bifurcation_test();
smooth_branch_test();

% plotting tests in the end to avoid opening too many figures at once
%plot_swc_test(rawDataDir);
%plot_apexes_test(rawDataDir);