% make a code that reads in the swc data, decomposes it into ids, coords, radii, and parents, and then identifies bifurcations (apexes) in the neuron structure. The code should also include tests for reading the swc file and plotting the neuron structure.
data_file = fullfile(projectRoot, 'data', 'raw', 'BG0014.CNG.swc');
% Read the SWC data
data = read_swc(data_file);
% Decompose the data into ids, coords, radii, and parents
[ids, coords, radii, parents] = decompose_network(data);
% Identify bifurcations (apexes) in the neuron structure
apex_ids = find_apexes(ids, parents);
% return points that are not apexes
not_apex_ids = setdiff(ids, apex_ids);
% eliminate points that are within 4 points of the apexes
for i = 1:length(apex_ids)
    apex_idx = find(ids == apex_ids(i));
    neighbors = max(1, apex_idx-4):min(length(ids), apex_idx+4);
    not_apex_ids = setdiff(not_apex_ids, ids(neighbors));
end

% count how many uniterupted segments are in the neuron structure

uninterrupted_segments = 0;
current_segment = 0;
for i = 1:length(not_apex_ids)
    if i == 1 || not_apex_ids(i) == not_apex_ids(i-1) + 1
        current_segment = current_segment + 1;
    else
        uninterrupted_segments = uninterrupted_segments + 1;
        current_segment = 1;
    end
end
if current_segment > 0
    uninterrupted_segments = uninterrupted_segments + 1;
end

% Caluculate the mean length of the uninterrupted segments
segment_lengths = diff([0; find(diff(not_apex_ids) > 1); length(not_apex_ids)]);
mean_segment_length = mean(segment_lengths);
% find the length of the shortest and longest segment
min_segment_length = min(segment_lengths);
max_segment_length = max(segment_lengths);

% print not apex ids
fprintf('There are %d not_apexes in the neuron structure.\n', length(not_apex_ids));
fprintf('There are %d uninterrupted segments in the neuron structure.\n', uninterrupted_segments);
fprintf('The mean length of the uninterrupted segments is %.2f.\n', mean_segment_length);
fprintf('The shortest uninterrupted segment is %d.\n', min_segment_length);
fprintf('The longest uninterrupted segment is %d.\n', max_segment_length);
