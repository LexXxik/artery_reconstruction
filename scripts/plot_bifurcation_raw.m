% Given a bifurcation consisting of bifucation segments make a 3D plot of the geometry made up of cylindrical segment of the specified radii.
% Optional input:
%   branch_colors: struct with fields parent, main_daughter, side_daughter
%                  each field is an RGB triplet
function plot_bifurcation_raw(bifurcation, radii, coords, ids, branch_colors)
    if nargin < 5
        branch_colors = default_branch_colors();
    else
        branch_colors = normalize_branch_colors(branch_colors);
    end

    apex_id = bifurcation.apex_id;
    parent_ids = make_parent_end_at_apex(bifurcation.id_p, apex_id);
    daughter1_ids = make_daughter_start_at_apex(bifurcation.id_d1, apex_id);
    daughter2_ids = make_daughter_start_at_apex(bifurcation.id_d2, apex_id);

    % Plot the bifurcation segments
    hold on;

    % Add a light source for shadow/shading
    light('Position', [1, 1, 2], 'Style', 'infinite');
    lighting gouraud;
    material dull;
    
    % Plot the parent segment leading up to the apex
    plot_segment(parent_ids, radii, coords, ids, branch_colors.parent);
    
    % Plot the main daughter branch
    plot_segment(daughter1_ids, radii, coords, ids, branch_colors.main_daughter);
    
    % Plot the side daughter branch
    plot_segment(daughter2_ids, radii, coords, ids, branch_colors.side_daughter);

    % Add legend using invisible proxy patches
    h_parent = patch(nan, nan, nan, 'FaceColor', branch_colors.parent, ...
        'EdgeColor', 'none', 'DisplayName', 'Parent');
    h_d1 = patch(nan, nan, nan, 'FaceColor', branch_colors.main_daughter, ...
        'EdgeColor', 'none', 'DisplayName', 'Main daughter');
    h_d2 = patch(nan, nan, nan, 'FaceColor', branch_colors.side_daughter, ...
        'EdgeColor', 'none', 'DisplayName', 'Side daughter');
    legend([h_parent, h_d1, h_d2]);

    hold off;
end

function plot_segment(segment_ids, radii, coords, ids, color)
    % rotate the cylinders so that they are aligned with the vector between the two nodes
    % ensure that cylinders are closed at both ends
    % Plot a segment of the bifurcation
    for i = 1:length(segment_ids)-1
        node_id_start = segment_ids(i);
        node_id_end = segment_ids(i+1);
        
        % Get the coordinates of the start and end nodes
        start_coords = coords(ids == node_id_start, :);
        end_coords = coords(ids == node_id_end, :);
        
        % Get the radius of the start node
        radius = radii(ids == node_id_start);

        % Direction and length of the segment
        segment_vector = end_coords - start_coords;
        segment_length = norm(segment_vector);
        if segment_length == 0
            continue;
        end
        direction = segment_vector / segment_length;
        
        % Create a cylinder between the two nodes
        [X, Y, Z] = cylinder(radius, 20);
        Z = Z * segment_length; % Scale Z to the distance between nodes

        % Build rotation matrix to map local +Z onto the segment direction
        z_axis = [0, 0, 1];
        cos_theta = dot(z_axis, direction);
        if cos_theta > 1 - 1e-12
            rotation_matrix = eye(3);
        elseif cos_theta < -1 + 1e-12
            rotation_matrix = [1, 0, 0; 0, -1, 0; 0, 0, -1];
        else
            rotation_axis = cross(z_axis, direction);
            axis_norm = norm(rotation_axis);
            skew_axis = [0, -rotation_axis(3), rotation_axis(2); ...
                         rotation_axis(3), 0, -rotation_axis(1); ...
                         -rotation_axis(2), rotation_axis(1), 0];
            rotation_matrix = eye(3) + skew_axis + skew_axis^2 * ((1 - cos_theta) / (axis_norm^2));
        end

        % Rotate and translate the cylinder to the start coordinates
        points = [X(:), Y(:), Z(:)]';
        rotated_points = rotation_matrix * points;
        X = reshape(rotated_points(1, :), size(X)) + start_coords(1);
        Y = reshape(rotated_points(2, :), size(Y)) + start_coords(2);
        Z = reshape(rotated_points(3, :), size(Z)) + start_coords(3);
        
        % Plot the cylinder wall
        surf(X, Y, Z, 'FaceColor', color, 'EdgeColor', 'none');

        % Close bottom and top of each cylinder segment
        patch(X(1, :), Y(1, :), Z(1, :), color, 'EdgeColor', 'none');
        patch(X(2, :), Y(2, :), Z(2, :), color, 'EdgeColor', 'none');
    end
end

function branch_colors = default_branch_colors()
    branch_colors.parent = [1, 0, 0]; % Red for parent
    branch_colors.main_daughter = [0, 1, 0]; % Green for main daughter
    branch_colors.side_daughter = [0.5, 0.5, 0.5]; % Gray for side daughter
end

function branch_colors = normalize_branch_colors(branch_colors)
    defaults = default_branch_colors();

    if ~isfield(branch_colors, 'parent')
        branch_colors.parent = defaults.parent;
    end
    if ~isfield(branch_colors, 'main_daughter')
        branch_colors.main_daughter = defaults.main_daughter;
    end
    if ~isfield(branch_colors, 'side_daughter')
        branch_colors.side_daughter = defaults.side_daughter;
    end
end

function parent_ids = make_parent_end_at_apex(parent_ids, apex_id)
    if isempty(parent_ids)
        return;
    end

    parent_ids = parent_ids(:);

    if parent_ids(end) == apex_id
        return;
    end
    if parent_ids(1) == apex_id
        parent_ids = flipud(parent_ids);
        return;
    end

    parent_ids = [parent_ids; apex_id];
end

function daughter_ids = make_daughter_start_at_apex(daughter_ids, apex_id)
    if isempty(daughter_ids)
        return;
    end

    daughter_ids = daughter_ids(:);

    if daughter_ids(1) == apex_id
        return;
    end
    if daughter_ids(end) == apex_id
        daughter_ids = flipud(daughter_ids);
        return;
    end

    daughter_ids = [apex_id; daughter_ids];
end