function [FF,HV] = call_Albarello_2011(nmodes, nsmooth, fstep, fmaxS, h,vp,vs,ro,qp,qs)
% inputs
% nmodes                        number of modes
% nsmooth                       n of samples invelved in smoothing
% fstep                         frequency step (and minimun frequency)
% fmaxS                         maximum frequence allowed
% h,vp,vs,ro,qp,qs              visco-elastic parameters
%
% outputs:
% FF                            frequency vector
% HV                            H/V ratio
    FF = [];
    HV = [];
    fprintf('sam: add surface waves\n')
    fprintf('sam: Add_HV_SW.m\n')

%    set(hnd.pushbutton29,'string','Please wait...')
%    nmodes=get(hnd.edit200,'string');
%    nsmooth=str2num(get(hnd.edit199,'string'));
%    fmaxS=get(hnd.edit132,'string');
    fid=fopen('inser_OS.txt','w');
    fprintf(fid,'%s\n','###');
    fprintf(fid,'%s\n','*Maximum Frequency to be considered:');
    fprintf(fid,'%f\n',fmaxS);
    fprintf(fid,'%s\n','* Frequency step (and minimun frequency):');
    fprintf(fid,'%f\n',fstep);
    fprintf(fid,'%s\n','*Maximum number of modes:');
    fprintf(fid,'%d\n',nmodes);
    fprintf(fid,'%s\n','*Seismic stratigraphy:');
    fprintf(fid,'%s\n','H(m)     VP(m/s)      VS(m/s) RHO(Kg/m^3)       QP(-)       QS(-)');
    
    %model ....
    for i=1:length(h)-1
       %fprintf(fid,'%g %g %g %g %g %g \n',[h(i) vp(i) vs(i) ro(i)*1000 qp(i) qs(i)]);
       fprintf(fid,'%g %g %g %g %g %g \n',[h(i) vp(i) vs(i) ro(i)*1000 qp(i) qs(i)]);
    end
    i=length(h);
    
    %Layers are added to stabilize solution
    fprintf(fid,'%g %g %g %g %g %g \n',[ 250 vp(i)      vs(i)      ro(i)*1000 qp(i) qs(i)]);
    fprintf(fid,'%g %g %g %g %g %g \n',[ 400 vp(i)*1.10 vp(i)*1.10/1.9  2500  qp(i)*1.2 qs(i)*1.2]);
    fprintf(fid,'%g %g %g %g %g %g \n',[ 250 vp(i)*1.15 vp(i)*1.15/1.9  2500  qp(i)*1.4 qs(i)*1.4]);
    fprintf(fid,'%g %g %g %g %g %g \n',[ 300 vp(i)*1.18 vp(i)*1.18/1.9  2500  qp(i)*1.6 qs(i)*1.6]);
    fprintf(fid,'%g %g %g %g %g %g \n',[ 250 vp(i)*1.20 vp(i)*1.20/1.8  2500  qp(i)*1.8 qs(i)*1.8]);
    fprintf(fid,'%g %g %g %g %g %g \n',[   0 vp(i)*1.22 vp(i)*1.22/1.73 2600  qp(i)*2.0 qs(i)*2.0]);
    fclose(fid);
    %fprintf('----\n');
    % !microtrem % Before 2012b
    % status = 1;
    status = system('microtrem');% try simpler command
    if(status==0); fprintf('microtrem success!  [1st]\n'); end
    
    if(status==1) % try adding extension
        status = system('microtrem.exe'); 
        if(status==0); fprintf('microtrem success!  [2nd]\n'); end
    end
    
    if(status==1)% try using full path with current matlab working folder
        status = system( strcat(pwd,'microtrem.exe') );
        if(status==0); fprintf('microtrem success!  [3th]\n'); end
    end
    
    if(status==1)% try using full path of the calling script
        current_folder = pwd;
        ffullpath = mfilename('fullpath');
        if ~strcmp(ffullpath( (end-1):end) , '.m')
            ffullpath = ffullpath(1: (end-19));
        else
            ffullpath = ffullpath(1: (end-21));
        end
        if ~strcmp(current_folder , ffullpath)
            cd(ffullpath) 
        end
        status = system( strcat(pwd,'\microtrem.exe') );
        if(status==0); fprintf('microtrem success!  [4th]\n'); end
    end
    
    
    if(status==1)
        fprintf('Matlab did not find executable: microtrem.exe.\n');
        fprintf('Program will now stop.\n');
        error('Please contact Samuel Bignardi. sedysen@gmail.com.');
    end
    %fprintf('----\n');
    if exist('HVratio','file') ==2
        load HVratio;
        % output:
        FF = HVratio(:,1);
        HV = SAM_smooth(HVratio(:,2),nsmooth);
        delete HVratio
    else
        warning('Surf. Waves Simulation cannot be performed.')
    end
end
