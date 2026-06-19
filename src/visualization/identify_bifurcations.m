% make a code that reads in the swc data, decomposes it into ids, coords, radii, and parents, and then identifies bifurcations (apexes) in the neuron structure. The code should also include tests for reading the swc file and plotting the neuron structure.
data_file = fullfile(projectRoot, 'data', 'raw', 'BG0014.CNG.swc');
% Read the SWC data
data = read_swc(data_file);
% Decompose the data into ids, coords, radii, and parents
[ids, coords, radii, parents] = decompose_network(data);
% Identify bifurcations (apexes) in the neuron structure
apex_ids = find_apexes(ids, parents);
fprintf('Apex IDs: %s\n', mat2str(apex_ids));
fprintf('There are %d bifurcations in the neuron structure.\n', length(apex_ids));


% 3380 finished prematurely as it encounters another bifurcation
% 3860 a pretty good to showcase
my_bifurcation = select_bifurcation(3021, ids, radii, parents);

plot_swc(ids, coords, radii, parents, 'BG0014_plot.png');
plot_apexes(ids, coords, radii, parents, apex_ids, 'BG0014_apexes.png');