%% generate_smooth_bifurcation.m
% Build a parametric bifurcation model from five cross-sections, following
% the model of Decroocq et al. Bifurcations are modeled as the combination
% of two tubes sharing the same inlet cross-section C0. Each tube is
% defined by three cross-sections: the shared inlet C0, an apical
% cross-section (AC1 or AC2, both located at the apex point AP) and an
% outlet cross-section (C1 or C2, cut one diameter downstream of AP).
%
% Parameter estimation (where AP/AC1/AC2/C0/C1/C2 actually are) follows
% the paper's two-step recipe:
%   1. The last two parent nodes are concatenated with each daughter branch
%      in turn, forming two independent single-tube vessel models (each
%      smoothed with a penalised cubic B-spline, runPenalizedSpline) that
%      both run from the same inlet.
%   2. Each vessel's local cross-section is a circular DISK lying in the
%      plane orthogonal to that vessel's own local tangent -- not a sphere,
%      since the two tangents are generally not parallel near a
%      bifurcation, so naively comparing center distance to the sum of
%      radii is only exact when the two disks are coplanar. AP is instead
%      found as the point where the two oriented disks (each rotated by
%      its own centreline tangent) first stop intersecting when walking
%      from the inlet outwards. The position/tangent of each vessel at
%      that arclength give AC1/AC2 (centre + normal); C1/C2 are evaluated
%      one diameter further along each vessel; C0 is the shared inlet.
%
% Each circular cross-section is described by its centre Pc, radius rc and
% normal vector nc. The FINAL bifurcation centreline (spl1, spl2) is then
% rebuilt from these five cross-sections as two cubic-Hermite segments per
% tube: C0 -> AC and AC -> C. The tangent of each segment endpoint matches
% the normal of the cross-section it connects to, and the radius evolves
% linearly (by arclength) along each segment.
%
% Usage:
%   model = generate_smooth_bifurcation(bifurcation, radii, coords, ids, outputFilename)
%   model = generate_smooth_bifurcation(bifurcation, radii, coords, ids, outputFilename, plotFlag)
%
% Inputs:
%   bifurcation    - struct from select_bifurcation (fields: id_p, id_d1, id_d2, apex_id)
%   radii          - N x 1 vector of node radii
%   coords         - N x 3 matrix of node coordinates [x, y, z]
%   ids            - N x 1 vector of node ids
%   outputFilename - base filename for the STL (saved to results/stl_models/)
%   plotFlag       - (optional) logical flag; if true, plots the model (default false)
%
% Output:
%   model - struct with fields C0, AC1, AC2, C1, C2 (each holding center,
%           radius, normal), spl1, spl2 (each holding points, radii sampled
%           along the centreline), and AP (the estimated apex point)

