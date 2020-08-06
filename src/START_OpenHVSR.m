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
%%       November 18, 2018           modifies curve and slope terms management in the energy function 
%%                                              NEW move-over suggestionss
%%                                              NEW test-function in model_manager for surface-waves
%%       April 4, 2019           New version 4.0.0 (Beta)
%%                                              NEW main tab showing the survey map
%%                                              NEW multiple profiles definition
%%                                              NEW terrain elevation in profiles
%%       August 10, 2020          2D profile revision
%%       Note: all imput text files are assuming to use UTF-8 encoding
%%
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
mode = '2D';%%   only 2D (better for 2-D profiles)
mode = '3D';%%  
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
    gui_2D_190410(enable_menu,fontsizeis);% routine for 2D geometry
end
if strcmp(mode,'3D')
    gui_3D_200805();% routine for 3D geometry
end






