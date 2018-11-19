%% Copyright 2017 by Samuel Bignardi.
%     www.samuelbignardi.com
%
%
% This file is part of the program OpenHVSR-Processing Toolkit.
%
% OpenHVSR-Processing Toolkit is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% OpenHVSR-Processing Toolkit is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with OpenHVSR-Processing Toolkit.  If not, see <http://www.gnu.org/licenses/>.
%
%
%
function [Matlab_Release,Matlab_Release_num, hTabGroup,SelectionChangeOption] = Pfiles_Function_MATLAB_Release(gui_handle)
    %fprintf('Pfiles-call: Pfiles_Function_MATLAB_Release\n')

    %%     Matlab release switch
    Matlab_Release = version('-release');
    if Matlab_Release(end)=='a'; Matlab_Release_num = str2double(Matlab_Release(1:4)) + 0.1; end
    if Matlab_Release(end)=='b'; Matlab_Release_num = str2double(Matlab_Release(1:4)) + 0.2; end
    % Manage Matlab version-dependent features
    %     * hTabGroup:  tabs
    %     * P.SelectionChangeOption: buttongroup select option:
    %            (before 2014b): SelectionChangFcn
    %            (after  2014b): SelectionChangedFcn
    %%         issue: hTabGroup
    switch Matlab_Release_num
        %% cases for tested versions
        case 2010.1%'2010a'
            str = warning('off', 'MATLAB:uitabgroup:OldVersion');
            hTabGroup = uitabgroup('v0','Parent',gui_handle);
            warning(str);
        case 2012.2%'2012b'
            hTabGroup = uitabgroup('Parent',gui_handle);
        case 2014.2%'2014b'
            hTabGroup = uitabgroup('Parent',gui_handle);     
        case 2015.1%'2015a'
            hTabGroup = uitabgroup('Parent',gui_handle);
        case 2015.2%'2015b'
            hTabGroup = uitabgroup('Parent',gui_handle);
        case 2017.2%'2017b'
            hTabGroup = uitabgroup('Parent',gui_handle);    
        otherwise
            fprintf('=============================================\n')
            fprintf('                   MESSAGE                   \n')
            fprintf('Detected Matlab %s in use                    \n',Matlab_Release)
            fprintf('the code was not tested on this particular   \n')
            fprintf('matlab version.                              \n')
            fprintf('Setting for the "generic" Matlab release are \n')
            fprintf('in use. Should the code perform unespectedly \n')
            fprintf('please contact sedysen@gmail.com             \n')
            fprintf('=============================================\n')
            %% untested versions
            if Matlab_Release_num<2010.1% before 2010a
                str = warning('off', 'MATLAB:uitabgroup:OldVersion');
                hTabGroup = uitabgroup('v0','Parent',gui_handle);
                warning(str);
            end
            if Matlab_Release_num>2010.2% after 2010b
                hTabGroup = uitabgroup('Parent',gui_handle);
                %P.SelectionChangeOption = 'SelectionChangeFcn';
            end
    end
    %%         issue: bottongroup -> SelectionChangeFcn
    if Matlab_Release_num <= 2014.2
        SelectionChangeOption = 'SelectionChangeFcn';
    else
        SelectionChangeOption = 'SelectionChangedFcn';
    end
    %%         issue: triscatterdata/scatterinterpolant
    if Matlab_Release_num <= 2014.2
        fprintf('\n')
        fprintf('MATLAB VERSIONS EARLIER THAN R2014B DETECTED\n')
        fprintf('The code was developed in R2015B\n')
        fprintf('* some visualization function were introduced\n')
        fprintf('* in 2014B and are not present in this distribution.\n')
        fprintf('* Visualization functions will be of poor quality\n')
        fprintf('\n')
        fprintf('Program is paused, press any key to continue.\n')
        pause
        clc
    end
end% function






