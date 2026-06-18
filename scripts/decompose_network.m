% Make a function to decompose and interpret swc data into ids, coords, radii, parents
function [ids, coords, radii, parents] = decompose_network(data)
    ids = round(data(:,1));
    coords = data(:,3:5);
    radii = data(:,6);
    parents = round(data(:,7));
end