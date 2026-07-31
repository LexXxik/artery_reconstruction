function [inlet, outlets] = tag_swc_endpoints(swc_path)
%TAG_SWC_ENDPOINTS Identify the inlet (root) and outlet (leaf) nodes of an SWC tree.
%
%   [inlet, outlets] = TAG_SWC_ENDPOINTS(swc_path) reads an SWC file and
%   returns the coordinates of its root node (inlet) and every terminal
%   node (outlet).
%
%   SWC columns are: id, type, x, y, z, r, parent.
%   - The inlet is the node with parent == -1 (the tree root).
%   - Outlets are nodes that never appear in the parent column, i.e.
%     nodes with no children.
%
%   Outputs:
%       inlet   - 1x1 struct with fields id, x, y, z, r
%       outlets - Nx1 struct array with the same fields
%
%   Coordinates are taken as written in the SWC file. vascularmd may
%   lightly resample or smooth the centerline near the ends, so treat
%   these as points to search NEAR later (nearest-neighbour match),
%   not as exact keys into the generated mesh.

    data = readmatrix(swc_path, 'FileType', 'text', 'CommentStyle', '#');
    id = data(:,1); x = data(:,3); y = data(:,4); z = data(:,5);
    r = data(:,6); parent = data(:,7);

    % Inlet: the node with no parent
    isRoot = (parent == -1);
    assert(sum(isRoot) == 1, ...
        '%s: expected exactly one root (parent == -1), found %d.', ...
        swc_path, sum(isRoot));
    inlet = struct('id', id(isRoot), 'x', x(isRoot), 'y', y(isRoot), ...
        'z', z(isRoot), 'r', r(isRoot));

    % Outlets: nodes that never appear as someone else's parent
    isTerminal = ~ismember(id, parent);
    outlets = struct('id', num2cell(id(isTerminal)), ...
        'x', num2cell(x(isTerminal)), 'y', num2cell(y(isTerminal)), ...
        'z', num2cell(z(isTerminal)), 'r', num2cell(r(isTerminal)));

    fprintf('%s: 1 inlet, %d outlet(s)\n', swc_path, numel(outlets));
end