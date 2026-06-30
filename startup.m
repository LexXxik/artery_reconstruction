% startup.m - Automatically configures the MATLAB path for this project

% Get the absolute path to the root of the project (where this file lives)
projectRoot = fileparts(mfilename('fullpath'));

% Add the specific folders you need MATLAB to search
addpath(fullfile(projectRoot, 'scripts'));
addpath(fullfile(projectRoot, 'tests'));
addpath(fullfile(projectRoot, 'src')); 
addpath(fullfile(projectRoot, 'src/visualization')); 
addpath(fullfile(projectRoot, 'src/data_processing')); 

disp('Project paths successfully added!');