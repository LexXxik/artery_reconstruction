function out_path = inflate_swc_radius(in_path, out_path, thickness, mode)
%INFLATE_SWC_RADIUS Write an inflated-radius copy of an SWC file.
%
%   out_path = INFLATE_SWC_RADIUS(in_path, out_path) writes a copy of the
%   SWC file at in_path to out_path with the radius column inflated by
%   10% (thickness = 0.1, mode = 'ratio').
%
%   out_path = INFLATE_SWC_RADIUS(in_path, out_path, thickness, mode)
%   controls the amount and style of inflation.
%
%   Same centerline, radius scaled/offset outward to represent the outer
%   wall surface. Feed the original file into vascularmd for the lumen
%   (fluid domain) surface, and the inflated copy into vascularmd for the
%   outer wall surface -- reusing vascularmd's own bifurcation-blending
%   geometry at both radii, rather than offsetting an already-generated
%   surface.
%
%   Inputs:
%       in_path   - source SWC file
%       out_path  - where to write the inflated copy
%       thickness - wall thickness (default 0.1)
%                     mode 'ratio'    -> outer = inner * (1 + thickness)
%                     mode 'absolute' -> outer = inner + thickness
%       mode      - 'ratio' (default) or 'absolute'. 'ratio' scales with
%                   local vessel radius, so a fixed thickness doesn't
%                   become disproportionately large at small distal
%                   branches -- more physiological and less likely to
%                   self-intersect at tight bifurcations.

    if nargin < 3 || isempty(thickness)
        thickness = 0.1;
    end
    if nargin < 4 || isempty(mode)
        mode = 'ratio';
    end
    if ~ismember(mode, {'ratio', 'absolute'})
        error('inflate_swc_radius:InvalidMode', "mode must be 'ratio' or 'absolute'");
    end

    fid_in = fopen(in_path, 'r');
    if fid_in < 0
        error('inflate_swc_radius:OpenFailed', 'Failed to open file for reading: %s', in_path);
    end
    fid_out = fopen(out_path, 'w');
    if fid_out < 0
        fclose(fid_in);
        error('inflate_swc_radius:OpenFailed', 'Failed to open file for writing: %s', out_path);
    end

    while true
        line = fgetl(fid_in);
        if ~ischar(line)
            break;
        end

        stripped = strtrim(line);
        if isempty(stripped) || startsWith(stripped, '#')
            fprintf(fid_out, '%s\n', line);
            continue;
        end

        parts = strsplit(stripped);
        r = str2double(parts{6});
        if strcmp(mode, 'ratio')
            r_outer = r * (1.0 + thickness);
        else
            r_outer = r + thickness;
        end
        parts{6} = sprintf('%.6f', r_outer);

        fprintf(fid_out, '%s\n', strjoin(parts, ' '));
    end

    fclose(fid_in);
    fclose(fid_out);
end
