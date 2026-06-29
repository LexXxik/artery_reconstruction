% Cubic penalised B-spline with chord-length parametrisation.
% Log-transforms radius to enforce positivity.
%
% Usage:
%   smoothed = runPenalizedSpline(segment)
%
% Inputs:
%   segment  - N x 4 matrix [X Y Z R] of centreline points and radii
%
% Output:
%   smoothed - 200 x 4 matrix [X Y Z R] resampled at high resolution
function smoothed = runPenalizedSpline(segment)
    k = 3; % cubic
    n = size(segment, 1);

    % Chord-length parametrisation
    diffs = diff(segment(:, 1:3));
    dist = [0; cumsum(sqrt(sum(diffs.^2, 2)))];
    u = dist / dist(end);

    % Clamped knot vector
    knots = [zeros(1, k), linspace(0, 1, n - k + 1), ones(1, k)];

    % B-spline basis and second-difference penalty
    N = spcol(knots, k + 1, u);
    S = (diff(eye(n), 2)' * diff(eye(n), 2));

    % Solve for control points (stronger smoothing for radius)
    solve = @(lam, y) (N'*N + lam*S) \ (N'*y);
    Px = solve(1e-3, segment(:,1));
    Py = solve(1e-3, segment(:,2));
    Pz = solve(1e-3, segment(:,3));
    Pr = solve(3.5e-2, log(segment(:,4)));

    % Reconstruct at high resolution
    u_fine  = linspace(0, 1, 200)';
    N_fine  = spcol(knots, k + 1, u_fine);
    smoothed = [N_fine*Px, N_fine*Py, N_fine*Pz, exp(N_fine*Pr)];
end
