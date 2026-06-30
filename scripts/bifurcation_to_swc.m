% Build a standalone SWC file containing a bifurcation: the parent segment
% leading up to the apex, the apex itself, and both daughter branches.
% Ids, coordinates, radii and parent links are copied unchanged from the
% source network, so the extracted file is a literal subgraph of it.
%
% Usage:
%   outputFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents)
%   outputFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents, outputFilename)
%   outputFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents, outputFilename, outputFolder)
%
% Inputs:
%   bifurcation    - struct from select_bifurcation (fields: id_p, id_d1, id_d2, apex_id)
%   ids            - N x 1 vector of node ids
%   radii          - N x 1 vector of node radii
%   coords         - N x 3 matrix of node coordinates [x, y, z]
%   parents        - N x 1 vector of parent node ids
%   outputFilename - base filename for the SWC file (default 'bifurcation.swc')
%   outputFolder   - output folder (default results/swc_models relative to project root)
%
% Output:
%   outputFile     - absolute path to the generated SWC file

function outputFile = bifurcation_to_swc(bifurcation, ids, radii, coords, parents, outputFilename, outputFolder)

    if nargin < 5
        error('bifurcation_to_swc:InvalidInput', ...
            'Required inputs: bifurcation, ids, radii, coords, parents.');
    end

    if nargin < 6 || isempty(outputFilename)
        outputFilename = 'bifurcation.swc';
    end
    [~, ~, ext] = fileparts(outputFilename);
    if isempty(ext)
        outputFilename = [outputFilename, '.swc'];
    end

    if nargin < 7 || isempty(outputFolder)
        outputFolder = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'swc_models');
    end
    if ~exist(outputFolder, 'dir'), mkdir(outputFolder); end

    idMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for i = 1:numel(ids)
        idMap(ids(i)) = i;
    end

    % apex_id is stored separately from id_p/id_d1/id_d2: id_p stops one
    % node short of it, and id_d1/id_d2 start one node past it.
    bif_ids = sort(unique([bifurcation.id_p; bifurcation.apex_id; bifurcation.id_d1; bifurcation.id_d2]));

    idx = zeros(numel(bif_ids), 1);
    for k = 1:numel(bif_ids)
        if ~isKey(idMap, bif_ids(k))
            error('bifurcation_to_swc:MissingNode', 'Node id %d not found in ids.', bif_ids(k));
        end
        idx(k) = idMap(bif_ids(k));
    end

    % SWC columns: id, type, x, y, z, radius, parent (type is unused
    % elsewhere in this pipeline; 3/dendrite by default, 1/soma for the
    % first row). The first row's parent is also forced to -1, since its
    % original parent lies outside this extracted subgraph.
    out_types = 3 * ones(numel(idx), 1);
    out_types(1) = 1;
    out_parents = parents(idx);
    out_parents(1) = -1;
    swcData = [ids(idx), out_types, coords(idx, :), radii(idx), out_parents];

    outputFile = fullfile(outputFolder, outputFilename);
    fid = fopen(outputFile, 'w');
    if fid < 0
        error('bifurcation_to_swc:OpenFailed', 'Failed to open file for writing: %s', outputFile);
    end
    fprintf(fid, '%d %d %.6f %.6f %.6f %.6f %d\n', swcData');
    fclose(fid);

    fprintf('SWC file saved to %s\n', outputFile);
end
