function json_path = tag_swc_endpoints_to_json(swc_path, output_path)
%TAG_SWC_ENDPOINTS_TO_JSON Save an SWC file's inlet/outlet info as JSON.
%
%   json_path = TAG_SWC_ENDPOINTS_TO_JSON(swc_path) tags the inlet and
%   outlet nodes of swc_path using tag_swc_endpoints, then writes them to
%   a JSON file next to the SWC file (same name, .json extension), ready
%   for coordinate-based boundary matching in COMSOL / LiveLink for
%   MATLAB.
%
%   json_path = TAG_SWC_ENDPOINTS_TO_JSON(swc_path, output_path) writes
%   to output_path instead of the default location.
%
%   JSON structure:
%       { "inlet": {id,x,y,z,r}, "outlets": [{id,x,y,z,r}, ...] }

    [inlet, outlets] = tag_swc_endpoints(swc_path);

    if nargin < 2 || isempty(output_path)
        [folder, name] = fileparts(swc_path);
        output_path = fullfile(folder, [name '.json']);
    end

    endpoints = struct('inlet', inlet, 'outlets', outlets);
    fid = fopen(output_path, 'w');
    if fid < 0
        error('tag_swc_endpoints_to_json:OpenFailed', ...
            'Failed to open file for writing: %s', output_path);
    end
    fprintf(fid, '%s', jsonencode(endpoints, 'PrettyPrint', true));
    fclose(fid);

    json_path = output_path;
    fprintf('Endpoints JSON saved to %s\n', output_path);
end
