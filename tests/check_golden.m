% Reruns the bifurcation export driver into a temporary directory and
% verifies its output byte-for-byte (modulo CRLF/LF differences) against
% the golden set in tests/golden/swc_to_process, using the SHA-256
% hashes recorded in tests/golden/swc_to_process/manifest.sha256.
%
% Errors (via `error`) on any missing file, extra file, or hash mismatch,
% so a non-zero exit code in `matlab -batch` signals a golden-set drift.

projectRoot = fileparts(fileparts(mfilename('fullpath')));
addpath(fullfile(projectRoot, 'scripts'));

file_name = 'BG001.CNG.swc';
data_path = fullfile(projectRoot, 'data', 'raw', file_name);

% Must match the inflation settings in
% src/data_processing/select_bifurcations_for_meshing.m.
inflation_amount = 0.1;
inflation_mode = 'ratio';

[ids, coords, radii, parents] = decompose_network(read_swc(data_path));
apexes = find_apexes(ids, parents);

full_bifurcations = [];
full_apexes = [];
for i = 1:numel(apexes)
    bifurcation = select_bifurcation(apexes(i), ids, radii, parents);
    if is_full_bifurcation(bifurcation)
        full_bifurcations = [full_bifurcations; bifurcation];
        full_apexes = [full_apexes; apexes(i)];
    end
end

[~, dataset_name] = fileparts(file_name);
tempRoot = tempname();
outputFolder = fullfile(tempRoot, dataset_name);

for i = 1:numel(full_apexes)
    outputFilename = sprintf('bifurcation_%d.swc', full_apexes(i));
    new_swc_file = bifurcation_to_swc(full_bifurcations(i), ids, radii, coords, parents, outputFilename, outputFolder);
    [~, base_name] = fileparts(new_swc_file);
    outer_swc_file = fullfile(outputFolder, [base_name '_outer.swc']);
    inflate_swc_radius(new_swc_file, outer_swc_file, inflation_amount, inflation_mode);
end

goldenRoot = fullfile(projectRoot, 'tests', 'golden', 'swc_to_process');
manifestFile = fullfile(goldenRoot, 'manifest.sha256');

fid = fopen(manifestFile, 'r');
if fid < 0
    error('check_golden:NoManifest', 'Golden manifest not found: %s', manifestFile);
end
manifestLines = {};
line = fgetl(fid);
while ischar(line)
    if ~isempty(strtrim(line))
        manifestLines{end+1} = line; %#ok<AGROW>
    end
    line = fgetl(fid);
end
fclose(fid);

sha256 = System.Security.Cryptography.SHA256.Create();

goldenNames = cell(numel(manifestLines), 1);
mismatches = {};
nChecked = 0;
for i = 1:numel(manifestLines)
    parts = strsplit(manifestLines{i}, '  ');
    expectedHash = lower(parts{1});
    relPath = strjoin(parts(2:end), '  ');
    goldenNames{i} = relPath;

    producedFile = fullfile(tempRoot, relPath);
    if ~isfile(producedFile)
        mismatches{end+1} = sprintf('MISSING: %s', relPath); %#ok<AGROW>
        continue;
    end

    actualHash = lower(sprintf('%02x', double(sha256.ComputeHash(read_bytes_no_cr(producedFile)))));
    if ~strcmp(actualHash, expectedHash)
        mismatches{end+1} = sprintf('HASH MISMATCH: %s (expected %s, got %s)', relPath, expectedHash, actualHash); %#ok<AGROW>
    else
        nChecked = nChecked + 1;
    end
end

producedFiles = dir(fullfile(outputFolder, '*.swc'));
for i = 1:numel(producedFiles)
    relPath = strrep(fullfile(dataset_name, producedFiles(i).name), '\', '/');
    if ~any(strcmp(relPath, goldenNames))
        mismatches{end+1} = sprintf('UNEXPECTED FILE: %s', relPath); %#ok<AGROW>
    end
end

rmdir(tempRoot, 's');

if ~isempty(mismatches)
    error('check_golden:Mismatch', 'Golden comparison failed:\n%s', strjoin(mismatches, '\n'));
end

fprintf('check_golden: PASS - %d/%d golden files matched exactly.\n', nChecked, numel(manifestLines));

function bytes = read_bytes_no_cr(filePath)
    fid = fopen(filePath, 'rb');
    raw = fread(fid, Inf, '*uint8');
    fclose(fid);
    bytes = raw(raw ~= 13);
end
