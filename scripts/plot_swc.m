function outputFile = plot_swc(ids, coords, radii, parents, outputFilename, bifurcation, zoomBif)
% PLOT_SWC Visualize SWC morphology as an interactive 3D plot and save it.
%   outputFile = PLOT_SWC(ids, coords, radii, parents)
%   outputFile = PLOT_SWC(ids, coords, radii, parents, outputFilename)
%   outputFile = PLOT_SWC(ids, coords, radii, parents, outputFilename, bifurcation)
%   outputFile = PLOT_SWC(ids, coords, radii, parents, outputFilename, bifurcation, zoomBif)
%
% Input:
%   ids            Vector of node IDs
%   coords         N-by-3 matrix of node coordinates [x, y, z]
%   radii          Vector of node radii
%   parents        Vector of parent node IDs
%   outputFilename Optional output image name (e.g., 'BG001_plot.png')
%   bifurcation    Optional struct from select_bifurcation with fields:
%                    id_p   : parent branch node IDs
%                    id_d1  : main daughter branch node IDs
%                    id_d2  : side daughter branch node IDs
%                    apex_id: apex node ID
%                  When provided, highlights parent and daughter branches.
%   zoomBif        Optional logical scalar (default false).
%                  If true and bifurcation is provided, zooms to bifurcation.
%
% Output:
%   outputFile     Absolute path to generated image

if nargin < 4 || isempty(ids) || isempty(coords) || isempty(radii) || isempty(parents)
    error('plot_swc:InvalidInput', 'Input data must be non-empty vectors/matrices.');
end

if nargin < 5 || isempty(outputFilename)
    outputFilename = 'swc_plot.png';
end

[~, ~, ext] = fileparts(outputFilename);
if isempty(ext)
    outputFilename = [outputFilename, '.png'];
end

if nargin < 6
    bifurcation = [];
end
highlightBif = ~isempty(bifurcation);

if nargin < 7 || isempty(zoomBif)
    zoomBif = false;
end


midX = median(coords(:,1));
midY = median(coords(:,2));

% Build id -> row index map for fast lookup.
idMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
for i = 1:numel(ids)
    idMap(ids(i)) = i;
end

% Unpack bifurcation highlight sets.
if highlightBif
    ids_p   = bifurcation.id_p;
    ids_d1  = bifurcation.id_d1;
    ids_d2  = bifurcation.id_d2;
    apex_id = bifurcation.apex_id;
else
    ids_p = []; ids_d1 = []; ids_d2 = []; apex_id = [];
end

% Colours for quadrant segments.
c_RA = [1,   0.4, 0.4];
c_LA = [0.4, 0.8, 0.4];
c_RP = [0.4, 0.4, 1  ];
c_LP = [1,   0.7, 0.2];
% Colours for bifurcation branches.
c_P  = [0.7, 0.0, 0.7];   % parent branch  – magenta
c_D1 = [0.0, 0.8, 0.8];   % daughter 1     – cyan
c_D2 = [1.0, 0.5, 0.0];   % daughter 2     – orange

fig = figure('Color', 'w', 'Name', 'SWC Anatomical Map: 3D');
hold on;
grid on;
axis equal;
view(3);   % standard 3-D perspective (azimuth -37.5°, elevation 30°)
xlabel('X (Right \leftrightarrow Left)');
ylabel('Y (Posterior \leftrightarrow Anterior)');
zlabel('Z (Inferior \leftrightarrow Superior)');

% Invisible dummy handles for legend entries.
hRA = plot3(NaN, NaN, NaN, '-', 'Color', c_RA, 'LineWidth', 1.5);
hLA = plot3(NaN, NaN, NaN, '-', 'Color', c_LA, 'LineWidth', 1.5);
hRP = plot3(NaN, NaN, NaN, '-', 'Color', c_RP, 'LineWidth', 1.5);
hLP = plot3(NaN, NaN, NaN, '-', 'Color', c_LP, 'LineWidth', 1.5);

% Draw all edges.
for i = 1:numel(ids)
    p_id = parents(i);
    if p_id <= 0 || ~isKey(idMap, p_id)
        continue;
    end
    p_idx = idMap(p_id);

    % Priority: bifurcation highlight > quadrant colour.
    if highlightBif && ismember(ids(i), ids_p) && ismember(p_id, ids_p)
        line_col = c_P;  lw = 2.5;
    elseif highlightBif && ismember(ids(i), ids_d1) && ismember(p_id, ids_d1)
        line_col = c_D1; lw = 2.5;
    elseif highlightBif && ismember(ids(i), ids_d2) && ismember(p_id, ids_d2)
        line_col = c_D2; lw = 2.5;
    else
        curX = coords(i,1);
        curY = coords(i,2);
        if     curX >  midX && curY >  midY,  line_col = c_RA;
        elseif curX <= midX && curY >  midY,  line_col = c_LA;
        elseif curX >  midX && curY <= midY,  line_col = c_RP;
        else,                                  line_col = c_LP;
        end
        lw = 0.8;
    end

    line([coords(i,1), coords(p_idx,1)], ...
         [coords(i,2), coords(p_idx,2)], ...
         [coords(i,3), coords(p_idx,3)], ...
         'Color', line_col, 'LineWidth', lw);