function model = generate_smooth_bifurcation(bifurcation, radii, coords, ids, outputFilename, plotFlag)

    if nargin < 4
        error('generate_smooth_bifurcation:InvalidInput', ...
            'Required inputs: bifurcation, radii, coords, ids.');
    end

    if nargin < 5 || isempty(outputFilename)
        outputFilename = 'smooth_bifurcation.stl';
    end
    [~, ~, ext] = fileparts(outputFilename);
    if isempty(ext)
        outputFilename = [outputFilename, '.stl'];
    end

    if nargin < 6 || isempty(plotFlag)
        plotFlag = false;
    end

    nTheta  = 30;  % cross-section circumferential resolution
    nSeg    = 40;  % points sampled per Hermite segment
    nSearch = 200; % per-vessel grid resolution for the all-pairs apex search

    idMap = containers.Map('KeyType', 'double', 'ValueType', 'double');
    for i = 1:numel(ids)
        idMap(ids(i)) = i;
    end

    if ~isKey(idMap, bifurcation.apex_id)
        error('generate_smooth_bifurcation:MissingApex', ...
            'Apex ID %d not found in ids.', bifurcation.apex_id);
    end

    % --- Two independent single-tube vessel models through the shared inlet
    vessel1_ids = [bifurcation.id_p; bifurcation.id_d1];
    vessel2_ids = [bifurcation.id_p; bifurcation.id_d2];

    smoothed1 = runPenalizedSpline( ...
        [getSegment(vessel1_ids, idMap, coords), getSegment(vessel1_ids, idMap, radii)]);
    smoothed2 = runPenalizedSpline( ...
        [getSegment(vessel2_ids, idMap, coords), getSegment(vessel2_ids, idMap, radii)]);

    vessel1 = buildArclengthModel(smoothed1(:,1:3), smoothed1(:,4));
    vessel2 = buildArclengthModel(smoothed2(:,1:3), smoothed2(:,4));

    % --- Estimate the five cross-sections from where the two vessels part
    [C0, AC1, AC2, C1, C2, AP] = estimateBifurcationParameters(vessel1, vessel2, nSearch);

    % --- Centreline splines (tangent = normal, radius linear by arclength)
    spl1 = buildCenterlineSpline(C0, AC1, C1, nSeg);
    spl2 = buildCenterlineSpline(C0, AC2, C2, nSeg);

    % --- Sweep tube surfaces around each centreline ---------------------
    [X1, Y1, Z1] = sweepTube(spl1, nTheta);
    [X2, Y2, Z2] = sweepTube(spl2, nTheta);

    model = struct( ...
        'C0', C0, 'AC1', AC1, 'AC2', AC2, 'C1', C1, 'C2', C2, ...
        'spl1', spl1, 'spl2', spl2, ...
        'AP', AP, 'apex_id', bifurcation.apex_id, ...
        'tube1', struct('X', X1, 'Y', Y1, 'Z', Z1), ...
        'tube2', struct('X', X2, 'Y', Y2, 'Z', Z2));

    % --- Combine both tubes into one triangulation and export STL -------
    X1c = [X1, X1(:,1)]; Y1c = [Y1, Y1(:,1)]; Z1c = [Z1, Z1(:,1)];
    X2c = [X2, X2(:,1)]; Y2c = [Y2, Y2(:,1)]; Z2c = [Z2, Z2(:,1)];

    p1 = surf2patch(X1c, Y1c, Z1c, 'triangles');
    p2 = surf2patch(X2c, Y2c, Z2c, 'triangles');

    V = [p1.vertices; p2.vertices];
    F = [p1.faces; p2.faces + size(p1.vertices, 1)];
    TR = triangulation(F, V);

    outDir = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'stl_models');
    if ~exist(outDir, 'dir'), mkdir(outDir); end

    stlPath = fullfile(outDir, outputFilename);
    stlwrite(TR, stlPath);
    fprintf('STL saved to %s\n', stlPath);

    if plotFlag
        [~, base, ~] = fileparts(outputFilename);
        pCoords  = getSegment(bifurcation.id_p,  idMap, coords);
        d1Coords = getSegment(bifurcation.id_d1, idMap, coords);
        d2Coords = getSegment(bifurcation.id_d2, idMap, coords);
        plotModel(model, X1c, Y1c, Z1c, X2c, Y2c, Z2c, pCoords, d1Coords, d2Coords, [base, '_model.png']);
    end
end


% -------------------------------------------------------------------------
function vals = getSegment(segIds, idMap, data)
    % Extract rows of data (coords or radii) for the given node ids.
    idx = zeros(numel(segIds), 1);
    for k = 1:numel(segIds)
        if ~isKey(idMap, segIds(k))
            error('generate_smooth_bifurcation:MissingNode', ...
                'Node ID %d not found in ids.', segIds(k));
        end
        idx(k) = idMap(segIds(k));
    end
    vals = data(idx, :);
end


% -------------------------------------------------------------------------
function vessel = buildArclengthModel(P, R)
    % Wrap a smoothed centreline (P) and radius profile (R) with finite-
    % difference tangents and a cumulative-arclength parametrisation, so
    % the vessel can be evaluated by physical distance from its inlet.
    vessel.points    = P;
    vessel.radii     = R;
    vessel.tangents  = computeTangents(P);
    vessel.s         = arclength(P);
end


