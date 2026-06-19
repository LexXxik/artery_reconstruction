%% smooth_branch.m
% Main function to smooth bifurcation segments
% Usage: [smoothed_coords, smoothed_radii] = smooth_branch(coords, radii, num_out)

function [smoothed_coords, smoothed_radii] = smooth_branch(coords, radii, num_out)
    % Smooth a branch segment using PCHIP interpolation
    % 
    % Inputs:
    %   coords - n x 3 matrix [x, y, z]
    %   radii - n x 1 vector of radii
    %   num_out - number of output points
    %
    % Outputs:
    %   smoothed_coords - num_out x 3 matrix of interpolated coordinates
    %   smoothed_radii - num_out x 1 vector of interpolated radii
    
    % Create parameter vectors for original and interpolated points

    n = size(coords, 1);
    t = linspace(0, 1, n);
    t_fine = linspace(0, 1, num_out);
    
    % PCHIP prevents numerical "overshoot" and maintains C2 continuity
    x = pchip(t, coords(:,1), t_fine)';
    y = pchip(t, coords(:,2), t_fine)';
    z = pchip(t, coords(:,3), t_fine)';
    r = pchip(t, radii, t_fine)';
    
    smoothed_coords = [x, y, z];
    smoothed_radii = r;
end
