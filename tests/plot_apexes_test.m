% Make a function to check that plt_apexes saves a figure in the results/visualization folder. The function should take in the ids, coords, radii, parents, and apex_ids as inputs and plot the neuron structure with apexes highlighted. The function should then check that the figure was saved in the correct location.
function plot_apexes_test(dataDir)
    % Arrange
    data_name = 'BG0014.CNG.swc';
    outName = [data_name, '_', datestr(now, 'yyyymmdd'), '.png'];
    % Act
    data_file = fullfile(dataDir, 'BG0014.CNG.swc');
    data = read_swc(data_file);
    [ids, coords, radii, parents] = decompose_network(data);
    apex_ids = find_apexes(ids, parents);
    output_Path = plot_apexes(ids, coords, radii, parents, apex_ids, outName);
    
    % Assert
    assert(isfile(output_Path), 'Figure was not saved in the expected location.');
    
    disp('PASS: plt_apexes_test saved the figure successfully.');
end