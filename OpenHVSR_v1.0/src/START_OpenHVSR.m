% Copyright 2015 by Samuel Bignardi.
% 
% This file is part of the program OpenHVSR.
% 
% OpenHVSR is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
% 
% OpenHVSR is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
% 
% You should have received a copy of the GNU General Public License
% along with OpenHVSR.  If not, see <http://www.gnu.org/licenses/>.
%
%
%
%
%% -----------------------------
%
% Lateral constrained montecarlo inversion of HVSR data
%
% Project Evolution:
% Original development environment: Matlab R2010a
%
%       September 20 2014            Forward model put 
%                                    into a callable function 
%       June      12 2015            Interface completed      
%       June      24 2015            First completed version 
%       August    15 2015            Extended to 3D
%       December  01 2015            Code revision. version 1.0
% 
%% -----------------------------
clear global
clear all
close all
clc
enable_menu = 0;

mode = '2D';%%   only 2D (better for 2-D profiles)
%mode = '3D';%%  

if strcmp(mode,'2D')
    gui_2D(enable_menu);
end
if strcmp(mode,'3D')
    gui_3D(enable_menu);
end








