%%% Bifurcation extraction into swc for processing by vascularmd and COMSOL
file_name = 'BG0014.CNG.swc';
data_path = fullfile(projectRoot, 'data', 'raw', file_name);
inflation_radius = 0.3; % 30 percent of the local radius, for generating an outer-wall sibling SWC

% find all apexes in the network
[ids, coords, radii, parents] = decompose_network(read_swc(data_path));

% find all apexes in the network
apexes = find_apexes(ids, parents);

% make bifurcations from all apexes and check if they are full bifurcations
full_bifurcations = [];
full_apexes = [];
for i = 1:numel(apexes)
    bifurcation = select_bifurcation(apexes(i), ids, radii, parents);
    if is_full_bifurcation(bifurcation)
        full_bifurcations = [full_bifurcations; bifurcation];
        full_apexes = [full_apexes; apexes(i)];
    end
end

% print apexes and full apexes
fprintf('Full apexes: %s\n', mat2str(full_apexes));
fprintf('Bifurcation count: %d\n', numel(full_bifurcations));
% pause until user presses a key
fprintf('Press any key to continue...\n');
pause;

% Now create a new SWC files that contains only the full bifurcations

% split the filename string by .
[~, dataset_name, ext] = fileparts(file_name);
% print the name and ext
fprintf('Name: %s, Ext: %s\n', dataset_name, ext);
% make a resulting filename for the new SWC file
outputFolder = fullfile(projectRoot, 'results', 'swc_to_process', dataset_name);
for i = 1:numel(full_apexes)
    outputFilename = sprintf('bifurcation_%d.swc', full_apexes(i));
    new_swc_file = bifurcation_to_swc(full_bifurcations(i), ids, radii, coords, parents, outputFilename, outputFolder);
    fprintf('Bifurcation SWC saved to %s\n', new_swc_file);

    % Tag the inlet/outlet nodes of this bifurcation and save them as a
    % JSON sidecar (bifurcation_%d.json) for later coordinate-based
    % boundary matching in COMSOL.
    tag_swc_endpoints_to_json(new_swc_file);

    % Generate an outer-wall sibling SWC with a fixed wall thickness
    % added to every radius (absolute mode), rather than a percentage of
    % the local radius. Feed the original file into vascularmd for the
    % lumen surface, and this one for the outer wall.
    [~, base_name] = fileparts(new_swc_file);
    outer_swc_file = fullfile(outputFolder, [base_name '_outer.swc']);
    inflate_swc_radius(new_swc_file, outer_swc_file, inflation_radius, 'ratio');
    fprintf('Inflated outer-wall SWC saved to %s\n', outer_swc_file);
end

% read swc file that was last created and plot it
last_swc_file = new_swc_file;
[last_ids, last_coords, last_radii, last_parents] = decompose_network(read_swc(last_swc_file));
plot_swc(last_ids, last_coords, last_radii, last_parents, sprintf('%s_last_bifurcation.png', dataset_name));
