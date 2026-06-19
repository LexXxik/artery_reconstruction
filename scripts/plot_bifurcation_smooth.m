% Plot smoothed bifurcation branches and save a CAD-ready figure.
%
% Inputs:
%   bifurcation    Struct from select_bifurcation
%   radii          Vector of node radii
%   coords         N-by-3 matrix [x y z]
%   ids            Vector of node IDs
%   outputFilename Optional output image name
%
% Output:
%   outputFile     Absolute path to generated image
function outputFile = plot_bifurcation_smooth(bifurcation, radii, coords, ids, outputFilename)
	if nargin < 4
		error('plot_bifurcation_smooth:InvalidInput', ...
			'Required inputs: bifurcation, radii, coords, ids.');
	end

	if nargin < 5 || isempty(outputFilename)
		outputFilename = 'bifurcation_smooth.png';
	end

	[~, ~, ext] = fileparts(outputFilename);
	if isempty(ext)
		outputFilename = [outputFilename, '.png'];
	end

	idMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
	for i = 1:numel(ids)
		idMap(ids(i)) = i;
	end

	id_p = bifurcation.id_p;
	id_d1 = bifurcation.id_d1;
	id_d2 = bifurcation.id_d2;
	apex_id = bifurcation.apex_id;

	parentSeg = get_segment_matrix(id_p, idMap, coords, radii);
	d1Seg = get_segment_matrix(id_d1, idMap, coords, radii);
	d2Seg = get_segment_matrix(id_d2, idMap, coords, radii);

	[smoothP, ~] = smooth_branch(parentSeg(:,1:3), parentSeg(:,4), 25);
	[smoothD1, ~] = smooth_branch(d1Seg(:,1:3), d1Seg(:,4), 25);
	[smoothD2, ~] = smooth_branch(d2Seg(:,1:3), d2Seg(:,4), 25);

	if ~isKey(idMap, apex_id)
		error('plot_bifurcation_smooth:MissingApex', 'Apex ID %d not found in ids.', apex_id);
	end
	apex = coords(idMap(apex_id), :);

	%% 4. FIGURE 2: SMOOTHED (CAD-READY)
	fig = figure('Color', 'w', 'Name', 'AFTER: Smoothed C2 Splines (19M)');
	hold on;
	grid on;
	axis equal;
	view(0,0);
	xlabel('X (mm)');
	zlabel('Z (mm)');
	title('AFTER SMOOTHING: 25-Point PCHIP Splines (Mesh-Ready)');

	% Branch colours — consistent with plot_bifurcation_raw / plot_swc
	c_P  = [0.7, 0.0, 0.7];   % parent     – magenta
	c_D1 = [0.0, 0.8, 0.8];   % daughter 1 – cyan
	c_D2 = [1.0, 0.5, 0.0];   % daughter 2 – orange

	% Plot smoothed result
	plot3(smoothP(:,1),  smoothP(:,2),  smoothP(:,3),  '-', 'Color', c_P,  'LineWidth', 3, 'DisplayName', 'Smooth Parent');
	plot3(smoothD1(:,1), smoothD1(:,2), smoothD1(:,3), '-', 'Color', c_D1, 'LineWidth', 3, 'DisplayName', 'Smooth Daughter 1');
	plot3(smoothD2(:,1), smoothD2(:,2), smoothD2(:,3), '-', 'Color', c_D2, 'LineWidth', 3, 'DisplayName', 'Smooth Daughter 2');

	% Highlight the Apex connection point
	plot3(apex(1), apex(2), apex(3), 'kp', 'MarkerSize', 12, 'MarkerFaceColor', 'y', ...
		'DisplayName', sprintf('Shared Apex (id = %d)', apex_id));

	legend('Location', 'best');

	scriptDir = fileparts(mfilename('fullpath'));
	projectRoot = fullfile(scriptDir, '..');
	outputDir = fullfile(projectRoot, 'results', 'visualization');
	if ~exist(outputDir, 'dir')
		mkdir(outputDir);
	end

	outputFile = fullfile(outputDir, outputFilename);
	saveas(fig, outputFile);
end

function segMat = get_segment_matrix(segIds, idMap, coords, radii)
	segIdx = zeros(numel(segIds), 1);
	for k = 1:numel(segIds)
		if ~isKey(idMap, segIds(k))
			error('plot_bifurcation_smooth:MissingNode', 'Node ID %d not found in ids.', segIds(k));
		end
		segIdx(k) = idMap(segIds(k));
	end

	segCoords = coords(segIdx, :);
	segRadii = radii(segIdx);
	segMat = [segCoords, segRadii];
end