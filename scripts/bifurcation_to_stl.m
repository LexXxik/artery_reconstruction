%% bifurcation_to_stl.m
%% UNFINISHED: This script is a work in progress and may not be fully functional yet.
% Smooth each daughter branch of a bifurcation and export a combined STL.
%
% Usage:
%   bifurcation_to_stl(bifurcation, radii, coords, ids, outputFilename)
%   bifurcation_to_stl(bifurcation, radii, coords, ids, outputFilename, plot)
%
% Inputs:
%   bifurcation    - struct from select_bifurcation (fields: id_d1, id_d2)
%   radii          - N x 1 vector of node radii
%   coords         - N x 3 matrix of node coordinates [x, y, z]
%   ids            - N x 1 vector of node ids
%   outputFilename - base filename for the STL (saved to results/stl_models/)
%   plot           - (optional) logical flag; if true, plots the 3D model

function bifurcation_to_stl(bifurcation, radii, coords, ids, outputFilename, plot)

    if nargin < 6
        plot = false;
    end

    nTheta = 30; % cross-section resolution

    % --- Smooth and mesh each daughter branch ---
    %smooth_d1 = runPenalizedSpline_wrapper(bifurcation.id_d1, ids, coords, radii);
    % concatenate id_p and id_d1 to ensure smooth transition at the bifurcation point
    smooth_d1 = runPenalizedSpline_wrapper([bifurcation.id_p; bifurcation.id_d1], ids, coords, radii);
    smooth_d2 = runPenalizedSpline_wrapper(bifurcation.id_d2, ids, coords, radii);

    [X1, Y1, Z1] = tubeFromCenterline(smooth_d1, nTheta);
    [X2, Y2, Z2] = tubeFromCenterline(smooth_d2, nTheta);

    % Append first column to close the tube circumferentially
    X1c = [X1, X1(:,1)];
    Y1c = [Y1, Y1(:,1)];
    Z1c = [Z1, Z1(:,1)];

    p1 = surf2patch(X1c, Y1c, Z1c, 'triangles');

    X2c = [X2, X2(:,1)];
    Y2c = [Y2, Y2(:,1)];
    Z2c = [Z2, Z2(:,1)];

    p2 = surf2patch(X2c, Y2c, Z2c, 'triangles');

    % OLD IMPLEMENTATION: Combine both branches into one triangulation
    % --- Combine into one triangulation ---
    %p1 = surf2patch(X1, Y1, Z1, 'triangles');
    %p2 = surf2patch(X2, Y2, Z2, 'triangles');

    V = [p1.vertices; p2.vertices];
    F = [p1.faces; p2.faces + size(p1.vertices, 1)];
    TR = triangulation(F, V);

    % --- Save STL ---
    outDir = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'stl_models');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    stlPath = fullfile(outDir, outputFilename);
    stlwrite(TR, stlPath);
    fprintf('STL saved to %s\n', stlPath);

    if plot
        plotGeometryModel(X1c, Y1c, Z1c, X2c, Y2c, Z2c);
    end
end


% -------------------------------------------------------------------------
function segment = runPenalizedSpline_wrapper(branch_ids, ids, coords, radii)
    % Extract [X Y Z R] for the given node ids and apply penalised spline

    idx     = arrayfun(@(id) find(ids == id, 1), branch_ids);
    segment = runPenalizedSpline([coords(idx, :), radii(idx)]);
end


% -------------------------------------------------------------------------
function [X, Y, Z] = tubeFromCenterline(branch, nTheta)
    % Build a tube surface around a centreline stored as [X Y Z R].

    P     = branch(:, 1:3);
    R     = branch(:, 4);
    nPts  = size(P, 1);
    theta = linspace(0, 2*pi, nTheta + 1);  theta(end) = [];

    X = zeros(nPts, nTheta);
    Y = zeros(nPts, nTheta);
    Z = zeros(nPts, nTheta);

    % Finite-difference tangents
    T = [P(2,:)-P(1,:); (P(3:end,:)-P(1:end-2,:))/2; P(end,:)-P(end-1,:)];
    T = T ./ vecnorm(T, 2, 2);

    % Swept cross-sections via Frenet-like frame
    for i = 1:nPts
        ref = [0 0 1];
        if abs(dot(T(i,:), ref)) > 0.95, ref = [0 1 0]; end

        N = cross(T(i,:), ref);   N = N / norm(N);
        B = cross(T(i,:), N);     B = B / norm(B);

        % Vectorised but safe
        cos_t = cos(theta(:));   % [nTheta x 1]
        sin_t = sin(theta(:));   % [nTheta x 1]
        pts = P(i,:) + R(i) * (cos_t * N + sin_t * B);  % [nTheta x 3]
        X(i,:) = pts(:,1);
        Y(i,:) = pts(:,2);
        Z(i,:) = pts(:,3);
    end
end


% -------------------------------------------------------------------------
function plotGeometryModel(X1, Y1, Z1, X2, Y2, Z2)
    % Plot the smoothed daughter branch geometry.

    figure;
    hold on;
    surf(X1, Y1, Z1, 'EdgeColor', 'none', 'FaceAlpha', 0.95);
    surf(X2, Y2, Z2, 'EdgeColor', 'none', 'FaceAlpha', 0.95);
    axis equal;
    grid on;
    xlabel('X');
    ylabel('Y');
    zlabel('Z');
    title('Vascular geometry model');
    camlight headlight;
    lighting gouraud;
    view(3);
end
