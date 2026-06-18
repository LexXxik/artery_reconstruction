function outputFile = plot_swc(data, outputFilename)
% PLOT_SWC Visualize SWC morphology and save image under results/visualization.
%   outputFile = PLOT_SWC(data)
%   outputFile = PLOT_SWC(data, outputFilename)
%
% Input:
%   data           N-by-7 matrix [id, type, x, y, z, radius, parent]
%   outputFilename Optional output image name (e.g., 'BG001_plot.png')
%
% Output:
%   outputFile     Absolute path to generated image

if nargin < 1 || isempty(data) || size(data, 2) ~= 7
    error('plot_swc:InvalidInput', 'Input data must be a non-empty N-by-7 matrix.');
end

if nargin < 2 || isempty(outputFilename)
    outputFilename = 'swc_plot.png';
end

[~, ~, ext] = fileparts(outputFilename);
if isempty(ext)
    outputFilename = [outputFilename, '.png'];
end

[ids, coords, radii, parents] = decompose_network(data);

midX = median(coords(:,1));
midY = median(coords(:,2));

% Nodes with more than one child are bifurcation candidates.
[uParents, ~, idxParent] = unique(parents(parents > 0));
childCounts = accumarray(idxParent, 1);
bif_ids = uParents(childCounts > 1);

% Build id -> row index map for parent lookup.
idMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
for i = 1:numel(ids)
    idMap(ids(i)) = i;
end

fig = figure('Color', 'w', 'Name', 'SWC Anatomical Map: Bifurcation Highlighted');
hold on;
grid on;
axis equal;
view(0, 0); % Coronal (front-on)
xlabel('X (Right <-> Left)');
ylabel('Y (Posterior <-> Anterior)');
zlabel('Z (Inferior <-> Superior)');

c_RA = [1, 0.4, 0.4];
c_LA = [0.4, 0.8, 0.4];
c_RP = [0.4, 0.4, 1];
c_LP = [1, 0.7, 0.2];
c_BIF = [0.6, 0, 0];

hRA = plot3(NaN, NaN, NaN, 'Color', c_RA, 'LineWidth', 1);
hLA = plot3(NaN, NaN, NaN, 'Color', c_LA, 'LineWidth', 1);
hRP = plot3(NaN, NaN, NaN, 'Color', c_RP, 'LineWidth', 1);
hLP = plot3(NaN, NaN, NaN, 'Color', c_LP, 'LineWidth', 1);
hBIF = plot3(NaN, NaN, NaN, 'Color', c_BIF, 'LineWidth', 3.5);

for i = 1:size(data, 1)
    p_id = parents(i);
    if p_id <= 0 || ~isKey(idMap, p_id)
        continue;
    end

    p_idx = idMap(p_id);

    if ismember(ids(i), bif_ids) && ismember(p_id, bif_ids)
        line_col = c_BIF;
        lw = 3.5;
    else
        curX = coords(i,1);
        curY = coords(i,2);

        if curX > midX && curY > midY
            line_col = c_RA;
        elseif curX <= midX && curY > midY
            line_col = c_LA;
        elseif curX > midX && curY <= midY
            line_col = c_RP;
        else
            line_col = c_LP;
        end
        lw = 0.8;
    end

    line([coords(i,1), coords(p_idx,1)], ...
         [coords(i,2), coords(p_idx,2)], ...
         [coords(i,3), coords(p_idx,3)], ...
         'Color', line_col, 'LineWidth', lw);
end

markerSize = max(6, min(60, radii * 10));
scatter3(coords(:,1), coords(:,2), coords(:,3), markerSize, [0.2 0.2 0.2], 'filled', ...
    'MarkerFaceAlpha', 0.35, 'MarkerEdgeAlpha', 0.35);

legend([hRA, hLA, hRP, hLP, hBIF], ...
    {'Right Anterior', 'Left Anterior', 'Right Posterior', 'Left Posterior', 'Bifurcation'}, ...
    'Location', 'northeastoutside');

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fullfile(scriptDir, '..');
outputDir = fullfile(projectRoot, 'results', 'visualization');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

outputFile = fullfile(outputDir, outputFilename);
saveas(fig, outputFile);
close(fig);
end