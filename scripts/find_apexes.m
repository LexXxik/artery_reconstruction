% Make a function that finds all the apex nodes in the network: point that have two or more children. Return the ids of the apex nodes.
% nodes is a matrix containing two columns: ids, parent_ids
function apex_ids = find_apexes(ids, parents)
    % use is_apex function
    apex_ids = ids(arrayfun(@(id) is_apex(id, ids, parents), ids));

end