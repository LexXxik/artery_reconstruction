
function data = read_swc(filename)
% READ_SWC Read an SWC-format morphology file.
%   data = READ_SWC(filename) returns an N-by-7 numeric matrix with columns
%   [id, type, x, y, z, radius, parent]. `filename` may be a full path or a
%   basename located in the project's data/raw folder.

if nargin < 1 || isempty(filename)
	error('Usage: data = read_swc(filename)');
end

found = '';
if isfile(filename)
	found = filename;
end

if isempty(found)
	error('read_swc:FileNotFound', 'Could not find file ''%s'' in candidates.', filename);
end

fid = fopen(found, 'r');
if fid < 0
	error('read_swc:OpenFailed', 'Failed to open file: %s', found);
end

% Read numeric rows. SWC files can contain comments beginning with '#'.
dataC = textscan(fid, '%f%f%f%f%f%f%f', 'CommentStyle', '#', 'MultipleDelimsAsOne', true);
fclose(fid);

if isempty(dataC) || isempty(dataC{1})
	data = zeros(0,7);
else
	data = [dataC{1}(:), dataC{2}(:), dataC{3}(:), dataC{4}(:), dataC{5}(:), dataC{6}(:), dataC{7}(:)];
end

% Ensure first, second and last (parent) columns are integer-valued.
if ~isempty(data)
	idx = [1,2,7];
	% Round to nearest integer to preserve expected discrete ids/types
	data(:,idx) = round(data(:,idx));
end
end
