%% export_bifurcation_stl.m
% Reads a SWC file, selects a bifurcation, and exports it as an STL.
%% UNFINISHED: This script is a work in progress and may not be fully functional yet.

data_file = fullfile(projectRoot, 'data', 'raw', 'BG0014.CNG.swc');

% Load and decompose
data = read_swc(data_file);
[ids, coords, radii, parents] = decompose_network(data);

% Select bifurcation
% 3380 finished prematurely as it encounters another bifurcation
% 3860 a pretty good to showcase
my_bifurcation = select_bifurcation(3860, ids, radii, parents);

% Export to STL
bifurcation_to_stl(my_bifurcation, radii, coords, ids, 'BG0014_bifurcation_3860.stl', true);