% -------------------------------------------------------------------------
function [pos, rad, tang] = evalVessel(vessel, s)
    % Interpolate position, radius and unit tangent at arclength s
    % (clamped to the vessel's available range).
    sClamped = min(max(s, 0), vessel.s(end));
    pos  = interp1(vessel.s, vessel.points,   sClamped);
    rad  = interp1(vessel.s, vessel.radii,    sClamped);
    tang = unitVector(interp1(vessel.s, vessel.tangents, sClamped));
end


% -------------------------------------------------------------------------
function [C0, AC1, AC2, C1, C2, AP] = estimateBifurcationParameters(vessel1, vessel2, nSearch)
    % Locate the apex by searching ALL pairs of cross-sections between the
    % two vessels, not just matched-arclength pairs: the branches can
    % diverge at different rates, so the point where they truly part need
    % not sit at equal arclength on each side. Each vessel's own apex
    % arclength is defined independently as the most distal point (closest
    % to its own outlet) whose disk still intersects the OTHER vessel's
    % tube somewhere along its full length (Decroocq et al., Sec 4.2.2).
    %
    % The search walks inward from each daughter's outlet towards the
    % shared parent, not outward from the inlet: right after the shared
    % segment the two tangents are still nearly parallel, which is exactly
    % where the disk-disk test is least reliable, and scanning from the
    % inlet can latch onto a spurious early separation there. Near the
    % outlets the branches are unambiguously apart, so scanning inward and
    % stopping at the first genuine overlap finds the true divergence
    % point instead.
    s1Grid = linspace(0, vessel1.s(end), nSearch)';
    s2Grid = linspace(0, vessel2.s(end), nSearch)';

    [P1, R1, T1] = sampleVessel(vessel1, s1Grid);
    [P2, R2, T2] = sampleVessel(vessel2, s2Grid);

    overlap = false(nSearch, nSearch);
    for i = 1:nSearch
        for j = 1:nSearch
            overlap(i, j) = ringsIntersect(P1(i,:), R1(i), T1(i,:), P2(j,:), R2(j), T2(j,:));
        end
    end

    % Most distal sample on each vessel that still intersects the other
    % vessel SOMEWHERE; the next sample out is found genuinely separated
    % from everything on the other side.
    i1 = find(any(overlap, 2), 1, 'last');
    j1 = find(any(overlap, 1), 1, 'last');
    if isempty(i1) || i1 == nSearch || isempty(j1) || j1 == nSearch
        error('generate_smooth_bifurcation:NoApexFound', ...
            'Scanning inward from the outlets, the two branch cross-sections never separate (or never start overlapping); cannot locate the apex.');
    end

    s1Apex = bisectExists(vessel1, s1Grid(i1), s1Grid(i1 + 1), P2, R2, T2);
    s2Apex = bisectExists(vessel2, s2Grid(j1), s2Grid(j1 + 1), P1, R1, T1);

    [P1s, R1s, T1s] = evalVessel(vessel1, s1Apex);
    [P2s, R2s, T2s] = evalVessel(vessel2, s2Apex);
    [~, AP] = ringsIntersect(P1s, R1s, T1s, P2s, R2s, T2s);

    AC1.center = P1s; AC1.radius = R1s; AC1.normal = T1s;
    AC2.center = P2s; AC2.radius = R2s; AC2.normal = T2s;

    C0.center = vessel1.points(1, :);
    C0.radius = vessel1.radii(1);
    C0.normal = vessel1.tangents(1, :);

    [P1c, R1c, T1c] = evalVessel(vessel1, s1Apex + 2*AC1.radius);
    C1.center = P1c; C1.radius = R1c; C1.normal = T1c;

    [P2c, R2c, T2c] = evalVessel(vessel2, s2Apex + 2*AC2.radius);
    C2.center = P2c; C2.radius = R2c; C2.normal = T2c;
end


% -------------------------------------------------------------------------
function [P, R, T] = sampleVessel(vessel, sGrid)
    % Position, radius and unit tangent of a vessel at each arclength in
    % sGrid.
    P = interp1(vessel.s, vessel.points, sGrid);
    R = interp1(vessel.s, vessel.radii,  sGrid);
    T = interp1(vessel.s, vessel.tangents, sGrid);
    T = T ./ vecnorm(T, 2, 2);
end


% -------------------------------------------------------------------------
function sApex = bisectExists(vesselSelf, sLo, sHi, otherP, otherR, otherT)
    % Bisect the [exists-overlap, no-overlap] bracket on vesselSelf's own
    % arclength, where "exists overlap" means disk_self(s) intersects ANY
    % cross-section sampled along the OTHER vessel.
    for iter = 1:40
        sMid = 0.5 * (sLo + sHi);
        if existsOverlapAnywhere(vesselSelf, sMid, otherP, otherR, otherT)
            sLo = sMid;
        else
            sHi = sMid;
        end
    end
    sApex = 0.5 * (sLo + sHi);
end


% -------------------------------------------------------------------------
function tf = existsOverlapAnywhere(vesselSelf, sSelf, otherP, otherR, otherT)
    % Whether disk_self(sSelf) intersects any of the sampled disks on the
    % other vessel.
    [pSelf, rSelf, tSelf] = evalVessel(vesselSelf, sSelf);
    tf = false;
    for k = 1:size(otherP, 1)
        if ringsIntersect(pSelf, rSelf, tSelf, otherP(k,:), otherR(k), otherT(k,:))
            tf = true;
            return;
        end
    end
end


% -------------------------------------------------------------------------
function [overlap, contactPoint] = ringsIntersect(P1, R1, T1, P2, R2, T2)
    % Exact intersection test between two finite circular disks in 3D,
    % each lying in the plane orthogonal to its own normal T1/T2 (the
    % cross-section tangent). Comparing centre distance to the sum of
    % radii (a sphere-sphere test) is only exact when T1 and T2 are
    % parallel; in general the two planes intersect along a line, and the
    % disks meet only where that line falls within both radii.
    n1 = unitVector(T1);
    n2 = unitVector(T2);
    dCross = cross(n1, n2);
    dn = norm(dCross);

    if dn < 1e-9
        % Parallel cross-sections: only coincide if also coplanar, in
        % which case the plain sphere-sphere test is exact.
        offset = dot(P2 - P1, n1);
        if abs(offset) > 1e-6 * max([R1, R2, 1])
            overlap = false;
            contactPoint = [NaN, NaN, NaN];
        else
            overlap = norm(P2 - P1) <= (R1 + R2);
            contactPoint = 0.5 * (P1 + P2);
        end
        return;
    end

    d = dCross / dn;

    % A point on the planes' line of intersection (minimum-norm solution
    % of n1.X = n1.P1, n2.X = n2.P2).
    A = [n1; n2];
    bvec = [dot(n1, P1); dot(n2, P2)];
    L0 = (pinv(A) * bvec)';

    [ok1, t1a, t1b] = diskInterval(L0, d, P1, R1);
    [ok2, t2a, t2b] = diskInterval(L0, d, P2, R2);
    if ~ok1 || ~ok2
        overlap = false;
        contactPoint = [NaN, NaN, NaN];
        return;
    end

    tLo = max(t1a, t2a);
    tHi = min(t1b, t2b);
    overlap = tLo <= tHi;
    contactPoint = L0 + 0.5 * (tLo + tHi) * d;
