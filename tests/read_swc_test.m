function read_swc_test(dataDir)
% READ_SWC_TEST Simple test for read_swc comparing to readmatrix.
%
% This test loads `my_pipeline/data/raw/BG001.CNG.swc` using both
% `read_swc` (the reader) and MATLAB's `readmatrix`, then compares results.

raw_filename = fullfile(dataDir, 'BG001.CNG.swc');

% Run reader under test
A = read_swc(raw_filename);

%display(A);
display(A(1,:));
% Compare A(1,:) to expected row from SWC file string
expected_row = [1 1 86.8 -109.12 109.74 1.24 -1];
row1 = double(A(1,:));
tol_row = 1e-6;
if ~isequal(size(row1), size(expected_row)) || any(abs(row1 - expected_row) > tol_row)
    fprintf('FAIL: A(1,:) does not match expected row.\nExpected: %s\nFound:    %s\n', mat2str(expected_row), mat2str(row1));
    return;
else
    fprintf('PASS: A(1,:) matches expected row.\n');
end
end