% Make a function that plots apexes on the neuron structure. The function should take in the ids, coords, radii, parents, and apex_ids as inputs and plot the neuron structure with apexes highlighted.
function outputFile = plot_apexes(ids, coords, radii, parents, apex_ids, outputFilename)
    
    % Create a new figure
    figure;
    hold on;
    
    % Plot the neuron structure
    for i = 1:length(ids)
        if parents(i) > 0
            parent_idx = find(ids == parents(i));
            plot3([coords(i,1), coords(parent_idx,1)], ...
                  [coords(i,2), coords(parent_idx,2)], ...
                  [coords(i,3), coords(parent_idx,3)], 'b-');
        end
    end
    
    % Highlight apexes
    for i = 1:length(apex_ids)
        apex_idx = find(ids == apex_ids(i));
        scatter3(coords(apex_idx,1), coords(apex_idx,2), coords(apex_idx,3), ...
                 radii(apex_idx)*100, 'r', 'filled');
    end
    
    % Set labels and title
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Neuron Structure with Apexes Highlighted');
    %save the figure in the results visualization folder
    hold off;
    scriptDir = fileparts(mfilename('fullpath'));
    projectRoot = fullfile(scriptDir, '..');
    outputDir = fullfile(projectRoot, 'results', 'visualization');
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end

    outputFile = fullfile(outputDir, outputFilename);
    saveas(gcf, outputFile);
end