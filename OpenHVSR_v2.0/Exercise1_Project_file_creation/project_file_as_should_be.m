% This is a project-file to input the program
% OpenHVSR-2D, v2.0

% Determined how H/V files are read
% datafile_columns:   describes the columnwise structure of the data
%     [FREQUENCY column Id][HVSR Curve column Id][standard dev. Id]
% datafile_separator: in H/V curve files, is a string separator between HEADER and DATA
datafile_separator = 'none';
datafile_columns   = [1 2 3];



% Collection of H/V curves to invert
SURVEYS{1,1} = [0,0,0];
SURVEYS{1,2} = 'c01_sinthetic.txt';
SURVEYS{2,1} = [40,0,0];
SURVEYS{2,2} = 'c02_sinthetic.txt';


% Starting subsurface description
MODELS{1,1} = 'c01_subsurface.txt';
MODELS{1,2} =1;
MODELS{2,1} = 'c02_subsurface.txt';
MODELS{2,2} =2;


% Describe if some reference model is present
% reference_model_file1   is defined following the same format of the input subsurface models
%                         i.e. depth is specified using layers thickness
% reference_model_file2:  is the depth is a true depth
reference_model_file1 = '';
reference_model_file2 = '';
