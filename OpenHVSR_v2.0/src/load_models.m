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