% Lateral constrained montecarlo inversion of HVSR data
%
%%%-----------------------------
%%
%% Lateral constrained montecarlo inversion of HVSR data
%%
%%
%% AUTHORS:
%%
%%    Ph.D. Samuel  Bignardi
%%           University Of Ferrara (Italy)
%%           - User Interface
%%           - Montecarlo inversion
%%
%%   TESTED MATLAB CONFIGURATIONS: (started tracking on August 2, 2023)
%    OpenHVSR  ---  MATLAB
%    4.0.2     ---  R2022b 64-bit (glnxa64)
%%
%% 
%% Project Evolution
%% Date: 
%%       Matlab R2010a
%%       September 20 2014            Forward model put 
%%                                    into a callable function 
%%       June      12, 2015            Interface completed      
%%       June      24, 2015            First 'beta' version completed  
%%       August    15, 2015            Extended to 3D
%%       August    28, 2015            Bugfix: Matlab Tab support (V0 parameter)
%%       December   5, 2017            Minor Bugfix: linspace. (not affecting functionality)
%%       September 27, 2018            Files with different frequency scales are now accepted
%%       October    2, 2018            smooth.m (curve fittin toolbox) included as SAM_smooth.m
%%       November 18, 2018             modifies curve and slope terms management in the energy function 
%                                              NEW move-over suggestionss
%                                              NEW test-function in model_manager for surface-waves
%%       April 4, 2019                 New version 4.0.0 (Beta)
%                                              NEW main tab showing the survey map
%                                              NEW multiple profiles definition
%                                              NEW terrain elevation in profiles
%%       August 10, 2020               2D profile revision
%%       September 10, 2020            Improved the View Menu. 
%                                              Solved a minor issue with color_axis variable. 
%                                              Improved image production
%                                              Changed behavior of "Refresh" button
%%       January 27,2021           fixed backword compatibility R2016b: (gimput) 
%%       August 02, 2023           TESTED AND WORKING ON MATLAB 2022b
%                                              - name change: sam_ginput.m >> SAM_2018b_ginput.m
%                                              - name change: sam_smooth.m >> SAM_2018a_smooth.m
%                                              - name change: as_Samuel.m  >> BodyWavesForwardModel.p
%                                              - implemented memory preallocation in
%                                                BodyWavesForwardModel, for efficiency
%                                              - created SAM_2022b_griddata3.m from griddata3.m 
%%
%%
%%
%%       Notes: 
%%             1) all imput text files are assuming to use UTF-8 encoding
%%             2) Use the command "codeCompatibilityReport" to solve Matlab version compatibility issues
%%

%%%-----------------------------
%feature('DefaultCharacterSet')
feature('DefaultCharacterSet', 'UTF8')
close all
clear
clc
%%  -----------------------------------------------------------------------
enable_menu = 0;
%%  -----------------------------------------------------------------------
mode = '3D'; %%    3D is enable by default.
% mode = '2D';%%   uncomment this line to stat in 2D mode (better for 2-D profiles)  
%%  -----------------------------------------------------------------------
%% some settings
fontsizeis = 15;
%%  -----------------------------------------------------------------------
%%
%%
%%
%% check working folder was properly set
current_folder = pwd;
ffullpath = mfilename('fullpath');
if ~strcmp(ffullpath( (end-1):end) , '.m')
    ffullpath = ffullpath(1: (end-15));
else
    ffullpath = ffullpath(1: (end-17));
end
if ~strcmp(current_folder , ffullpath)
    cd(ffullpath) 
    fprintf('MESSAGE:: I Forced Working folder to: %s\n',ffullpath)
end
%%
if strcmp(mode,'2D')
    gui_2D_210127(enable_menu,fontsizeis);% routine for 2D geometry
end
if strcmp(mode,'3D')
    % gui_3D_210127();% routine for 3D geometry
    gui_3D_230802();% routine for 3D geometry
end






