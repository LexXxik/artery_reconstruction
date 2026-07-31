function out_files = batch_inflate_swc(swc_folder, thickness, mode, suffix)
%BATCH_INFLATE_SWC Generate an inflated-radius sibling file for every SWC
%in a folder.
%
%   out_files = BATCH_INFLATE_SWC(swc_folder) inflates every *.swc file
%   in swc_folder by 10% (thickness = 0.1, mode = 'ratio') and writes
%   '<name><suffix>.swc' siblings (default suffix '_outer'), skipping
%   files whose name already ends in suffix.
%
%   out_files = BATCH_INFLATE_SWC(swc_folder, thickness, mode, suffix)
%   controls the inflation amount/style (see INFLATE_SWC_RADIUS) and the
%   sibling filename suffix.
%
%   Output:
%       out_files - cell array of paths to the generated sibling files

    if nargin < 2 || isempty(thickness)
        thickness = 0.1;
    end
    if nargin < 3 || isempty(mode)
        mode = 'ratio';
    end
    if nargin < 4 || isempty(suffix)
        suffix = '_outer';
    end

    files = dir(fullfile(swc_folder, '*.swc'));
    out_files = {};
    for k = 1:numel(files)
        [~, name] = fileparts(files(k).name);
        if endsWith(name, suffix)
            continue;
        end

        in_path = fullfile(files(k).folder, files(k).name);
        out_name = [name suffix '.swc'];
        out_path = fullfile(files(k).folder, out_name);
        inflate_swc_radius(in_path, out_path, thickness, mode);
        fprintf('%s -> %s\n', files(k).name, out_name);
        out_files{end+1, 1} = out_path; %#ok<AGROW>
    end
end
