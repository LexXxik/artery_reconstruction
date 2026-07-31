function batch_inflate_swc_test()
    % Arrange: two source SWC files plus a file that already carries the
    % "_outer" suffix, which batch_inflate_swc must skip rather than
    % re-inflate.
    tmpDir = tempname;
    mkdir(tmpDir);

    file1 = fullfile(tmpDir, 'bifurcation_1.swc');
    fid = fopen(file1, 'w');
    fprintf(fid, '1 1 0.0 0.0 0.0 1.0 -1\n');
    fprintf(fid, '2 3 1.0 0.0 0.0 2.0 1\n');
    fclose(fid);

    file2 = fullfile(tmpDir, 'bifurcation_2.swc');
    fid = fopen(file2, 'w');
    fprintf(fid, '1 1 0.0 0.0 0.0 4.0 -1\n');
    fclose(fid);

    alreadyOuterFile = fullfile(tmpDir, 'bifurcation_3_outer.swc');
    fid = fopen(alreadyOuterFile, 'w');
    fprintf(fid, '1 1 0.0 0.0 0.0 9.0 -1\n');
    fclose(fid);

    % Act
    out_files = batch_inflate_swc(tmpDir, 0.1, 'ratio', '_outer');

    % Assert: exactly the two real source files were inflated
    assert(numel(out_files) == 2, 'Expected exactly two inflated sibling files.');

    outer1 = fullfile(tmpDir, 'bifurcation_1_outer.swc');
    outer2 = fullfile(tmpDir, 'bifurcation_2_outer.swc');
    assert(isfile(outer1), 'Expected outer sibling for bifurcation_1.swc was not created.');
    assert(isfile(outer2), 'Expected outer sibling for bifurcation_2.swc was not created.');
    assert(~isfile(fullfile(tmpDir, 'bifurcation_3_outer_outer.swc')), ...
        'Pre-existing outer file should have been skipped, not re-inflated.');

    tol = 1e-6;
    data1 = read_swc(outer1);
    assert(abs(data1(1,6) - 1.1) < tol, 'Row 1 radius in bifurcation_1_outer.swc was not inflated correctly.');
    assert(abs(data1(2,6) - 2.2) < tol, 'Row 2 radius in bifurcation_1_outer.swc was not inflated correctly.');

    data2 = read_swc(outer2);
    assert(abs(data2(1,6) - 4.4) < tol, 'Row radius in bifurcation_2_outer.swc was not inflated correctly.');

    delete(file1);
    delete(file2);
    delete(alreadyOuterFile);
    delete(outer1);
    delete(outer2);
    rmdir(tmpDir);

    disp('PASS: batch_inflate_swc_test generated inflated sibling files for every SWC in the folder.');
end
