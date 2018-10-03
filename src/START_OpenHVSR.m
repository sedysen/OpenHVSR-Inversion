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
%%       September 27 2018            Files with different frequency scales are now accepted
%%       October    2 2018            smooth.m (curve fittin toolbox) included as SAM_smooth.m
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
% Matlab_Release = '2016b';
Matlab_Release = '2018b';
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






