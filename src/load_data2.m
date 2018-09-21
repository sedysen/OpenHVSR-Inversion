function FDAT = load_data2(working_folder,SURVEYS, datafile_columns,datafile_separator)

%% Load Input FILES
N      = size(SURVEYS,1);
FDAT   = cell(N, 3);% [frequences, HVSR-curve]

fprintf('[Loading Field Data]\n');
if(strcmp(datafile_separator,'none'))
    fprintf('    No header/data separator selected \n'); 
else
    fprintf('    Header/data separator: %s\n',datafile_separator);
end
fprintf('    Freq. expected in column [%d]\n',datafile_columns(1)); 
fprintf('    HVSR. expected in column [%d]\n',datafile_columns(2));
fprintf('\n');

for id = 1:N 
    FileNameData = SURVEYS{id,2};%                                         get filename for field data
    FileNamePath = strcat(working_folder, FileNameData);%                  complete path
    
    %% data separator is not set
    if(strcmp(datafile_separator,'none'))
        fprintf('id[%d] %s.\n',id,FileNameData);
        DATA = load(strcat(working_folder, FileNameData),'-ascii')
    end
    %% data separator is set
    if(~strcmp(datafile_separator,'none'))    
        EOHind = 0;
        
        fid=fopen(FileNamePath,'r');
        % B = textscan(fid, '%s', 'delimiter', '\n', 'whitespace', '');%% B contains all the contents of the opened file.
        B = textscan(fid, '%s', 'delimiter', '\n');%% B contains all the contents of the opened file.
        fclose(fid);
        clear fid

        %% HEADER.
        fprintf('id[%d] %s.\n',id,FileNameData);
        fprintf('      Header Evaluation:');
        B=B{1,1};
        %     SAMP_FREQ=char(B(2,1));                       %%Original sampling frequence
        %     SAMP_FREQ=SAMP_FREQ(1,13:size(SAMP_FREQ,2));
        %     SAMP_FREQ=str2num(SAMP_FREQ);
        %     NDAT=char(B(3,1));
        %     NDAT=NDAT(1,8:size(NDAT,2));
        %     NDAT=str2num(NDAT);
        for i = 1:size(B,1)
            % Finding a corrispondence in header
            % HD = separation between header and data
            %fprintf('line[%d]  %s\n',i,B{i,1})
            Ref_SHD = strcmp(B{i,1},datafile_separator);
            if Ref_SHD==1
                EOHind=i;  %%index of header end in matrix of cells "b".
            end
        end
        fprintf('  ...Done.\n');

        if(EOHind ~= 0)
            %% DATA.
            % write data on a File and read again
            fprintf('      Data Evaluation:')
            format long g
            DATA = char(B(EOHind+1:size(B,1)));
            DATA = DATA';
            fid=fopen('DATA.mat','w');
            for i=1:size(DATA,2)
                fprintf(fid, '%s\n', DATA(:,i));
            end
            fclose(fid);
            clear fid DATA count2 %B
            DATA = load('DATA.mat','-ascii'); %test <<<
            fprintf('  ...Done.\n');   
        else
            msg =[ 'Data evaluation is not possible!  '; ...
                   'The header/data separator was not '; ...
                   'found.                            '; ...
                   'Consider to modify the file/header'; ...
                   'separator or to set it to "none"  '; ...
                   'to load just-numerical data files '; ...
                   ];

            msgbox(msg,'Error')
        end
    end% read file mode
    
    %% READ DATA PART 
    if isempty(DATA)
        error('Unable to read the data. This is probably due to an ascii unexpected encoding format. Please Contact Samuel Bignardi: sedysen@gmail.com')
    end
    ff_scale = DATA(:, datafile_columns(1) );
    hv_curve = DATA(:, datafile_columns(2) );
    
    
    FDAT{id,1} = ff_scale;
    FDAT{id,2} = hv_curve; 
    
    if(size(DATA,2) >= 3)
        stdev = DATA(:, datafile_columns(3) );
        FDAT{id,3} = stdev;
    end
    
    %message = strcat('Select input file #',ii);
    %[FileName,PathName,FilterIndex] = uigetfile(input_filename_extension,message);

    %1. imput field data:  load tt_ee_sant1.txt -ascii;
    %INfiles{1,ii} = PathName;
    %INfiles{2,ii} = FileName;
    
%     FileName = SURVEYS{id,2};%% get filename for field data
%     array = load(strcat(working_folder, FileName),'-ascii');
% 
%     ff_scale = array(:,1);
%     hv_curve = array(:,2);
%     
%     FDAT{id,1} = ff_scale;
%     FDAT{id,2} = hv_curve;
% 
%     fprintf('id[%d] %s.\n',id,FileName);
end
fprintf('[Loading Done]\n');

end%function