end


% -------------------------------------------------------------------------
function [ok, ta, tb] = diskInterval(L0, d, P, R)
    % Range of t (along line L0 + t*d) lying within distance R of P.
    w = L0 - P;
    b = dot(w, d);
    c = dot(w, w) - R^2;
    disc = b^2 - c;
    if disc < 0
        ok = false; ta = NaN; tb = NaN;
        return;
    end
    ok = true;
    sq = sqrt(disc);
    ta = -b - sq;
    tb = -b + sq;
end


% -------------------------------------------------------------------------
function spl = buildCenterlineSpline(C0, AC, Cout, nSeg)
    % Two cubic-Hermite segments (C0->AC, AC->Cout) whose end tangents
    % match the cross-section normals. Radius is linear by arclength
    % within each segment.
    ptsA = hermiteSample(C0.center, C0.normal, AC.center, AC.normal, nSeg);
    ptsB = hermiteSample(AC.center, AC.normal, Cout.center, Cout.normal, nSeg);

    dA = arclength(ptsA);
    dB = arclength(ptsB);
    radA = C0.radius + (dA / max(dA(end), eps)) * (AC.radius - C0.radius);
    radB = AC.radius  + (dB / max(dB(end), eps)) * (Cout.radius - AC.radius);

    spl.points = [ptsA; ptsB(2:end, :)];
    spl.radii  = [radA; radB(2:end)];
end


