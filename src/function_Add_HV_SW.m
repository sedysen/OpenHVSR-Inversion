function function_Add_HV_SW()

fprintf('sam: add surface waves\n')
fprintf('sam: Add_HV_SW.m\n')

set(hnd.pushbutton29,'string','Please wait...')
nmodes=get(hnd.edit200,'string');
nsmooth=str2num(get(hnd.edit199,'string'));
fmaxS=get(hnd.edit132,'string')
%fprintf('sam: fmaxS            %f\n',fmaxS)
pause


fid=fopen('inser_OS.txt','w');
fprintf(fid,'%s\n','###');
fprintf(fid,'%s\n','*Maximum Frequency to be considered:');
fprintf(fid,'%s\n',fmaxS);
fprintf(fid,'%s\n','* Frequency step (and minimun frequency):');
fprintf(fid,'%s\n','0.2');
fprintf(fid,'%s\n','*Maximum number of modes:');
fprintf(fid,'%s\n',nmodes);
fprintf(fid,'%s\n','*Seismic stratigraphy:');
fprintf(fid,'%s\n','H(m)     VP(m/s)      VS(m/s) RHO(Kg/m^3)       QP(-)       QS(-)');
for i=1:length(h)-1
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
fclose(fid)
!microtrem
load HVratio

% f=0.2:0.2:str2num(FmaxS);
% aswave=as(vs,ro,h,qs,0.,30,f);
% apwave=as(vp,ro,h,qs,0.,30,f);
% HVSR=aswave./apwave;
% semilogx(HVratio(:,1),smooth(HVratio(:,2),5),'r',f,HVSR)
hold on
hswhvsr=semilogx(HVratio(:,1),smooth(HVratio(:,2),nsmooth),'g');% If error: smooth -> SAM_2018a_smooth
set(hswhvsr,'linewidth',2)
grid on
hold off
set(hnd.pushbutton29,'string','Add surface w. HVSR')
end % function
