function inflate_swc_radius_test()
    % Arrange: a tiny SWC file with a comment line, a blank line, and two
    % data rows with known radii.
    tmpDir = tempname;
    mkdir(tmpDir);
    inPath = fullfile(tmpDir, 'test.swc');

    fid = fopen(inPath, 'w');
    fprintf(fid, '# comment line\n');
    fprintf(fid, '\n');
    fprintf(fid, '1 1 0.0 0.0 0.0 1.0 -1\n');
    fprintf(fid, '2 3 1.0 0.0 0.0 2.0 1\n');
    fclose(fid);

    % Act + Assert: ratio mode scales radius by (1 + thickness)
    outRatioPath = fullfile(tmpDir, 'test_ratio.swc');
    inflate_swc_radius(inPath, outRatioPath, 0.1, 'ratio');
    ratioData = read_swc(outRatioPath);
    tol = 1e-6;
    assert(abs(ratioData(1,6) - 1.1) < tol, 'Ratio mode: row 1 radius not inflated correctly.');
    assert(abs(ratioData(2,6) - 2.2) < tol, 'Ratio mode: row 2 radius not inflated correctly.');
    assert(isequal(ratioData(:, [1,2,3,4,5,7]), [1 1 0 0 0 -1; 2 3 1 0 0 1]), ...
        'Ratio mode: non-radius columns were changed.');

    % Act + Assert: absolute mode adds thickness directly
    outAbsPath = fullfile(tmpDir, 'test_abs.swc');
    inflate_swc_radius(inPath, outAbsPath, 0.5, 'absolute');
    absData = read_swc(outAbsPath);
    assert(abs(absData(1,6) - 1.5) < tol, 'Absolute mode: row 1 radius not inflated correctly.');
    assert(abs(absData(2,6) - 2.5) < tol, 'Absolute mode: row 2 radius not inflated correctly.');

    % Assert: comments and blank lines are preserved verbatim
    outText = fileread(outRatioPath);
    assert(contains(outText, '# comment line'), 'Comment line was not preserved.');

    % Assert: default arguments behave like 10% ratio inflation
    outDefaultPath = fullfile(tmpDir, 'test_default.swc');
    inflate_swc_radius(inPath, outDefaultPath);
    defaultData = read_swc(outDefaultPath);
    assert(abs(defaultData(1,6) - 1.1) < tol, 'Default arguments did not behave like 10% ratio inflation.');

    % Assert: an invalid mode raises a clear error
    try
        inflate_swc_radius(inPath, fullfile(tmpDir, 'bad.swc'), 0.1, 'bogus');
        error('inflate_swc_radius_test:NoError', 'Expected an error for invalid mode, but none was thrown.');
    catch err
        assert(strcmp(err.identifier, 'inflate_swc_radius:InvalidMode'), ...
            'Unexpected error identifier for invalid mode.');
    end

    delete(inPath);
    delete(outRatioPath);
    delete(outAbsPath);
    delete(outDefaultPath);
    rmdir(tmpDir);

    disp('PASS: inflate_swc_radius_test inflated radii correctly in both modes.');
end