% -------------------------------------------------------------------------
function pts = hermiteSample(P0, T0, P1, T1, n)
    % Cubic Hermite curve from P0 to P1 with prescribed unit tangents T0,
    % T1 (scaled by chord length), sampled at n points.
    t = linspace(0, 1, n)';
    L = norm(P1 - P0);
    m0 = T0 * L;
    m1 = T1 * L;

    h00 =  2*t.^3 - 3*t.^2 + 1;
    h10 =      t.^3 - 2*t.^2 + t;
    h01 = -2*t.^3 + 3*t.^2;
    h11 =      t.^3 -   t.^2;

    pts = h00*P0 + h10*m0 + h01*P1 + h11*m1;
end


% -------------------------------------------------------------------------
function d = arclength(pts)
    seglen = sqrt(sum(diff(pts, 1, 1).^2, 2));
    d = [0; cumsum(seglen)];
end


% -------------------------------------------------------------------------
function u = unitVector(v)
    n = norm(v);
    if n < eps
        u = [0, 0, 1];
    else
        u = v / n;
    end
end


% -------------------------------------------------------------------------
function [X, Y, Z] = sweepTube(spl, nTheta)
    % Sweep a circular cross-section of varying radius along the
    % centreline, oriented with a rotation-minimizing frame to avoid
    % twisting artefacts.
    P = spl.points;
    R = spl.radii;
    nPts = size(P, 1);

    theta = linspace(0, 2*pi, nTheta + 1); theta(end) = [];
    cos_t = cos(theta(:));
    sin_t = sin(theta(:));

    T = computeTangents(P);
    N = computeRMF(P, T);
    Bn = cross(T, N, 2);

    X = zeros(nPts, nTheta);
    Y = zeros(nPts, nTheta);
    Z = zeros(nPts, nTheta);
    for i = 1:nPts
        pts = P(i,:) + R(i) * (cos_t * N(i,:) + sin_t * Bn(i,:));
        X(i,:) = pts(:,1)';
        Y(i,:) = pts(:,2)';
        Z(i,:) = pts(:,3)';
    end
end


% -------------------------------------------------------------------------
function T = computeTangents(P)
    % Finite-difference unit tangents along the centreline.
    n = size(P, 1);
    T = zeros(n, 3);
    T(1,:) = P(2,:) - P(1,:);
    T(n,:) = P(n,:) - P(n-1,:);
    if n > 2
        T(2:n-1,:) = (P(3:n,:) - P(1:n-2,:)) / 2;
    end
    T = T ./ vecnorm(T, 2, 2);
end


% -------------------------------------------------------------------------
function N = computeRMF(P, T)
    % Rotation-minimizing frame via the double reflection method
    % (Wang et al., 2008), avoids the flips a Frenet frame produces
    % when the tangent crosses a fixed reference axis.
    n = size(P, 1);
    N = zeros(n, 3);

    ref = [0, 0, 1];
    if abs(dot(T(1,:), ref)) > 0.9
        ref = [0, 1, 0];
    end
    N(1,:) = unitVector(cross(T(1,:), ref));

    for i = 1:n-1
        v1 = P(i+1,:) - P(i,:);
        c1 = dot(v1, v1);
        if c1 < eps
            N(i+1,:) = N(i,:);
            continue;
        end
        rL = N(i,:) - (2/c1) * dot(v1, N(i,:)) * v1;
        tL = T(i,:) - (2/c1) * dot(v1, T(i,:)) * v1;

        v2 = T(i+1,:) - tL;
        c2 = dot(v2, v2);
        if c2 < eps
            N(i+1,:) = rL;
        else
            N(i+1,:) = rL - (2/c2) * dot(v2, rL) * v2;
        end
        N(i+1,:) = unitVector(N(i+1,:));
    end
end


% -------------------------------------------------------------------------
function ring = circleRing(center, radius, normal, nTheta)
    % Points around a circle of given radius/normal, closed (first point
    % repeated at the end) for plotting.
    normal = unitVector(normal);
    ref = [0, 0, 1];
    if abs(dot(normal, ref)) > 0.9
        ref = [0, 1, 0];
    end
    u = unitVector(cross(normal, ref));
    v = cross(normal, u);

    theta = linspace(0, 2*pi, nTheta + 1)';
    ring = center + radius * (cos(theta) * u + sin(theta) * v);
end


