function plot_swc_test(dataDir)
% PLOT_SWC_TEST Validates that plot_swc generates and saves an image.

if nargin < 1 || isempty(dataDir)
	error('plot_swc_test:MissingInput', 'Usage: plot_swc_test(dataDir)');
end

rawFile = fullfile(dataDir, 'BG001.CNG.swc');
if ~isfile(rawFile)
	fprintf('FAIL: Test SWC file not found: %s\n', rawFile);
	return;
end

data = read_swc(rawFile);

outName = ['BG001_plot_test_', datestr(now, 'yyyymmdd'), '.png'];
outPath = plot_swc(data, outName);

if ~isfile(outPath)
	fprintf('FAIL: plot_swc did not create output image: %s\n', outPath);
	return;
end

fileInfo = dir(outPath);
if isempty(fileInfo) || fileInfo.bytes <= 0
	fprintf('FAIL: Output image is empty: %s\n', outPath);
	return;
end

disp('PASS: plot_swc created image.');
end
