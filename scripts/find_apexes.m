% Make a function that finds all the apex nodes in the network: point that have two or more children. Return the ids of the apex nodes.
% nodes is a matrix containing two columns: ids, parent_ids
function apex_ids = find_apexes(nodes)
    parents = nodes(:,2);
    % Create a map to count the number of children for each parent
    child_count = containers.Map('KeyType', 'double', 'ValueType', 'double');
    
    % Count the number of children for each parent
    for i = 1:length(parents)
        p_id = parents(i);
        if p_id > 0  % Ignore root nodes (parent id <= 0)
            if isKey(child_count, p_id)
                child_count(p_id) = child_count(p_id) + 1;
            else
                child_count(p_id) = 1;
            end
        end
    end
    
    % Find apex nodes (parents with two or more children)
    apex_ids = [];
    keys = child_count.keys;
    for i = 1:length(keys)
        if child_count(keys{i}) >= 2
            apex_ids(end+1) = keys{i}; %#ok<AGROW>
        end
    end
end