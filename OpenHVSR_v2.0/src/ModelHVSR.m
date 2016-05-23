warning('off','MATLAB:dispatcher:InexactMatch');
clear

open ampspektarHVSR.fig
set(gcf,'name','ModelHVSR, v3.4')

hnd=guihandles;
postoji=exist('setup.mat','file');
ex=str2double(get(hnd.edit197,'string'));

if postoji>0
    load setup.mat
    set(hnd.edit197,'string',num2str(ex));
else
    open_setup
    close gcf
end

vrs=version;  
% if str2double(vrs(1:3))<7.1
%     if exist('as.dll_','file')>1, dos('copy as.dll_ as.dll'); end
% else
%     if exist('as.mexw32_','file')>1, dos('copy as.mexw32_ as.mexw32'); end
%     if exist('as.dll','file')>1, dos('ren as.dll as.dll_'); end
% end


hax1=hnd.axes1; 
hax2=hnd.axes2;
axes(hax2); axis off;
axes(hax1);
workdir=pwd;
cd(pwd);
sorp=3;
set_flim;
var_rnd=0;
filnam='Model';
titl1=' ';
ijk=0;
un=0;

f=(0.1:0.01:25);
[fFS,FSraw]=FourierSpectrum(magn,delt,dept,rock); %Compute theoretical Fourier spectrum for target earthquake (see Setup)
FS=interp1(fFS,FSraw,f,'linear','extrap');
FS(f>25)=0; FS(f<0.1)=0; %FS is defined only for 0.1<=f<=25 Hz

fc1=25;
fc2=0.1;

%set(hnd.text123,'visible','off');

