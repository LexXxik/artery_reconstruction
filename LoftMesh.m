clc; clear;
% READ DATA FROM FILE
% Assumes a whitespace-delimited txt file with 4 columns:
% X Y Z R
input_filename = 'BH004_19M.txt';
data_matrix = readmatrix(input_filename);
%SPLIT DATA INTO DAUGHTER BRANCHES
% Adjust split index if needed
branch1_raw = data_matrix(1:48, :);
branch2_raw = data_matrix(49:end, :);
%SMOOTH BRANCH 1
smooth1 = runPenalizedSpline(branch1_raw);
%SMOOTH BRANCH 2
smooth2 = runPenalizedSpline(branch2_raw);
% Combine for final result
smooth_path = [smooth1; smooth2];
%WRITE SMOOTHED DATA TO FILE
output_filename = 'smoothed_output.txt';
writematrix(smooth_path, output_filename, 'Delimiter', 'tab');
%Verification - ensure radius hasn't warped at potential connnecting points
fprintf('--- SMOOTHING RESULTS ---\n');
fprintf('Branch 1: Min R = %.4f, Max R = %.4f\n', min(smooth1(:,4)), max(smooth1(:,4)));
fprintf('Branch 2: Min R = %.4f, Max R = %.4f\n', min(smooth2(:,4)), max(smooth2(:,4)));
fprintf('Smoothed data written to %s\n', output_filename);
% PAPER FUNCTION
function smoothed = runPenalizedSpline(segment)
X_raw = segment(:, 1);
Y_raw = segment(:, 2);
Z_raw = segment(:, 3);
R_raw = segment(:, 4);
n = size(segment, 1);
k = 3; % Cubic degree
% 1. Chord-Length Parametrization
diffs = diff(segment(:, 1:3));
dist = [0; cumsum(sqrt(sum(diffs.^2, 2)))];
u = dist / dist(end);
% 2. Knot Vector with Clamping
knots = [zeros(1, k), linspace(0, 1, n-k+1), ones(1, k)];
% 3. Basis and Penalty Matrices
N = spcol(knots, k+1, u);
D = diff(eye(n), 2);
S = D' * D;
% 4. Solvers with Different Lambda
A_path = (N' * N + 1e-3 * S);
A_rad = (N' * N + 3.5e-2 * S);
Px = A_path \ (N' * X_raw);
Py = A_path \ (N' * Y_raw);
Pz = A_path \ (N' * Z_raw);
% Log-transform radius
Pr = A_rad \ (N' * log(R_raw));
% 5. High-Resolution Reconstruction
u_fine = linspace(0, 1, 200)';
N_fine = spcol(knots, k+1, u_fine);
smoothed = [ ...
N_fine*Px, ...
N_fine*Py, ...
N_fine*Pz, ...
exp(N_fine*Pr) ...
];
end
fprintf('Smoothed data written to %s\n', output_filename);
%% BUILD GEOMETRY MODEL FROM SMOOTHED BRANCHES
nTheta = 30; % points around each circular cross-section
[X1,Y1,Z1] = tubeFromCenterline(smooth1, nTheta);
[X2,Y2,Z2] = tubeFromCenterline(smooth2, nTheta);
%% PLOT THE 3D MODEL
figure;
hold on;
surf(X1,Y1,Z1,'EdgeColor','none','FaceAlpha',0.95);
surf(X2,Y2,Z2,'EdgeColor','none','FaceAlpha',0.95);
axis equal;
grid on;
xlabel('X');
ylabel('Y');
zlabel('Z');
title('Vascular geometry model');
camlight headlight;
lighting gouraud;
view(3);
%% CONVERT SURFACES TO TRIANGLES
p1 = surf2patch(X1,Y1,Z1,'triangles');
p2 = surf2patch(X2,Y2,Z2,'triangles');
%% COMBINE BOTH BRANCHES INTO ONE TRIANGULATION
V = [p1.vertices; p2.vertices];
F = [p1.faces;
p2.faces + size(p1.vertices,1)];
TR = triangulation(F, V);
%% SAVE STL
stl_filename = 'vascular_model.stl';
stlwrite(TR, stl_filename);
fprintf('STL file written to %s\n', stl_filename);
function [X,Y,Z] = tubeFromCenterline(branch, nTheta)
% branch format: [X Y Z R]
P = branch(:,1:3);
R = branch(:,4);
nPts = size(P,1);
theta = linspace(0, 2*pi, nTheta+1);
theta(end) = [];
X = zeros(nPts, nTheta);
Y = zeros(nPts, nTheta);
Z = zeros(nPts, nTheta);
% Compute tangent vectors
T = zeros(nPts, 3);
for i = 1:nPts
if i == 1
v = P(2,:) - P(1,:);
elseif i == nPts
v = P(end,:) - P(end-1,:);
else
v = P(i+1,:) - P(i-1,:);
end
T(i,:) = v / norm(v);
end
% Build circular cross-sections along centreline
for i = 1:nPts
ref = [0 0 1];
if abs(dot(T(i,:), ref)) > 0.95
ref = [0 1 0];
end
N = cross(T(i,:), ref);
N = N / norm(N);
B = cross(T(i,:), N);
B = B / norm(B);
for j = 1:nTheta
pt = P(i,:) + R(i) * (cos(theta(j))*N + sin(theta(j))*B);
X(i,j) = pt(1);
Y(i,j) = pt(2);
Z(i,j) = pt(3);
end
end
end

