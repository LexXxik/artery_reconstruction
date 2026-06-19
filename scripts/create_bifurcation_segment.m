% Make a function that returns ids of 4 parents up the network, or down the chain as specified by user
function bifurcation_segment = create_bifurcation_segment(target_id, ids, parents, forward)
    % Initialize the bifurcation segment with the target_id
    bifurcation_segment = target_id;
    
    % Traverse the network in the specified direction
    current_id = target_id;
    for i = 1:3
        if forward
            % Move down the network to find the children
            child_ids = ids(parents == current_id);
            if isempty(child_ids) || is_apex(child_ids(1), ids, parents) || is_apex(current_id, ids, parents)
                break; % No more children, exit the loop
            end
            bifurcation_segment = [bifurcation_segment; child_ids(1)]; % Take the first child for simplicity
            current_id = child_ids(1);
        else
            % Move up the network to find the parent
            parent_id = parents(ids == current_id);
            if isempty(parent_id) || parent_id == -1 || is_apex(parent_id, ids, parents)
                break; % No more parents, exit the loop
            end
            bifurcation_segment = [bifurcation_segment; parent_id];
            current_id = parent_id;
        end
    end
    

end