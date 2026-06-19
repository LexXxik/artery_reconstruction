% given a node id, determine if it is a side branch.
% A side branch is a daughter of an apex node that has smaller radii than the other daughter
function is_side = is_side_branch(node_id, ids, parents, radii)
    % Find the parent of the given node
    parent_id = parents(ids == node_id);
    
    % Find the children of the parent node
    child_ids = ids(parents == parent_id);
    
    % Check if the parent node is an apex
    if ~is_apex(parent_id, ids, parents)
        is_side = false;
    end
    
    % Get the radii of the children
    child_radii = radii(ismember(ids, child_ids));
    
    % Determine if the given node is a side branch (smaller radius)
    is_side = radii(ids == node_id) < max(child_radii);
end