% -------------------------------------------------------------------------
function plotModel(model, X1, Y1, Z1, X2, Y2, Z2, pCoords, d1Coords, d2Coords, figFilename)
    % Plot the swept tube surfaces, the two centreline splines, the raw
    % id_p/id_d1/id_d2 SWC nodes that fed the smoothing, and the five
    % cross-sections (as rings with their normals).
    fig = figure('Color', 'w', 'Name', 'Smooth bifurcation model (Decroocq et al.)');
    hold on; grid on; axis equal; view(3);
    xlabel('X'); ylabel('Y'); zlabel('Z');
    title('Smooth bifurcation model: 5 cross-sections + centreline splines');

    surf(X1, Y1, Z1, 'EdgeColor', 'none', 'FaceAlpha', 0.25, 'FaceColor', [0, 0.8, 0.8], ...
        'HandleVisibility', 'off');
    surf(X2, Y2, Z2, 'EdgeColor', 'none', 'FaceAlpha', 0.25, 'FaceColor', [1, 0.5, 0], ...
        'HandleVisibility', 'off');

    plot3(model.spl1.points(:,1), model.spl1.points(:,2), model.spl1.points(:,3), '-', ...
        'Color', [0, 0.6, 0.6], 'LineWidth', 2, 'DisplayName', 'spl_1 (centreline, daughter 1)');
    plot3(model.spl2.points(:,1), model.spl2.points(:,2), model.spl2.points(:,3), '-', ...
        'Color', [0.8, 0.4, 0], 'LineWidth', 2, 'DisplayName', 'spl_2 (centreline, daughter 2)');

    plot3(pCoords(:,1), pCoords(:,2), pCoords(:,3), 'o', 'Color', [0.5, 0, 0.5], ...
        'MarkerFaceColor', [0.85, 0.6, 0.85], 'MarkerSize', 8, 'LineWidth', 1.2, ...
        'DisplayName', 'id_p (parent nodes)');
    plot3(d1Coords(:,1), d1Coords(:,2), d1Coords(:,3), 's', 'Color', [0, 0.5, 0.5], ...
        'MarkerFaceColor', [0.6, 0.9, 0.9], 'MarkerSize', 8, 'LineWidth', 1.2, ...
        'DisplayName', 'id_d1 (daughter 1 nodes)');
    plot3(d2Coords(:,1), d2Coords(:,2), d2Coords(:,3), '^', 'Color', [0.6, 0.3, 0], ...
        'MarkerFaceColor', [1, 0.7, 0.4], 'MarkerSize', 8, 'LineWidth', 1.2, ...
        'DisplayName', 'id_d2 (daughter 2 nodes)');

    plot3(model.AP(1), model.AP(2), model.AP(3), 'o', 'Color', 'k', ...
        'MarkerFaceColor', 'r', 'MarkerSize', 8, 'DisplayName', 'AP (apex)');

    sections = {model.C0, model.AC1, model.AC2, model.C1, model.C2};
    names    = {'C0', 'AC1', 'AC2', 'C1', 'C2'};
    colors   = [0.7, 0, 0.7; 0, 0.8, 0.8; 1, 0.5, 0; 0, 0.4, 0.4; 0.6, 0.3, 0];

    for k = 1:numel(sections)
        s = sections{k};
        ring = circleRing(s.center, s.radius, s.normal, 60);
        plot3(ring(:,1), ring(:,2), ring(:,3), '-', 'Color', colors(k,:), 'LineWidth', 2, ...
            'DisplayName', sprintf('%s (r=%.3f)', names{k}, s.radius));
        arrowLen = 2 * s.radius;
        quiver3(s.center(1), s.center(2), s.center(3), ...
            s.normal(1)*arrowLen, s.normal(2)*arrowLen, s.normal(3)*arrowLen, 0, ...
            'Color', colors(k,:), 'LineWidth', 1.5, 'MaxHeadSize', 1, 'HandleVisibility', 'off');
        text(s.center(1), s.center(2), s.center(3), ['  ', names{k}], ...
            'Color', colors(k,:), 'FontWeight', 'bold');
    end

    legend('Location', 'bestoutside');
    camlight headlight; lighting gouraud;

    outDir = fullfile(fileparts(mfilename('fullpath')), '..', 'results', 'visualization');
    if ~exist(outDir, 'dir'), mkdir(outDir); end
    saveas(fig, fullfile(outDir, figFilename));
end
