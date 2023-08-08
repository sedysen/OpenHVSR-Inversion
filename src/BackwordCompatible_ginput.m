function [xx,yy] = BackwordCompatible_ginput(MRelease, N, haxis)
    %  The purpose of this fiunction is to implement backword compatibility
    %  for the native matlab function ginput, and to solve some
    %  Matlab-release specific issues.
    %   
    %
    % MRelease              Matlab_Release_num:   year.1 (release A)
    %                                             year.2 (release B)
    % N:                    n of points to gather
    % haxis                 handle to a specific axis
    %% 2016A
    if (MRelease == 2016.1)
        axes(hAx_main_geo)
        [xx,yy] = ginput(N);
        return
    end
    %% 2016B --not fully tested yet--   
    if (MRelease == 2016.2)
        axes(hAx_main_geo)
        [xx,yy] = ginput(N);
        return
    end
    %% 2017A - 2018B
    if (2017.1 <= MRelease) && (MRelease <= 2018.2)
        % Solve the 2017 issue by using the 2018B ginput version
        [xx,yy] = SAM_2018b_ginput(N, haxis);
        return
    end  
    
    %% default behavior
    [xx,yy] = ginput(N);
    
    fprintf('[New ginput]\n')
    
end