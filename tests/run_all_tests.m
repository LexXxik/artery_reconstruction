disp('Running all tests...');
rawDataDir = fullfile(projectRoot, 'data', 'raw');
hello_world();
read_swc_test(rawDataDir);
decompose_network_test();
plot_swc_test(rawDataDir);