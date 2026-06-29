%% experimental_smooth_bifurcation.m
% Reads a SWC file, selects a bifurcation, and builds/exports the
% Decroocq-style 5-cross-section smooth bifurcation model via
% generate_smooth_bifurcation.

data_file = fullfile(projectRoot, 'data', 'raw', 'BG0014.CNG.swc');
% Faulty smoothing of bifurcation - 3021
% Good smoothing of bifurcation - 194
% 64
% 26
bif_id = 3021; % The ID of the bifurcation to export

% Load and decompose
data = read_swc(data_file);
[ids, coords, radii, parents] = decompose_network(data);

% Select bifurcation
% 3380 finished prematurely as it encounters another bifurcation
% 3860 a pretty good to showcase
my_bifurcation = select_bifurcation(bif_id, ids, radii, parents);

% Show the bifurcation in the brain
%plot_swc(ids, coords, radii, parents,"my_bifurcation.png", my_bifurcation, true);

% Call generate_smooth_bifurcation to build the 5 cross-section model, sweep tubes, and plot
fprintf('\n========== Generating smooth bifurcation ==========\n');
model = generate_smooth_bifurcation(my_bifurcation, radii, coords, ids, ['BG0014_bifurcation_' num2str(bif_id) '_NEW.stl'], true);
fprintf('========== Complete ==========\n');
