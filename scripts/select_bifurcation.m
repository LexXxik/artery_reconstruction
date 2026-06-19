% Make a function that takes apex id and constructs a bifurcation
% bifurcation contains 4 nodes leading up to apex called id_parent
% 4 nodes for each branch of apex called id_d1, id_d2
% id_d1 is the main continuation of the branch and id_d2 is the side branch
% the logic distinguishinng main and side branch is contained in a function is_side_branch

%NOT FINSIHED
function bifurcation = select_bifurcation(apex_id, ids, coords, radii, parents)
    % Find the parent of the apex node
    id_parent = parents(ids == apex_id);
    
    % Find the children of the apex node
    child_ids = ids(parents == apex_id);
    
    % Initialize bifurcation structure
    bifurcation = struct('id_parent', id_parent, 'id_d1', [], 'id_d2', []);
    
    % Check if there are at least two children
    if length(child_ids) < 2
        error('Apex node must have at least two children to form a bifurcation.');
    end
    
    % Determine which child is the main continuation and which is the side branch
    if is_side_branch(child_ids(1), ids, parents)
        bifurcation.id_d1 = child_ids(2);
        bifurcation.id_d2 = child_ids(1);
    else
        bifurcation.id_d1 = child_ids(1);
        bifurcation.id_d2 = child_ids(2);
    end
end