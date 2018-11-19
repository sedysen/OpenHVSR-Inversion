% Example of a project file.
% It requires some basic knowledge of Matlab
%
%
datafile_separator = 'header_data_separation';% this is the header/data separator in data files.
% it can be setted in the interface and is not necessary here.
%
%
%% LIST OF MODELS TO LOAd
id = 0; 
id=id+1; SURVEYS{id,1} = [4965 0 0]; SURVEYS{id,2} = 'DATA/sito_06.asc';

id=id+1; SURVEYS{id,1} = [5968 0 0]; SURVEYS{id,2} = 'DATA/sito_07.asc';

id=id+1; SURVEYS{id,1} = [6927 0 0]; SURVEYS{id,2} = 'DATA/sito_08.asc';

id=id+1; SURVEYS{id,1} = [8096 0 0]; SURVEYS{id,2} = 'DATA/sito_09.asc';
  
id=id+1; SURVEYS{id,1} = [8953 0 0]; SURVEYS{id,2} = 'DATA/sito_10.asc';
 
id=id+1; SURVEYS{id,1} = [9863 0 0]; SURVEYS{id,2} = 'DATA/sito_11.asc';

id=id+1; SURVEYS{id,1} = [10815 0 0]; SURVEYS{id,2} = 'DATA/sito_12-2.asc';

id=id+1; SURVEYS{id,1} = [12214 0 0]; SURVEYS{id,2} = 'DATA/sito_13.asc';


%% SUBSURFACE STARTING MODELS ( Lateral Constrain Groups )
%  Different sets of measurements can be separately laterally constrained. 
%  for example say we have 5 measurements (1 2 3 4 5)
%  and say that the presence of a strong lateral discontinuity is known
%  between surveys 3 and 4. 
%  We can give two separate starting models for the two set of measurements.
%  for example 
%  {1 2 3} and {4 5}
%  so, surveys are divided into two groups
%  MODELS{1, 1} = 'path/to/the/model_A.mdl'   
%  MODELS{1, 2} = [1,2,3]%  id=id+1; SURVEY associated to the model_A.mdl
%
%  MODELS{2, 1} = 'path/to/the/model_B.mdl' 
%  MODELS{2, 2} = [4, 5]%  id=id+1; SURVEY associated to the model_A.mdl
% 
%  NOTE: We need a starting model for each group.
%  Same parameters order as Herak
%  vp  vs  rho  h  Qp  Qs
%
id = 0; 
id=id+1; MODELS{id,1} = 'MODEL/sito_06_subsurface.txt'; MODELS{id,2} = id;          
 
id=id+1; MODELS{id,1} = 'MODEL/sito_07_subsurface.txt'; MODELS{id,2} = id;          

id=id+1; MODELS{id,1} = 'MODEL/sito_08_subsurface.txt'; MODELS{id,2} = id;          

id=id+1; MODELS{id,1} = 'MODEL/sito_09_subsurface.txt'; MODELS{id,2} = id; 

id=id+1; MODELS{id,1} = 'MODEL/sito_10_subsurface.txt'; MODELS{id,2} = id;   

id=id+1; MODELS{id,1} = 'MODEL/sito_11_subsurface.txt'; MODELS{id,2} = id;       

id=id+1; MODELS{id,1} = 'MODEL/sito_12_subsurface.txt'; MODELS{id,2} = id;   

id=id+1; MODELS{id,1} = 'MODEL/sito_13_subsurface.txt'; MODELS{id,2} = id;   







