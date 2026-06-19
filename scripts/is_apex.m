% Determine if the given node is an apex based on their IDs.
function is_apex_node = is_apex(node_id, ids, parents) 
    % Find the children of the given node
    child_ids = ids(parents == node_id);
    
    % A node is an apex if it has two or more children
    is_apex_node = length(child_ids) >= 2;
end