end

% Background node cloud.
markerSize = max(6, min(60, radii * 20));
scatter3(coords(:,1), coords(:,2), coords(:,3), markerSize, [0.2 0.2 0.2], 'filled', ...
    'MarkerFaceAlpha', 0.35, 'MarkerEdgeAlpha', 0.35);

% Overlay and annotate bifurcation if provided.
if highlightBif
    hP  = plot3(NaN, NaN, NaN, 'o', 'Color', c_P,  'MarkerFaceColor', c_P,  'MarkerSize', 8);
    hD1 = plot3(NaN, NaN, NaN, 'o', 'Color', c_D1, 'MarkerFaceColor', c_D1, 'MarkerSize', 8);
    hD2 = plot3(NaN, NaN, NaN, 'o', 'Color', c_D2, 'MarkerFaceColor', c_D2, 'MarkerSize', 8);
    hApex = plot3(NaN, NaN, NaN, 'o', 'Color', [1 1 0], 'MarkerFaceColor', [1 1 0], ...
        'MarkerSize', 10, 'MarkerEdgeColor', 'k', 'LineWidth', 1.5);

    seg_list   = {ids_p,  ids_d1,  ids_d2};
    seg_colours = {c_P,   c_D1,    c_D2  };
    for s = 1:3
        seg = seg_list{s};
        col = seg_colours{s};
        for j = 1:numel(seg)
            if isKey(idMap, seg(j))
                idx = idMap(seg(j));
                scatter3(coords(idx,1), coords(idx,2), coords(idx,3), ...
                    100, col, 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 1);
            end
        end
        % Connect points within the segment with lines
        for j = 1:numel(seg)-1
            if isKey(idMap, seg(j)) && isKey(idMap, seg(j+1))
                idx_curr = idMap(seg(j));
                idx_next = idMap(seg(j+1));
                plot3([coords(idx_curr,1), coords(idx_next,1)], ...
                      [coords(idx_curr,2), coords(idx_next,2)], ...
                      [coords(idx_curr,3), coords(idx_next,3)], ...
                      'Color', col, 'LineWidth', 3);
            end
        end
    end

    % Highlight the apex node
    if isKey(idMap, apex_id)
        ax_idx = idMap(apex_id);
        ax_pos = coords(ax_idx, :);
        scatter3(ax_pos(1), ax_pos(2), ax_pos(3), 150, [1 1 0], 'filled', ...
            'MarkerEdgeColor', 'k', 'LineWidth', 1.5);
    end

    legend([hRA, hLA, hRP, hLP, hP, hD1, hD2, hApex], ...
        {'Right Anterior', 'Left Anterior', 'Right Posterior', 'Left Posterior', ...
         'Parent Branch', 'Daughter 1 (main)', 'Daughter 2 (side)', ...
         sprintf('Apex (id = %d)', apex_id)}, ...
        'Location', 'northeastoutside');

    if zoomBif
        % Zoom onto the bifurcation region
        all_bif_ids = [ids_p; ids_d1; ids_d2];
        bif_indices = [];
        for bid = 1:numel(all_bif_ids)
            if isKey(idMap, all_bif_ids(bid))
                bif_indices = [bif_indices; idMap(all_bif_ids(bid))];
            end
        end

        if ~isempty(bif_indices)
            bif_coords = coords(bif_indices, :);
            x_min = min(bif_coords(:,1)); x_max = max(bif_coords(:,1));
            y_min = min(bif_coords(:,2)); y_max = max(bif_coords(:,2));
            z_min = min(bif_coords(:,3)); z_max = max(bif_coords(:,3));

            % Add 20% padding
            x_pad = 0.2 * (x_max - x_min); if x_pad == 0, x_pad = 1; end
            y_pad = 0.2 * (y_max - y_min); if y_pad == 0, y_pad = 1; end
            z_pad = 0.2 * (z_max - z_min); if z_pad == 0, z_pad = 1; end

            xlim([x_min - x_pad, x_max + x_pad]);
            ylim([y_min - y_pad, y_max + y_pad]);
            zlim([z_min - z_pad, z_max + z_pad]);
        end
    end
else
    legend([hRA, hLA, hRP, hLP], ...
        {'Right Anterior', 'Left Anterior', 'Right Posterior', 'Left Posterior'}, ...
        'Location', 'northeastoutside');
end

scriptDir = fileparts(mfilename('fullpath'));
projectRoot = fullfile(scriptDir, '..');
outputDir = fullfile(projectRoot, 'results', 'visualization');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

outputFile = fullfile(outputDir, outputFilename);
saveas(fig, outputFile);
end