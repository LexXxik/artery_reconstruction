% Plot bifurcation by reusing plot_swc and its zoomBif feature.
%
% Inputs:
%   bifurcation    Struct from select_bifurcation
%   radii          Vector of node radii
%   coords         N-by-3 matrix [x y z]
%   ids            Vector of node IDs
%   parents        Vector of parent IDs (required)
%   outputFilename Optional output image name
%   zoomBif        Optional logical flag (default true)
%
% Output:
%   outputFile     Absolute path to generated image
function outputFile = plot_bifurcation_raw(bifurcation, radii, coords, ids, parents, outputFilename, zoomBif)
    if nargin < 5 || isempty(parents)
        error('plot_bifurcation_raw:MissingParents', ...
            'parents is required so plot_swc can render network edges.');
    end

    if nargin < 6 || isempty(outputFilename)
        outputFilename = 'bifurcation_raw.png';
    end

    if nargin < 7 || isempty(zoomBif)
        zoomBif = true;
    end

    outputFile = plot_swc(ids, coords, radii, parents, outputFilename, bifurcation, zoomBif);
end