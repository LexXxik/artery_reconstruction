function read_swc_test(dataDir)
% READ_SWC_TEST Simple test for read_swc comparing to readmatrix.
%
% This test loads `my_pipeline/data/raw/BG001.CNG.swc` using both
% `read_swc` (the reader) and MATLAB's `readmatrix`, then compares results.

% Arrange
raw_filename = fullfile(dataDir, 'BG001.CNG.swc');
expected_row = [1 1 86.8 -109.12 109.74 1.24 -1];

% Act
A = read_swc(raw_filename);
row1 = double(A(1,:));

% Assert
tol_row = 1e-6;
if ~isequal(size(row1), size(expected_row)) || any(abs(row1 - expected_row) > tol_row)
    fprintf('FAIL: A(1,:) does not match expected row.\nExpected: %s\nFound:    %s\n', mat2str(expected_row), mat2str(row1));
    return;
else
    fprintf('PASS: read_swc matches expected row.\n');
end
end