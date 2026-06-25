% Make a function that takes apex id and constructs a bifurcation
% bifurcation contains 4 nodes leading up to apex called id_parent
% 4 nodes for each branch of apex called id_d1, id_d2
% id_d1 is the main continuation of the branch and id_d2 is the side branch
% the logic distinguishinng main and side branch is contained in a function is_side_branch

% use create bifurcation segment to get the 4 nodes leading up to apex and the 4 nodes leading down from apex in each daughter branch
function bifurcation = select_bifurcation(apex_id, ids, radii, parents)
    % Get the 4 nodes leading up to the apex
    bifurcation_up = create_bifurcation_segment(apex_id, ids, parents, false);
    
    % Get the daughters of the apex
    daughter_ids = find_daughters(apex_id, ids, parents);
    
    % Determine which daughter is the side branch and which is the main branch
    if is_side_branch(daughter_ids(1), ids, parents, radii)
        id_d1 = daughter_ids(2); % Main branch
        id_d2 = daughter_ids(1); % Side branch
    else
        id_d1 = daughter_ids(1); % Main branch
        id_d2 = daughter_ids(2); % Side branch
    end
    
    % Get the 4 nodes leading down from each daughter branch
    bifurcation_down_d1 = create_bifurcation_segment(id_d1, ids, parents, true);
    bifurcation_down_d2 = create_bifurcation_segment(id_d2, ids, parents, true);
    
    % Combine all parts of the bifurcation into a single structure
    % daughter 1 is treated as a continuation of the parent branch, while daughter 2 is treated as a side branch
    bifurcation.id_p = bifurcation_up;
    bifurcation.id_d1 = [bifurcation_down_d1];
    bifurcation.id_d2 = [apex_id; bifurcation_down_d2];
    bifurcation.apex_id = apex_id; % Store the apex id for reference
end