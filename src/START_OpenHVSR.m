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
%%       June      12 2015            Interface completed      
%%       June      24 2015            First 'beta' version completed  
%%       August    15 2015            Extended to 3D
%%       August    28 2015            Bugfix: Matlab Tab support (V0 parameter)
%%       December   5 2017            Minor Bugfix: linspace. (not affecting functionality)
%% 
%%
%%       Note: all imput text files are assuming to use UTF-8 encoding
%%
%%

%%%-----------------------------
%feature('DefaultCharacterSet')
feature('DefaultCharacterSet', 'UTF8')

clear global
clear all
close all
clc
%%  -----------------------------------------------------------------------
% During the past, Matworks changed the function managing the creation of
% "Tabs" in the gui. To solve potential errors, the user is encouraged to
% chose the best working one of the following configurations. 
% Matlab_Release = '2010a';
% Matlab_Release = '2015b';
Matlab_Release = '2016b';
%%  -----------------------------------------------------------------------
enable_menu = 0;
%%  -----------------------------------------------------------------------
mode = '2D';%%   only 2D (better for 2-D profiles)
%mode = '3D';%%  
%%  -----------------------------------------------------------------------
%% some settings
fontsizeis = 15;
%%  -----------------------------------------------------------------------
%%
%%
%%
if strcmp(mode,'2D')
    gui_2D(Matlab_Release,enable_menu,fontsizeis);% routine for 2D geometry
end
if strcmp(mode,'3D')
    gui_3D(Matlab_Release,enable_menu,fontsizeis);% routine for 3D geometry
end

% mcc -m hello.m -a ./src
% START_OpenHVSR.m
% -o outfile
% -d ./bin/
% -I ./src/
% mcc -o OpenHVSR_2D__win64 -m FourierSpectrum.m, START_OpenHVSR.m, SparseDtata_XYZD_to_3D.m, as_Samuel.m, call_Albarello_2011.m, function_Add_HV_SW.m, griddata3.m, gui_2D.m, gui_3D.m, load_data2.m, load_models.m, moving_average.m, nanmoving_average.m, nanmoving_average2.m, openhvsr_project_creator.m, points_to_surface_grid.m, prfsmoothing.m, publish_gui.p, setup_manager.m, smoothvolume3.m
% mcc -o OpenHVSR_2D__win64 -m START_OpenHVSR.m gui_2D.m gui_3D.m SparseDtata_XYZD_to_3D.m FourierSpectrum.m as_Samuel.m call_Albarello_2011.m function_Add_HV_SW.m griddata3.m load_data2.m load_models.m moving_average.m nanmoving_average.m nanmoving_average2.m openhvsr_project_creator.m points_to_surface_grid.m prfsmoothing.m publish_gui.p setup_manager.m smoothvolume3.m









