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
function MDLS =  load_models(working_folder,SURVEYS,MODELS)

%% Load Input FILES
% loads one input file. The file is defined by its id
%
%  Same parameters order as Herak
%  vp  vs  rho  h  Qp  Qs

% 1. imput field data
N = size(SURVEYS,1);
M = size(MODELS,1);

MDLS = cell(1,N);


fprintf('[Loading Inital Models]\n');
for m = 1:M% span on available subsurface models 
    
    FileName = MODELS{m,1};%% get filename for INITIAL MODEl
    array = load(strcat(working_folder, FileName),'-ascii');
    array = array(:,1:6);
    
    fprintf('Model[%d] %s.\n',m,FileName);
    
    for s = MODELS{m,2}
        fprintf('   associated to data[%d].\n',s);
        MDLS{s} = array;
    end

   
end
fprintf('[Loading Done]\n');

end%function