% Given a node find its daughters. The function takes in the node id, ids, and parents as inputs and returns the ids of the daughters.
function daughter_ids = find_daughters(node_id, ids, parents)
    % Find the daughters of the given node
    daughter_ids = ids(parents == node_id);
end