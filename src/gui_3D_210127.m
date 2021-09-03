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
%
% Lateral constrained montecarlo inversion of HVSR data
function gui_3D_210127()  

close all
clc
%% to load project
id ='';
i = 0;
dx= 0;
x = 0; 
%
%
%
%%%------------------------------------------------------------------------
%% NOTES:
%      hvsr curve is a function of frequence.
%      in what follows:
%      scale = frequency scale, also x 
%      curve = hvsr
%
%
%    model is:  vp  vs  rho  h  Qp  Qs
%
%

%%%-----------------------------
%
%
%% PROGRAM machinery
%%    ON/OFF Features
%190404 beta_stuff_enable_status   = 'off';
%190404 USER_PREFERENCE_Move_over_suggestions = 'on';
if ispc()
    FLAG__PC_features = 'on';
else
    FLAG__PC_features = 'off';
end
%% Set core variables
G = [];
H = [];
P = [];
Pfiles_SET_ONOFF_FEAT%          extra features
Pfiles__INTERNAL_VARIABLES%     contains private variables
%
%%    Default values
[min_vs, min_vp_vs_ratio, max_vp_vs_ratio, ...
min_ro,max_ro, ...
min_H,max_H, ...
min_qs,max_qs, ...
min_qp_qs_ratio,max_qp_qs_ratio, ...
HQMagnitude, ...
HQEpicDistance, ...
HQFocalDepth, ...
HQRockRatio, ...
sw_nmodes, ...
sw_nsmooth, ...
sensitivity_colormap, ...
confidence_colormap] = load_defaults();
%%    Tool Variable
SURVEYS    = {};                                % Surveys Description
MODELS     = {};                                % Models  Description 
FDAT       = {};                                % Field Data
%                                               % col 1: x-axis fr the curve
%                                               % col 2: curve
%                                               % col 3: standard deviation
DISCARDS   = {};
modl_FDAT  = {};                                % response of the MODEL button
modl_FDATSW= {};                                % response of the Add S.W. button
last_FDAT  = {};                                % Last Models. after inversion step.
best_FDAT  = {};                                % Best Models. after inversion step.
%                                               FDAT = cell(N, 3) == [freq, hvsr, standard_deviation]
best_MISFIT_by_location = [];%                        Laterally constrained optimization (one vector recording the best misfit for each location)
%
MDLS       = {};                                % Subsurface Initial models [vp  vs  rho  h  Qp  Qs] - > [VPList,VSList,ROList,Hprofile,QPList,QSList]
%                                               % If a better model is found, the new model will overwrite this
last_MDLS  = {};                                % Last Models. after inversion step.
vfst_MDLS  = {};                                % very first model.
%
prev_MDLS               = {};                   % models before last optimization section
prev_BEST_SINGLE_MODELS = {};
prev_best_FDAT          = {};
prev_BEST_SINGLE_MISFIT = [];
prev_single_it          = 0;
%
weight_curv =[];                                % curve weights definition
CW = {};                                        % USED  curve-weights (cell: for future development)
%
weight_dpth=[];                                % depth weights definition
DW  = {};                                      % USED  depth-weights
DL  = {};                                      %       depth-levels
LKT = [];                                      % Lock Table (comply with settings)
RCT = [];                                      % Relax constrains:
%                                                column 1: relax Vp/Vs higher bound (Allaw Water table)
%
r_reciprocicity = [];                          % (3D) station to station distances table
receiver_locations     = [];                   % (3D) stations locations          
cutplanes       = [0,1, 0,1, 0,1];             % (3D) sliders for slicing          
%isslice         = cutplanes;                  % (3D) coordinates for slicing     
%r_distance_from_profile = 50;                  % (3D) 
Flag__stop_inversion = 0;
%
%
%% USER_PREFERENCE_interface_objects_fontsize is NEW
%% P is new
P.isshown.id      = 0;
%
P.profile.id      = 0;
P.profile_ids     = {};                          % (3D) [id's; x-position, distances from rect] to create a 2D profile: Cell since 190404
P.profile_line    = {};                          % (3D) :Cell since 190404 
P.profile_name    = {};                          % (3D) :NEW, Cell since 190404 
P.profile_onoff   = {};                          % (3D) :NEW, Cell since 190404 
dim             = [];  
%
%
Misfit_curve_term_w = 0.9;        
Misfit_slope_term_w = 0.1;
%
TO_INVERT = [];                            % [1] if files have to be used
%                                            [2] if the model is acceptable 
%                                                and must be kept fixed (LOCKED) 
NresultsToKeep = 50;
global_inversion_step = 0;

% Laterally constrained optimization
BEST_ENERGIES =  realmax() * ones(NresultsToKeep,1);% Laterally constrained optimization
BEST_MISFITS = realmax() * ones(NresultsToKeep,1);%   Laterally constrained optimization
BEST_MODELS = cell(NresultsToKeep,1);%                Laterally constrained optimization
init_single_FDAT = {};%                      in single optimization section: inittial model 
%
last_single_MDL = {};
last_single_FDAT = {};
BEST_SINGLE_MISFIT = [];
BEST_SINGLE_MODELS = {};

BREAKS = [];%                                     breaks of the profile: 
%                                                 BREAKS(1) = 1 means: 
%                                                 model 1 and 2 are decoupled
%             
independent_optimiazation_cicles = [];

STORED_RESULTS_1d_misfit = {};%                  {survey id}(iteration:      [misfit,  misfit/sum-of-weights])
STORED_RESULTS_2d_misfit = {};%                  {survey id}(iteration:      [misfit,  misfit/sum-of-weights])
STORED_RESULTS_2d_misfit_profile = [];%          (iteration:      [misfit,  misfit/sum-of-weights,    energy]) whole profile
%     The folliwing follows Herack. Is a cell row. one survey for each cell position
%     each cell contains a matrix formed with stack of rows.
%     For example vs_fit is a stach of vs values for subsequent models
%     Row follows left to tight position is top to bottom layer rule
%     
STORED_1d_vp_fits         = {};% {survey id}() filled independently                  
STORED_1d_vs_fits         = {};
STORED_1d_ro_fits         = {};
STORED_1d_hh_fits         = {};
STORED_1d_qp_fits         = {};
STORED_1d_qs_fits         = {};
STORED_1d_daf_fits        = {};

STORED_2d_vp_fits         = {};% {survey id}() filled at the same time                  
STORED_2d_vs_fits         = {};
STORED_2d_ro_fits         = {};
STORED_2d_hh_fits         = {};
STORED_2d_qp_fits         = {};
STORED_2d_qs_fits         = {};
STORED_2d_daf_fits        = {};

Misfit_vs_Iter            = {};
Misfit_vs_Iter_MULPTIPLE  = [];% retains the best misfit value in crinological(iteration time). Sum lump of all surveys
Misfit_vs_Iter_MULPTIPLE_local = [];% retains the best misfit value in crinological(iteration time). At each location (ID)
inversion_is_started__inedipendent= '';
inversion_is_started__global      = '';

% data_1d_to_show           = 0; FIX
property_1d_to_show       = 0;
property_23d_to_show      = 0;

ZZList  = [];% zlevels + elevation
VPList  = [];
VSList  = [];
ROList  = [];
QPList  = [];
QSList  = [];
zlevels    = [];%  All from 0. Not accounts for elevation (it is depth, negative z)
xpositions = [];%  All from 0. Not accounts for elevation 
bedrock    = [];
%
datafile_columns   = [1 2 3];% [FREQ. column Id][HVSR. column Id][standard dev. Id]
datafile_separator = 'none';% in data files: separator between HEADER and DATA
%
% Graphic
n_depth_levels     = 20;
smoothing_strategy = 3;
smoothing_radius   = 3;
viewerview = [ -37.5, 30.0];
%
%% Get USER preferences
USER_PREFERENCE_Move_over_suggestions      = '';
USER_PREFERENCE_interface_objects_fontsize = 0; 
USER_PREFERENCE_enable_Matlab_default_menu = 0;
%
USER_PREFERENCE_Subsurface_model_color_limits = [];
USER_PREFERENCE_Subsurface_model_colormap     = 'Jet';
USER_PREFERENCE_Subsurface_model_interpolation= [];
USER_PREFERENCES
%
%%    Target Earthquake
HQfreq = [];%        fFS,
QHspec = [];%        FSraw
%%    Confidence  plots
conf_1d_to_show_x      = 0;
conf_1d_to_show_y      = 0;

misfit_over_sumweight = [];
ndegfree = 0;
lsmooth =  3;
nlvl    = 30;
default_colormap = 'Jet';
SS=[]; poten=1; X1=[]; X2=[]; var1=0; var2=0; vala=0; valb=0; nlaya=0; nlayb=0;
%%    Sensitivity plots
sns_1d_to_show         = 0;
SN_xscale              = [];
SN_parscale            = [];
SN_dtamsf              = [];
SN_parname             = '';
SN_centralval          = 0;
%%    Figure variables
nx_ticks = 0;% interpolation
ny_ticks = 0;
nz_ticks = 0;
color_limits = [];
color_map  = ''; 

%%        Show weights
curve_weights_plotmode = 1;
depth_weights_plotmode = 0;
curve_plotmode         = 1;
%%    Initial Values for the main scale
%      main scale is frequence and is also indicated with x
main_scale = [];
ixmin_id = 0;
ixmax_id = 0;


view_min_scale = 0;
view_max_scale = 100;

init_value__fref                = '30';
init_value__dscale              = '0.1';
init_value__min_scale           = '0.4';
init_value__max_scale           = '4';

max_lat_dVp = 100; 
max_lat_dVs =  50;
max_lat_dRo = 300;
max_lat_dH  =  10;
max_lat_dQp =  10;
max_lat_dQs =  10;
%% NEW AND TEMPORARY FEATURES xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
%%    Reference models: vp  vs  rho  h  Qp  Qs
REFERENCE_MODEL_dH       = [];
REFERENCE_MODEL_zpoints  = [];
%%    Surface Waves
% sw_nmodes   = 15;
% sw_nsmooth  = 5;
% sw_fmax     = 0;%% set later depending on the user
%% xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
%%
%% MAIN GUI ===============================================================
DSP = get(0,'ScreenSize');% [left, bottom, width, height]
main_l = 0.1 * DSP(3);
main_b = 0.1 * DSP(4);
main_w = 0.8 * DSP(3);
main_h = 0.8 * DSP(4);
%190404 h_gui = figure('Visible','on','OuterPosition',[main_l, main_b, main_w, main_h],'NumberTitle','off');
h_view_rotation = rotate3d;
set(h_view_rotation ,'ActionPostCallback',@ViewerPostCallback);
%%  Build Interface components.
%% MENUS
if USER_PREFERENCE_enable_Matlab_default_menu == 0
    set(H.gui,'MenuBar','none');    % Hide standard menu bar menus.
end
%%    File
h0  = uimenu(H.gui,'Label','Files');
uimenu(h0,'Label','Create/Edit project','Callback',{@Menu_Project_Create}, ...
'Separator','on');
uimenu(h0,'Label','Load HVI project', 'Callback',{@Menu_Project_Load});
uimenu(h0,'Label','HVSR files format','Callback',{@Menu_File_Set_file_format});
%
uimenu(h0,'Label','Save Subsurface Model as .txt set','Callback',{@Menu_Model_Save_txt_set}, ...
'Separator','on');
uimenu(h0,'Label','Save Modeled Curves (P/S) as txt','Callback',{@Menu_Curve_Save_txt_set});
uimenu(h0,'Label','Save Modeled Curves (SW) as txt', ...
'Enable',FLAG__PC_features,'Callback',{@Menu_Curve_Save_txt_set_sw});

uimenu(h0,'Label','Save as new project','Callback',{@Menu_Save_as_newproject_set});
%
uimenu(h0,'Label','Save Elaboration',  'Callback',{@Menu_Save_elaboration},'Separator','on');
uimenu(h0,'Label','Resume Elaboration','Callback',{@Menu_Load_elaboration});
%%    Settings
h1  = uimenu(H.gui,'Label','Settings');
uimenu(h1,'Label','Setup','Callback',{@Menu_Settings_Setup});
uimenu(h1,'Label','Objective Func.','Callback',{@Menu_Settings_objective});
%%    View
%%        HVSR curve
h5  = uimenu(H.gui,'Label','View');
h51 = uimenu(h5,'Label','HVSR');
uimenu(h51,'Label','View Freq. range','Callback',{@Menu_view_xcurverange_custom});
uimenu(h51,'Label','Fit view to processed data','Callback',{@Menu_view_xcurverange_fitprocessed});
uimenu(h51,'Label','Fit view all data','Callback',{@Menu_view_xcurverange_fitdata});
%%        SUBSURFACE view
h52 = uimenu(h5,'Label','Subsurface');
%%            Interpolation
uimenu(h52,'Label','Interpolation','Callback',{@Menu_view_media_interp});
%%        colormap
uimenu(h52,'Label','Color Limits','Callback',{@Menu_View_clim});
h5_1 = uimenu(h5,'Label','Colormap');
uimenu(h5_1,'Label','Jet','Callback', {@Menu_view_cmap_Jet});
uimenu(h5_1,'Label','Hot','Callback', {@Menu_view_cmap_Hot});
uimenu(h5_1,'Label','Bone','Callback',{@Menu_view_cmap_Bone});
%%
eh52 = uimenu(h52,'Label','Profile Smoothing');
eh52_childs = zeros(1,4);
eh52_childs(1) = uimenu(eh52,'Label','off','Callback',        {@Menu_smoothing_strategy0_Callback});
eh52_childs(2) = uimenu(eh52,'Label','Layer','Callback',      {@Menu_smoothing_strategy1_Callback});
eh52_childs(3) = uimenu(eh52,'Label','Broad Layer','Callback',{@Menu_smoothing_strategy2_Callback});
eh52_childs(4) = uimenu(eh52,'Label','Bubble','Callback',     {@Menu_smoothing_strategy3_Callback});



%%    Extra
h7  = uimenu(H.gui,'Label','Extra');
uimenu(h7,'Label','Schreenshot','Callback',{@funct_saveimage});
%%    About
H.menu.credits  = uimenu(H.gui,'Label','Credits','Callback',{@Menu_About_Credits});
%%
%%
%% ************************* INTERFACE OBJECTS ****************************
%% Panels
Pnl = [];
Pfiles_PANELS
%% ABOUT MATLAB RELEASE: Get release and apply release-specific behavior  
[Matlab_Release,Matlab_Release_num, hTabGroup,SelectionChangeOption] = Pfiles_Function_MATLAB_Release(H.gui);
P.SelectionChangeOption = SelectionChangeOption;

set(H.gui,'visible','on')%% delete FIX
%
%%    Panels: locations and sizes 
%% TAB: ============================================================== MAIN: 190404
%
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%
create_new_tab('Main View');
%%     Panels
H.PANELS{P.tab_id}.A = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units', 'normalized','Position',Pnl.Lay0.A);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.A,'title','A');end
H.PANELS{P.tab_id}.B = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay0.B);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.B,'title','B');end
%%     Objets on panel A
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
%
%%       Objects 
%%          Navigation
objw = 1;
objx = 0;
row = 1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A, ...%H.PANELS{P.tab_id}.A, ...
    'String','Measuremet Location', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);%% setting weigths for fiele   FIX
row = row+1;
T1_PA_wgt_file = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A, ...%H.PANELS{P.tab_id}.A, ...
    'String',' ', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);%% setting weigths for fiele   FIX
objw = [0.25,  0.25,  0.25,  0.2];
objx = [0.0,   0.25,  0.50,  0.8];
row = row+1;
T1_PA_wgt_bk = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...%,H.PANELS{P.tab_id}.A, ...
    'String','<<', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@CB_hAx_geo_back});
T1_PA_wgt_goto = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...%,H.PANELS{P.tab_id}.A, ...
    'String','go to', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@CB_hAx_geo_goto});
T1_PA_wgt_fw = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...%H.PANELS{P.tab_id}.A, ...
    'String','>>', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'Callback',{@CB_hAx_geo_next});
%%          Move Over suggestions
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    set(T1_PA_wgt_fw,'TooltipString','Next location')
    set(T1_PA_wgt_goto,'TooltipString','Go to custom location')
    set(T1_PA_wgt_bk,'TooltipString','Previous location')
end
%%          INFO measurements:
row = row+1;
objw = [0.25,  0.75];
objx = [0.0,   0.25];
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','File ID:', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
T1_PC_dataid_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'BackgroundColor', [1 1 1]);
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Data File', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
T1_PC_datafile_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'BackgroundColor', [1 1 1]);
%
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Model File', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
T1_PC_modelfile_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'BackgroundColor', [1 1 1]);
%
%%          Profile (if any)
row = row+3;
objw = 1;
objx = 0;
T1_PA_prof_0 = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...%'parent',H.PANELS{P.tab_id}.A, ...
    'String','Profiles', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
row = row+1;
objw = [0.2, 0.2,   0.195, 0.195, 0.195];
gapx = 1-sum(objw)-0.005;
objx = [0, objw(1), (sum(objw(1:2)) + gapx), (sum(objw(1:3)) + gapx) , (sum(objw(1:4)) + gapx)];
T1_PA_prof_bk = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton', ...
    'parent',H.PANELS{P.tab_id}.A, ...%'parent',H.PANELS{P.tab_id}.A, ...
    'String','<<', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@CB_hAx_show_profile_back});
T1_PA_prof_goto = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton', ...
    'parent',H.PANELS{P.tab_id}.A, ...%'parent',H.PANELS{P.tab_id}.A, ...
    'String','go to', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@CB_hAx_show_profile_goto});
T1_PA_prof_fw = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton', ...
    'parent',H.PANELS{P.tab_id}.A, ...%'parent',H.PANELS{P.tab_id}.A, ...
    'String','>>', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'Callback',{@CB_hAx_show_profile_next});
%
T1_PA_prof_add = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton', ...
    'parent',H.PANELS{P.tab_id}.A, ...%'parent',H.PANELS{P.tab_id}.A, ...
    'String','add', ...
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh], ...
    'Callback',{@CB_hAx_profile_addrec});
T1_PA_prof_rem = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton', ...
    'parent',H.PANELS{P.tab_id}.A, ...%'parent',H.PANELS{P.tab_id}.A, ...
    'String','remove', ...
    'Units','normalized','Position',[objx(5), objy(row), objw(5), objh], ...
    'Callback',{@CB_hAx_profile_remrec});
%%          INFO profile  
row = row+1;
objw = [0.75,  0.25];
objx = [0.0,   0.75];
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Number of profiles', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
T1_PC_n_of_profiles_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'BackgroundColor', [1 1 1]);
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Active profile', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
T1_PC_active_profiles_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'BackgroundColor', [1 1 1]);
%%          Move Over suggestions
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    tipstring = sprintf('Profile Creation: (on this Tab)\n1) Define profiles by right-clicking on the map.\n2) Click to set the profile''s start point.\n3) Click again to set the profile''s end point.\n4) Include stations by entering the desired distance from profile.\n5) Use add/remove buttons to include/exclude single stations.\n \nProfile Visualization: (on "2D views" Tab)\n1) Select a profile to be shown using the [-][->][+] buttons.\n2) Select a the property to be shown using buttons on the rigth.');
    set(T1_PA_prof_0,'TooltipString',tipstring)
    set(T1_PA_prof_fw,'TooltipString',sprintf('Next profile.\nEnter the profile investigation mode.\nVisualize the profile to inspect which stations are included\nand which are not.'))
    set(T1_PA_prof_bk,'TooltipString',sprintf('Previous profile\nEnter the profile investigation mode.\nVisualize the profile to inspect which stations are included\nand which are not.'))
    set(T1_PA_prof_goto,'TooltipString',sprintf('Go to specific profile\nEnter the profile investigation mode.\nVisualize the profile to inspect which stations are included\nand which are not.'))
    
    
    set(T1_PA_prof_add,'TooltipString','Add single location to the selected profile')
    set(T1_PA_prof_rem,'TooltipString','Remove single location from the selected profile')
end
%
% 
%
%%     Objets on panel B
%%       MAP View
% pos_panel = [0.325 0.20,  (1-0.325) 0.80];
hAx_maingeo_hcmenu = uicontextmenu;
uimenu(hAx_maingeo_hcmenu, 'Label', 'Show',   'Callback', @CM_hAx_geo_show);
uimenu(hAx_maingeo_hcmenu, 'Label', 'Define 2D profile',    'Callback', {@define_Profile}, 'Separator','on');
uimenu(hAx_maingeo_hcmenu, 'Label', 'Discard  a profile',    'Callback', {@reset_one_Profile});
uimenu(hAx_maingeo_hcmenu, 'Label', 'Discard  ALL profiles',    'Callback', {@reset_Profile});
%
%uimenu(hAx_geo_hcmenu, 'Label', 'Disable','Callback', @CM_hAx_geo_disable);
%uimenu(hAx_geo_hcmenu, 'Label', 'Enable', 'Callback', @CM_hAx_geo_enable);
uimenu(hAx_maingeo_hcmenu, 'Label', 'Edit externally',    'Callback', {@plot_extern,3}, 'Separator','on');
uimenu(hAx_maingeo_hcmenu, 'Label', 'Edit externally (profile)',    'Callback', {@plot_extern,31});
pos_axes  = [0.1 0.1 0.8 0.8];
hAx_main_geo= axes('Parent',H.PANELS{P.tab_id}.B,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes,'uicontextmenu',hAx_maingeo_hcmenu);
%% TAB-1: ============================================== Inversion (Global)
%
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%
create_new_tab('Global Inversion');
%%set(H.TABS(P.tab_id),'ButtonDownFcn',{@CB_TAB_main_view_update})
%%     Panels
H.PANELS{P.tab_id}.A = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units', 'normalized','Position',Pnl.Lay5.A);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.A,'title','A');end
H.PANELS{P.tab_id}.B = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay5.B);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.B,'title','B');end
H.PANELS{P.tab_id}.C = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay5.C);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.C,'title','C');end

%
%%     Objets on panel A
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
%
%%       Objects 
%%          random method
row = 1;
basevalue = '5';
basevalue2= '0';
basevaluew ='0';
row = row+4;
objw = [0.3, 0.7];
objx = [0.0, 0.3];
hRandx = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Stat.Distribution', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
hRand = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','popup', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',['Uniform '; 'Gaussian'], ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), 2*objh] );
%%          texts
row = row+2;
objw = [0.3, 0.25, 0.25, 0.2];
objx = [0, objw(1), sum(objw(1:2)), sum(objw(1:3)) ];
hPrcv = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','%variation', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);

hLC = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Lateral constr. W.', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
%%          Thick.
row = row+1; 
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Thk.', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_hh_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevalue, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%     'Callback',{@CB_Set_HH_percent});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Vp', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_vp_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevalue, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%     'Callback',{@CB_Set_VP_percent});
h_vp_w = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevaluew, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
%%          Vs
row = row+1; 
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Vs', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_vs_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevalue, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%    'Callback',{@CB_Set_VS_percent});
h_vs_w = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevaluew, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
%%          Ro
row = row+1; 
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Rho', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_ro_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevalue2, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%     'Callback',{@CB_Set_RO_percent});
h_ro_w = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevaluew, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
%%          Qp
row = row+1; 
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Qp', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_qp_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevalue2, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%    'Callback',{@CB_Set_QP_percent});
h_qp_w = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevaluew, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
%%          Qs
row = row+1; 
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Qs', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_qs_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevalue2, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%      'Callback',{@CB_Set_QS_percent});
h_qs_w = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',basevaluew, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
%%          LOCK-TAble
row = row+1; 
objw = 1;
objx = 0;
hShLockT = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','show Lock Table', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@lock_table_modify});
%%          ex, fref
row = row+4;  
objw = [0.45, 0.55];
objx = [0,    0.45];
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','k in Q(f) = Q(1Hz)f^k', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_ex_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','0.25', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Vel. measured at (Hz)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_fref_val = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',init_value__fref, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);

row = row+1; 
objw = [0.45, 0.1375, 0.1375,  0.1375, 0.1375];
objx = [0.00, objw(1), sum(objw(1:2)), sum(objw(1:3)) , sum(objw(1:4))];
h_scale_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Freq. range', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
h_scale_min = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',init_value__min_scale, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);%, ...
%     'Callback',{@CB_Set_FMIN_percent});
h_scale_max= uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',init_value__max_scale, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);%, ...
%    'Callback',{@CB_Set_FMAX_percent});

uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','dd', ...
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh]);
h_dscale= uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','edit', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String',init_value__dscale, ...
    'Units','normalized','Position',[objx(5), objy(row), objw(5), objh]);
%%          Model
row = row+4; 
objw = [0.5, 0.5];
objx = [0, (objw(1) )];
h_fwd_bw = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','MODEL (P/S)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_start_model});
%
h_fwd_sw=uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'enable', FLAG__PC_features, ...
    'String','MODEL (SW)', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_start_model_sw});
%%          Inversion 
row = row+1;
objw = [0.5, 0.3 0.2];
objx = [0, (objw(1)),  (sum(objw(1:2)))];
T2_P1_inv_button_bw = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','START Inversion (P/S)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Interruptible','on', ...
    'Callback',{@B_start_inversion});
T2_P1_global_it_count = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A, ...
    'String','0 So far.', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
T2_P1_max_it = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A, ...
    'String','50000', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'BackgroundColor', [1 1 1]);
%
row = row+1;
T2_P1_inv_button_sw = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','START Inversion (SW)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Enable',FLAG__PC_features, ...
    'Interruptible','on', ...
    'Callback',{@B_start_inversion_SW});
T2_P1_progress = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A, ...
    'String','', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);

row = row+1;
objw = [0.5, 0.5];
objx = [0,  0.5];
T2_P1_inv_button_lw = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Automatic Weighting', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_auto_lateral_weights});
T2_P1_inv_stop = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','','Enable','off','Value', 0, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_stop_inversion_all});
%%          mouse over tips
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    hoveoverstring = sprintf('Select the distribution which the perturbations will obey');
    set(hRandx,'TooltipString',hoveoverstring)
    set(hRand,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Range of variation (as percentage) within which to search for a better model\n NOTE: might be further modified by the "Depth-Weighting function" ');
    set(hPrcv,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Weights to apply to various parameter kinds when performing\n a laterally constrained inversion');
    set(hLC,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Select which parameters will be perturbed\n and which will not');
    set(hShLockT,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Attenuation as function of the frequency\n k value in the formula\n Q(f) = Q(1Hz)f^k');
    set(h_ex_val,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Reference frequency for the formula Q(f) = Q(1Hz)f^k');
    set(h_fref_val,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('This line of controls manages which portion of the HVSR curve is considered\n \n NOTE: This values should not be changed after inversion is started. When a change is necessary, for example to gradually increase the considered frequency span,\n 1) use the ''Files/Save as new project"\n to generate a as new project while retaining the current subsurface model\n 2) perform a new independent inversion using the new parameters');
    set(h_scale_txt ,'TooltipString',hoveoverstring)  
    hoveoverstring = sprintf('Minimum frequency to consider (Hz)');
    set(h_scale_min,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Maximum frequency to consider (Hz)');
    set(h_scale_max,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Frequency axis discretization (Hz)');
    set(h_dscale,'TooltipString',hoveoverstring)
    % modeling
    hoveoverstring = sprintf('Modeling based on a sub-vertical body-waves propagation assumption.');
    set(h_fwd_bw,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Modeling based on a surface-waves propagation assumption.\n Lunedei and Albarello (2010),\n DOI: 10.1111/j.1365-246X.2010.04560.x\n (Windows only)');
    set(h_fwd_sw,'TooltipString',hoveoverstring)
    % inversion
    hoveoverstring = sprintf('Inversion based on a sub-vertical body-waves propagation assumption.');
    set(T2_P1_inv_button_bw,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Inversion based on a surface-waves propagation assumption.\n Lunedei and Albarello (2010),\n DOI: 10.1111/j.1365-246X.2010.04560.x (Windows only)');
    set(T2_P1_inv_button_sw,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Attempt to automatically determine the weights to be applied\n  to different parameters during the laterally constrained inversion');
    set(T2_P1_inv_button_lw,'TooltipString',hoveoverstring)
    %
    hoveoverstring = sprintf('Number of iterations performed');
    set(T2_P1_global_it_count,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Number of iterations still to perform');
    set(T2_P1_max_it,'TooltipString',hoveoverstring)
end
%%    Panel-B  Curve-Weighting and Depth-Weighting Function
hAx_cwf_hcmenu = uicontextmenu;
uimenu(hAx_cwf_hcmenu, 'Label', 'Modify',  'Callback', @CM_hAx_cwf_modify);
uimenu(hAx_cwf_hcmenu, 'Label', 'Exp. Decay',  'Callback', @CM_set_logaritmic_decreasing);
uimenu(hAx_cwf_hcmenu, 'Label', 'Reset',   'Callback', @CM_hAx_cwf_reset_to_1);
uimenu(hAx_cwf_hcmenu, 'Label', 'Show linear',    'Callback', @CM_hAx_cwf_show_lin, 'Separator','on');
uimenu(hAx_cwf_hcmenu, 'Label', 'Show logaritmic','Callback', @CM_hAx_cwf_show_log);
uimenu(hAx_cwf_hcmenu, 'Label', 'Edit externally',    'Callback', {@plot_extern,1}, 'Separator','on');
Position_Axes = [0.1 (0.45+0.15) 0.8 0.3];
hAx_cwf= axes('Parent',H.PANELS{P.tab_id}.B,'Units', 'normalized','Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Position', Position_Axes, ...
    'uicontextmenu',hAx_cwf_hcmenu, ...
    'title','Curve Weights');
%
hAx_dwf_hcmenu = uicontextmenu;
uimenu(hAx_dwf_hcmenu, 'Label', 'Modify',  'Callback', @CM_hAx_dwf_modify);
uimenu(hAx_dwf_hcmenu, 'Label', 'Reset',   'Callback', @CM_hAx_dwf_reset_to_1);
uimenu(hAx_dwf_hcmenu, 'Label', 'Show linear',    'Callback', @CM_hAx_dwf_show_lin);
uimenu(hAx_dwf_hcmenu, 'Label', 'Show logaritmic','Callback', @CM_hAx_dwf_show_log);
uimenu(hAx_dwf_hcmenu, 'Label', 'Edit externally',    'Callback', {@plot_extern,2}, 'Separator','on');
Position_Axes = [0.1 0.15 0.8 0.3];
hAx_dwf= axes('Parent',H.PANELS{P.tab_id}.B,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Position', Position_Axes, ...
    'uicontextmenu',hAx_dwf_hcmenu, ...
    'title','Depth Weights');
%%    Panel-C   Misfit view
%           general misfit
pos_axes3 = [0.1 0.15  0.35 0.8];
hAx_MvsIT_hcmenu_full = uicontextmenu;
uimenu(hAx_MvsIT_hcmenu_full, 'Label', 'Edit externally','Callback', {@plot_extern,10});
hAx_MvsIT_full = axes('Parent',H.PANELS{P.tab_id}.C,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes3,'uicontextmenu',hAx_MvsIT_hcmenu_full);
%           local misfit
pos_axes4 = [0.6 0.15  0.35 0.8];
hAx_MvsIT_hcmenu_full_local = uicontextmenu;
uimenu(hAx_MvsIT_hcmenu_full_local, 'Label', 'Edit externally','Callback', {@plot_extern,10});
hAx_MvsIT_full_local = axes('Parent',H.PANELS{P.tab_id}.C,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes4,'uicontextmenu',hAx_MvsIT_hcmenu_full_local);
%
%% TAB-2: =============================================== Inversion (Local)
%
%   [BB][CCC][DDD]
%   [BB][CCC][DDD]
%   [AA][CCC][EEE]
%   [AA][CCC][EEE]
%
create_new_tab('Local Inversion');
%%     Panels
H.PANELS{P.tab_id}.A = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units', 'normalized','Position',Pnl.Lay3.A);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.A,'title','A');end
H.PANELS{P.tab_id}.B = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay3.B);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.B,'title','B');end
H.PANELS{P.tab_id}.C = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay3.C);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.C,'title','C');end
H.PANELS{P.tab_id}.D = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay3.D);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.D,'title','D');end
H.PANELS{P.tab_id}.E = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay3.E);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.E,'title','E');end
%%     Objets on panel A
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
%%       Objects 
row = 18;
objw = [0.2, 0.2,   0.195, 0.195, 0.195];
gapx = 1-sum(objw)-0.005;
objx = [0, objw(1), (sum(objw(1:2)) + gapx), (sum(objw(1:3)) + gapx) , (sum(objw(1:4)) + gapx)];
h_1d_prev = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','<<', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@CB_hAx_geo_back});
h_1d_next = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','>>', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@CB_hAx_geo_next});

h_1d_spreadL = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Spread L', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'Callback',{@CM_hAx_keep_and_spread_left});
h_1d_spreadALL = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Spread', ...
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh], ...
    'Callback',{@CM_hAx_keep_and_spread_model});

h_1d_spreadR = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Spread R', ...
    'Units','normalized','Position',[objx(5), objy(row), objw(5), objh], ...
    'Callback',{@CM_hAx_keep_and_spread_right});

row = row+1;
h_1d_disable =uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Disable', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@CM_hAx_geo_disable});
h_1d_enable =uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Enable', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@CM_hAx_geo_enable});
%% NEW BUTTON, look side effects: CM_hAx_keep_and_spread_to  
h_1d_spreadTO = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Spread to:', ...
    'Enable','on', ... 
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh], ...
    'Callback',{@CM_hAx_keep_and_spread_to});

row = row+1;
h_1d_Lock = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Lock Model', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_lock_model});
h_1d_Unlock = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Unlock Model', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_unlock_model});
%% NEW BUTTON, look side effects: CM_hAx_double_all_layers
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Double layers', ...
    'Enable',P.ExtraFeatures.beta_stuff_enable_status, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'Callback',{@CM_hAx_double_all_layers});
%% NEW BUTTON, look side effects: CM_hAx_double_a_layer
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Double layer', ...
    'Enable',P.ExtraFeatures.beta_stuff_enable_status, ...
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh], ...
    'Callback',{@CM_hAx_double_a_layer});
%
%% NEW BUTTON, look side effects: CM_hAx_keep_unite_all_layers
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Unite layers', ...
    'Enable',P.ExtraFeatures.beta_stuff_enable_status, ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'Callback',{@CM_hAx_keep_unite_all_layers});
%% NEW BUTTON, look side effects: CM_hAx_keep_and_unite_two_layers
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Unite two layers', ...
    'Enable',P.ExtraFeatures.beta_stuff_enable_status, ...
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh], ...
    'Callback',{@CM_hAx_keep_and_unite_two_layers});
%% NEW BUTTON, look side effects: CM_hAx_keep_Equate_layer_number
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Equate N of layers', ...
    'Enable',P.ExtraFeatures.beta_stuff_enable_status, ...
    'Units','normalized','Position',[objx(4), objy(row), objw(4), objh], ...
    'Callback',{@CM_hAx_keep_Equate_layer_number});
%%
row = row+2;
objw = [0.3, 0.3 0.3];
objx = [0, objw(1), sum(objw(1:2))];
T3_P1_inv = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Optimize (P/S)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Interruptible','on', ...
    'Callback',{@B_start_inversion__independently});
T3_P1_it_count = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A, ...
    'String','0', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
T3_P1_max_it = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A, ...
    'String','10000', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(3), objh], ...
    'BackgroundColor', [1 1 1]);
row = row+1;
T3_P1_invSW = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Optimize (SW)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Enable',FLAG__PC_features, ...
    'Interruptible','on', ...
    'Callback',{@B_start_inversion__independently_SW});
row = row+1;
objw = [0.3, 0.5];
objx = [0,  0.5];
T3_p1_revert = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Revert', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_revert_1d});
T3_P1_inv_stop = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','','Enable','off','Value', 0, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_stop_inversion});

row = row+1;
objw = [0.1, 0.3];
objx = 0.01 + [0, objw(1)];
h_realtime = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','radiobutton', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'Value', 0, ... 
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'Style','text', ...
    'parent',H.PANELS{P.tab_id}.A, ...
    'String','Toggle real-time updates', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);

row = row+2;
objw = 1;
objx = 0.01;
T3_P1_txt = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text', ... 
    'parent',H.PANELS{P.tab_id}.A,'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'BackgroundColor', [1 1 1]);
%%    Panel-B: Surveys locations 
%190404 pos_panel = [0 0.5 0.325, 0.5];%0.4, 0.5];
pos_axes  = [0.1 0.1 0.8 0.8];
%190404 hT3_P4 = uipanel('FontSize',fontsizeis,'parent',hTab_1d_viewer,'Units','normalized','Position',pos_panel);
hAx_geo_hcmenu = uicontextmenu;
%190404  uimenu(hAx_geo_hcmenu, 'Label', 'Show',   'Callback', @CM_hAx_geo_show);
%190404  uimenu(hAx_geo_hcmenu, 'Label', 'Define 2D profile',    'Callback', {@define_Profile}, 'Separator','on');
%190404  uimenu(hAx_geo_hcmenu, 'Label', 'Discard  a profile',    'Callback', {@reset_one_Profile});
%190404  uimenu(hAx_geo_hcmenu, 'Label', 'Discard  ALL profiles',    'Callback', {@reset_Profile});
%190404 uimenu(hAx_geo_hcmenu, 'Label', 'Disable','Callback', @CM_hAx_geo_disable);
%190404 uimenu(hAx_geo_hcmenu, 'Label', 'Enable', 'Callback', @CM_hAx_geo_enable);
uimenu(hAx_geo_hcmenu, 'Label', 'Edit externally',    'Callback', {@plot_extern,3}, 'Separator','on');

hAx_geo= axes('Parent',H.PANELS{P.tab_id}.B,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes,'uicontextmenu',hAx_geo_hcmenu);
%%    Panel-C: data view
pos_panel = [0.325 0    0.325, 1];%[0.4 0    0.3, 1];
%190404 hT3_P2 = uipanel('FontSize',fontsizeis,'parent',hTab_1d_viewer,'Position',pos_panel); 
hAx_dat_hcmenu = uicontextmenu;
uimenu(hAx_dat_hcmenu, 'Label', 'Discard data',   'Callback', @CM_hAx_dat_disable);
uimenu(hAx_dat_hcmenu, 'Label', 'Restore data',   'Callback', @CM_hAx_dat_enable, 'Separator','on');
uimenu(hAx_dat_hcmenu, 'Label', 'Show linear',    'Callback', @CM_hAx_dat_show_lin);
uimenu(hAx_dat_hcmenu, 'Label', 'Show logaritmic','Callback', @CM_hAx_dat_show_log);
uimenu(hAx_dat_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,4}, 'Separator','on');
pos_axes = [0.1 0.1 0.8 0.8];
hAx_dat= axes('Parent',H.PANELS{P.tab_id}.C,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes,'uicontextmenu',hAx_dat_hcmenu);
%%    Panel-D: model view
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
pos_table = [0   0  1  1];
%
hTab_mod_cnames = {'Vp','Vs','Rho','H','Qp','Qs','Depth'};
hTab_mod_hcmenu = uicontextmenu;
uimenu(hTab_mod_hcmenu, 'Label', 'Modify',   'Callback', @CM_hAx_mod_modify);
hTab_mod= uitable('Parent',H.PANELS{P.tab_id}.D,'ColumnName',hTab_mod_cnames,'Units','normalized','Units','normalized','Position',pos_table, ...
    'uicontextmenu',hTab_mod_hcmenu, ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize,'ColumnFormat',{'bank','bank','bank','bank','bank','bank','bank'}, ...
    'ColumnWidth',{75 75 50 50 50 50}); 
%
row = 1;
dww = 1/7;
objw = dww*[1 1 1 1 1 1 1];
objx = 0:dww:(1-dww);
%
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','Vp', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 1});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','Vs', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 2});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','Ro', ...
    'Units','normalized','Position',[objx(3), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 3});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','Qp', ...
    'Units','normalized','Position',[objx(4), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 4});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','Qs', ...
    'Units','normalized','Position',[objx(5), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 5});
%
%row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','Nu', ...
    'Units','normalized','Position',[objx(6), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 6});
%row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.D, ...
    'String','DW', ...
    'Units','normalized','Position',[objx(7), objy(row), objw(1), objh], ...
    'Callback',{@B_hAx_model_profile, 7});
%%    Panel-D: model view
pos_axes = [0.1 0.075  0.38 1];
hAx_1dprof_hcmenu = uicontextmenu;
uimenu(hAx_1dprof_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,5});
hAx_1dprof= axes('Parent',H.PANELS{P.tab_id}.E,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes,'uicontextmenu',hAx_1dprof_hcmenu);
%
pos_axes2 = [0.6 0.075  0.38 1];
hAx_MvsIT_hcmenu = uicontextmenu;
uimenu(hAx_MvsIT_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,9});
hAx_MvsIT = axes('Parent',H.PANELS{P.tab_id}.E,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axes2,'uicontextmenu',hAx_MvsIT_hcmenu);
%
%%    mouse over tips
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    hoveoverstring = sprintf('Go to the previous location');
    set(h_1d_prev,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Go to the next location');
    set(h_1d_next,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Copy this subsurface to the previous location (Left)');
    set(h_1d_spreadL,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Copy this subsurface to the next location (Right)');
    set(h_1d_spreadR,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Copy this subsurface to ALL locations');
    set(h_1d_spreadALL,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Copy this subsurface to a custom location');
    set(h_1d_spreadTO,'TooltipString',hoveoverstring)
    
   
    hoveoverstring = sprintf('Keep the subsurface model at this location fixed');
    set( h_1d_Lock ,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Disable: do not consider this station in any computation or graphic');
    set(h_1d_disable,'TooltipString',hoveoverstring)
    
    %2D hoveoverstring = sprintf('Insert break:\n at this location the lateral constraint is not enforced');
    %2D set(h_1d_break,'TooltipString',hoveoverstring)
   
    % inversion
    hoveoverstring = sprintf('Inversion based on a sub-vertical body-waves propagation assumption.\n Only for this station.');
    set(T3_P1_inv,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Inversion based on a surface-waves propagation assumption.\n Only for this station.\n Lunedei and Albarello (2010),\n DOI: 10.1111/j.1365-246X.2010.04560.x (Windows only)');
    set(T3_P1_invSW,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Restore the previous model.\n (only once, only right after optimization has stopped)');
    set(T3_p1_revert,'TooltipString',hoveoverstring)
     hoveoverstring = sprintf('Switch between:\n checked:   update graphics every iteration (slower)\n unchecked: update graphics only when a better model is found');
    set(h_realtime,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Station/Location being considered');
    set(T3_P1_txt,'TooltipString',hoveoverstring)
    
    %
    hoveoverstring = sprintf('Number of iterations performed');
    set(T3_P1_it_count,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Number of iterations still to perform');
    set(T3_P1_max_it,'TooltipString',hoveoverstring)
end
%% TAB-3: ====================================================== Section 3D
%
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%   [AA][BBBBBB]
%
create_new_tab('Model Viewer');
%%set(H.TABS(P.tab_id),'ButtonDownFcn',{@CB_TAB_main_view_update})
%%     Panels
H.PANELS{P.tab_id}.A = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units', 'normalized','Position',Pnl.Lay0.A);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.A,'title','A');end
H.PANELS{P.tab_id}.B = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay0.B);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.B,'title','B');end
%%     Objets on panel A
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
%%        Objects
objw = 1;
objx = 0;
row  = 3;
hwi23D = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'String',[ '  3D ';'Prof.'], ...
    'Units','normalized','Position',[objx, objy(row), objw, 3*objh]);
%
row = row+2;
hRefresh = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Refresh', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'Callback',{@BT_refresh_modelview});
row = row+2;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Vp', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'Callback',{@BT_show_media,1});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Vs', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'Callback',{@BT_show_media,2});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Ro', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'Callback',{@BT_show_media,3});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Qp', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'Callback',{@BT_show_media,4});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','Qs', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh], ...
    'Callback',{@BT_show_media,5});
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','', ...
    'Units','normalized','Position',[objx, objy(row), objw, objh]);
% uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
%     'String','Profiling', ...
%     'Units','normalized','Position',[objx, objy(row), objw, objh], ...
%     'Callback',{@BT_show_media,6});
%%        Slicers
row = row+3;
Slider0 = uicontrol('Style','slider','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Max',1,'Min',0,'Value',0, ...
    'TooltipString','slicer (X-) side', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@Slider0_Callback});
row = row+1;
Slider0b = uicontrol('Style','slider','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Max',1,'Min',0,'Value',1, ...
    'TooltipString','slicer (X+) side', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@Slider0b_Callback});
row = row+2;
Slider1 = uicontrol('Style','slider','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Max',1,'Min',0,'Value',0, ...
    'TooltipString','slicer (Y-) side', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@Slider1_Callback});
row = row+1;
Slider1b = uicontrol('Style','slider','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Max',1,'Min',0,'Value',1, ...
    'TooltipString','slicer (Y+) side', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@Slider1b_Callback});
row = row+2;
Slider2 = uicontrol('Style','slider','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Max',1,'Min',0,'Value',0, ...
    'TooltipString','slicer (Z-) side', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@Slider2_Callback});
row = row+1;
Slider2b = uicontrol('Style','slider','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Max',1,'Min',0,'Value',1, ...
    'TooltipString','slicer (Z+) side', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@Slider2b_Callback});
row = row+1;
Btn0 = uicontrol('Style','pushbutton','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ...
    'String','Reset', ...
    'Position',[objx, objy(row), objw, objh], 'Enable','on', ...
    'Callback',{@ResetSlices_Callback});
%%
row = row+2;
h_togg_terrain = uicontrol('Style','radiobutton','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Value',1, ...
    'String','Terrain', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@BT_refresh_modelview});
row = row+1;
h_togg_measpoints = uicontrol('Style','radiobutton','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Value',1, ...
    'String','Survey', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@BT_refresh_modelview});
row = row+1;
h_togg_2D_layers_boundaries = uicontrol('Style','radiobutton','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Value',0, ...
    'String','Layers boundaries', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@BT_refresh_modelview});
%row = row+1;
row = row+1;
h_togg_2D_bedrock_line = uicontrol('Style','radiobutton','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ... 
    'Value',0, ...
    'String','Bedrock line', ...
    'Position',[objx, objy(row), objw, objh],'Callback',{@BT_refresh_modelview});
row = row+1;
T5_P1_HsMask = uicontrol('Style','radiobutton','parent',H.PANELS{P.tab_id}.A,'Units','normalized', ...
    'FontSize',USER_PREFERENCE_interface_objects_fontsize, ...    
    'String','Mask half-space', 'Value',1, ...
    'Units','normalized','Position',[objx, objy(row), objw, objh],'Callback',{@BT_refresh_modelview});
%
%%    Panel-B: 2D/3D representation
%190404 pos_panel = [0.1 0,  0.9 1];
pos_axes  = [0.05 0.05 0.90 0.90];
%190404 hT4_P2 = uipanel('FontSize',fontsizeis,'parent',hTab_2d_viewer,'Position',pos_panel);
hAx_2dprof_hcmenu = uicontextmenu;
uimenu(hAx_2dprof_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,6});
%
hAx_2Dprof = axes('Parent',H.PANELS{P.tab_id}.B,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position', pos_axes,'uicontextmenu',hAx_2dprof_hcmenu);
%%
%% TAB-4: ====================================================== Confidence
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
create_new_tab('Confidence');
%%set(H.TABS(P.tab_id),'ButtonDownFcn',{@CB_TAB_main_view_update})
%%     Panels
H.PANELS{P.tab_id}.A = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units', 'normalized','Position',Pnl.Lay0.A);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.A,'title','A');end
H.PANELS{P.tab_id}.B = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay0.B);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.B,'title','B');end
%
%%     Objets on panel A
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
%
objw = [0.1, 0.1,   0.75];
objx = [0.0, 0.1,   0.25];
row = 5;
hT5_PA_back = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','<<', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_conf_backX});
hT5_PA_next = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','>>', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_conf_nextX});
T5_P1_txtx = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'Units','normalized','Position',[objx(3), objy(row), objw(3), objh],'BackgroundColor', [1 1 1]);
%
row = row+1;
objw = [0.5, 0.5];
objx = [0, objw(1)];
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Parameter', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Layer', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%
row = row+2;
hconf_xprop = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'string',[' Vp'; ' Vs'; ' Ro'; ' H '; ' Qp'; ' Qs'; 'DAF']);
hconf_xlay = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%%      mouse over tips
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    % X-axis
    hoveoverstring = sprintf('Go to the previous location');
    set(hT5_PA_back,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Go to the next location');
    set(hT5_PA_next,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Station/Location being considered on the X-axis');
    set(T5_P1_txtx,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Elastic Property considered on the X-axis ');
    set(hconf_xprop,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Layer of the model considered on the X-axis ');
    set(hconf_xlay,'TooltipString',hoveoverstring)
end
%%    Panel-B: Y-axis Objects
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.B, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.B, G.main_object_levels );
objw = [0.1, 0.1,   0.75];
gapx = 1-sum(objw);
objx = [0, objw(1), (sum(objw(1:2)) + gapx)];
row = row+3;
%
hT5_PB_back = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','<<', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_conf_backY});
hT5_PB_next = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','>>', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_conf_nextY});
T5_P1_txty = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'Units','normalized','Position',[objx(3), objy(row), objw(3), objh],'BackgroundColor', [1 1 1]);
%
row = row+1;
objw = [0.5, 0.5];
objx = [0, objw(1)];
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Parameter', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Layer', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%
row = row+2;
hconf_yprop = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'string',[' Vp'; ' Vs'; ' Ro'; ' H '; ' Qp'; ' Qs'; 'DAF']);
hconf_ylay = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%%      mouse over tips
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    % Y-axis
    hoveoverstring = sprintf('Go to the previous location');
    set(hT5_PB_back,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Go to the next location');
    set(hT5_PB_next,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Station/Location being considered on the Y-axis');
    set(T5_P1_txty,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Elastic Property considered on the Y-axis');
    set(hconf_yprop,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Layer of the model considered on the Y-axis ');
    set(hconf_ylay,'TooltipString',hoveoverstring)
end
%%    Panel-C: more inputs
%
objw = [0.5, 0.5];
objx = [0, (objw(1))];
row = row+3;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Smoothing [0-6]', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
hconf_nsmooth = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A,'String','3', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','N of color levels', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
hconf_nlevels = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A,'String','30', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%
row = row+2;
hconf_upd = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','Pushbutton','parent',H.PANELS{P.tab_id}.A,'String','Update', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@confidence_update_misfit});
%%      mouse over tips
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    hoveoverstring = sprintf('Number of color levels');
    set(hconf_nlevels,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Decide the level of smoothing');
    set(hconf_nsmooth,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Replot');
    set(hconf_upd,'TooltipString',hoveoverstring)
end
%%    Panel-D: Confidence plot
%190404 pos_panel = [0.325 0.00,  (1-0.325) 1.00];
pos_axis  = [0.1 0.1 0.8 0.8];
%190404 hT5_PD = uipanel('FontSize',fontsizeis,'parent',hTab_Confidenc,'Units','normalized','Position',pos_panel);
hAx_cnf_hcmenu = uicontextmenu;
uimenu(hAx_cnf_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,7});
hAx_1d_confidence = axes('Parent',H.PANELS{P.tab_id}.B,'Units', 'normalized','Units','normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axis,'uicontextmenu',hAx_cnf_hcmenu);
%% TAB-5: ===================================================== Sensitivity
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
create_new_tab('Sensitivity');
%%set(H.TABS(P.tab_id),'ButtonDownFcn',{@CB_TAB_main_view_update})
%%     Panels
H.PANELS{P.tab_id}.A = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units', 'normalized','Position',Pnl.Lay0.A);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.A,'title','A');end
H.PANELS{P.tab_id}.B = uipanel('parent',H.TABS(P.tab_id),'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Units','normalized','Position',Pnl.Lay0.B);
if(strcmp(P.ExtraFeatures.tab_labels_enable_status,'on')); set(H.PANELS{P.tab_id}.B,'title','B');end
%%     Objets on panel A
objh = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_objh );
objy = get_normalheight_on_panel( H.PANELS{P.tab_id}.A, G.main_object_levels );
%
objw = [0.1, 0.1,   0.75];
objx = [0.0, 0.1,   0.25];
row = 5;
hT6_PA_back = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','<<', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@B_sns_back});
hT6_PA_next = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','pushbutton','parent',H.PANELS{P.tab_id}.A, ...
    'String','>>', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh], ...
    'Callback',{@B_sns_next});
T6_P1_txtx = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'Units','normalized','Position',[objx(3), objy(row), objw(3), objh],'BackgroundColor', [1 1 1]);
%
row = row+1;
objw = [0.5, 0.5];
gapx = 0.1;
objx = [0, objw(1)];
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Parameter', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Layer', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%
n = 5;
row = row+n;
hsns_xprop = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), n*objh], ...
    'string',[' Vp'; ' Vs'; ' Ro'; ' H '; ' Qp'; ' Qs']);
hsns_xlay = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','listbox','parent',H.PANELS{P.tab_id}.A, ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), n*objh]);
%
row = row+3;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Variation (%)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
hsns_bound = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A,'String','25', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
row = row+1;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','Step (%)', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
hsns_step = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A,'String','5', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);

%
row = row+3;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',H.PANELS{P.tab_id}.A,'String','N of color levels', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
hsns_nlevels = uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','edit','parent',H.PANELS{P.tab_id}.A,'String','20', ...
    'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
%
row = row+2;
uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','Pushbutton','parent',H.PANELS{P.tab_id}.A,'String','Update', ...
    'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], ...
    'Callback',{@sensitivity_update_misfit});
%%      mouse over tips
if strcmp(USER_PREFERENCE_Move_over_suggestions,'on')
    % X-axis
    hoveoverstring = sprintf('Go to the previous location');
    set(hT6_PA_back,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Go to the next location');
    set(hT6_PA_next,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Station/Location being considered');
    set(T6_P1_txtx,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Elastic Property considered');
    set(hsns_xprop,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Layer of the model considered');
    set(hsns_xlay,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Range of values around the current one\n to be considered (as percentage)');
    set(hsns_bound,'TooltipString',hoveoverstring)
    hoveoverstring = sprintf('Discretization step of the range ov values (as percentage)');
    set(hsns_step ,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Number of color levels');
    set(hsns_nlevels,'TooltipString',hoveoverstring)
    
    hoveoverstring = sprintf('Replot');
    set(hconf_upd,'TooltipString',hoveoverstring)
end
%%    Panel-B: curves
% pos_panel = [0.40 0.00,  0.60 1.00];
% pos_axis  = [0.1 0.1 0.8 0.8];
% hT6_PC = uipanel('FontSize',12,'parent',hTab_Sensitivt,'Units','normalized','Position',pos_panel);
% hAx_sns_hcmenu = uicontextmenu;
% uimenu(hAx_cnf_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,8});
% hAx_sensitivity = axes('Parent',hT6_PC,'Units', 'normalized','Units','normalized','Position',pos_axis,'uicontextmenu',hAx_cnf_hcmenu);
%%    Panel-C: Sensitivity plot
%190404 pos_panel = [0.325  0.0  (1-0.325) 1.0];% [0.00 0.65,  0.40 0.35];
pos_axis  = [0.1 0.1 0.8 0.8];
H.PANELS{P.tab_id}.B = uipanel('FontSize',USER_PREFERENCE_interface_objects_fontsize,'parent',H.PANELS{P.tab_id}.B,'Units','normalized','Position',pos_panel);
hAx_sns_hcmenu = uicontextmenu;
uimenu(hAx_sns_hcmenu, 'Label', 'Edit externally','Callback', {@plot_extern,8});
hAx_sensitivity = axes('Parent',H.PANELS{P.tab_id}.B,'Units', 'normalized','Units','normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',pos_axis,'uicontextmenu',hAx_sns_hcmenu);
%% Initializations before gui publication
%[fFS,FSraw]=FourierSpectrum(magn,delt,dept,rock); %Compute theoretical Fourier spectrum for target earthquake (see Setup)
[HQfreq, QHspec] = FourierSpectrum( HQMagnitude,  HQEpicDistance, HQFocalDepth, HQRockRatio);

% Menu selection
spunta(eh52_childs, smoothing_strategy);
%% Publish GUI and set history
working_folder = '';
last_project_name = 'OpenHVSR_Inv__project.m';
last_elaboration_name = 'OpenHVSR_Inv__Elaboration_main.mat';
last_log_number= 0;
if exist('history.m', 'file') == 2
history
end
% 
set(H.gui, 'MenuBar', 'none');
set(H.gui, 'ToolBar', 'none');
Pfunction__publish_gui(H.gui,H.menu.credits,P.appname_3D,P.appversion_3D);


%
%
%% ************************* GUI CALLBACKS ********************************
%%   MENU
%%      Files 
    function Menu_Project_Create(~,~,~)
        folder_name = uigetdir(working_folder,'Select working Folder for the project');
        if(folder_name)
            [SURVEYS,MODELS,datafile_separator,datafile_columns,nameof_reference_model_file1,nameof_reference_model_file2] = ...
                openhvsr_project_creator(USER_PREFERENCE_interface_objects_fontsize,folder_name, ...
                SURVEYS,MODELS,datafile_separator,datafile_columns);
            newprojectname = strcat(folder_name,'/project.m');
            fid = fopen(newprojectname,'w');

            fprintf(fid,'%% This is a project-file to input the program\n');
            fprintf(fid,'%% %s, %s\n',P.appname_3D,P.appversion_3D);
            fprintf(fid,'\n');
            fprintf(fid,'%% Determined how H/V files are read\n');
            fprintf(fid,'%% datafile_columns:   describes the columnwise structure of the data\n'); 
            fprintf(fid,'%%     [FREQUENCY column Id][HVSR Curve column Id][standard dev. Id]\n');
            fprintf(fid,'%% datafile_separator: in H/V curve files, is a string separator between HEADER and DATA\n');
            fprintf(fid,'datafile_separator = ''%s'';\n', datafile_separator);
            fprintf(fid,'datafile_columns   = [%d %d %d];\n',datafile_columns);
            fprintf(fid,'\n');
            fprintf(fid,'\n');
            fprintf(fid,'\n');
            fprintf(fid,'%% Collection of H/V curves to invert\n');
            Nsurveys = size(SURVEYS,1);
            if Nsurveys>0
                for ir = 1:Nsurveys
                    %[p,s,ext]=fileparts(SURVEYS{ir,2});
                    %fname = strcat(folder_name,'/',s,ext);% best position
                    %if()%check correct file position
                    %end
                    
                    is = num2str(ir);
                    stringline = strcat('SURVEYS{',is,',1} = [',num2str(SURVEYS{ir,1}(1)),', ',num2str(SURVEYS{ir,1}(2)),', ',num2str(SURVEYS{ir,1}(3)),'];\n');
                    fprintf(fid,stringline);
                    %fname = strcat(s,ext);
                    stringline = strcat('SURVEYS{',is,',2} = ''',SURVEYS{ir,2},''';\n');
                    fprintf(fid,stringline);
                end
                fprintf(fid,'\n');
                fprintf(fid,'\n');
                fprintf(fid,'%% Starting subsurface description\n');
                for ir = 1:Nsurveys
                    is = num2str(ir);
                    %fname = strcat(s,'_subsurface.txt');
                    stringline = strcat('MODELS{',is,',1} = ''',MODELS{ir,1},''';\n');
                    fprintf(fid,stringline);
                    stringline = strcat('MODELS{',is,',2} = ',num2str(MODELS{ir,2}),';\n');
                    fprintf(fid,stringline);
                end
            end
            fprintf(fid,'\n');
            fprintf(fid,'\n');
            %% check for reference models 
%             reference_model_file1 = strcat(folder_name,'/reference_model_dh.txt');
%             reference_model_file2 = strcat(folder_name,'/reference_model_xz.txt');
%             if(~isempty(REFERENCE_MODEL_dH))
%                 save(reference_model_file1,'REFERENCE_MODEL_dH','-ascii');
%             end
%             if(~isempty(REFERENCE_MODEL_zpoints))
%                 save(reference_model_file2,'REFERENCE_MODEL_zpoints','-ascii');
%             end
            fprintf(fid,'%% Describe if some reference model is present\n');
            fprintf(fid,'%% reference_model_file1   is defined following the same format of the input subsurface models\n');
            fprintf(fid,'%%                         i.e. depth is specified using layers thickness\n');
            fprintf(fid,'%% reference_model_file2:  is the depth is a true depth\n');
            fprintf(fid,strcat('reference_model_file1 = ''',nameof_reference_model_file1,''';\n'));
            fprintf(fid,strcat('reference_model_file2 = ''',nameof_reference_model_file2,''';\n'));
        end
    end
    
    function Menu_Project_Load(~,~,~)
        [file,thispath] = uigetfile('*.m','Load Project Script(.m)',strcat(working_folder,last_project_name) );
        if(file ~= 0)
            
            %% updating history
            working_folder = thispath;
            last_project_name = file;
            if get(H.menu.settings.log,'UserData')==1; last_log_number=last_log_number+1; end
            fid = fopen('history.m','w');
            fprintf(fid, 'working_folder = ''%s'';\n', working_folder);
            fprintf(fid, 'last_project_name = ''%s'';\n', last_project_name);
            fprintf(fid, 'last_elaboration_name = ''%s'';\n', last_elaboration_name);
            fprintf(fid, 'last_log_number = %d;\n', last_log_number);
            
            
            fclose(fid);            
			%% logging (temporarily commented)
% % %             today = date;
% % %             logfolder = strcat(working_folder,'logs');
% % %             if(~exist(logfolder,'dir'))% create log folder
% % %                 logfolder_exist = mkdir(logfolder);% 1 yes /0
% % %                 if(logfolder_exist==1); 
% % %                     fprintf('log folder created.\n'); 
% % %                 else
% % %                     fprintf('log folder creation failed.\n'); 
% % %                 end
% % %             else
% % %                 fprintf('log folder found.\n'); 
% % %             end
% % %             logname = strcat(working_folder,'logs/LOG_n',num2str(last_log_number),'_',P.appname_3D,'_',P.appversion_3D,'_',today,'.log');
% % %             set(0,'DiaryFile',logname)
% % %             diary(logname);
% % %             diary on;
% % %             fprintf('logging on %s\n',get(0,'DiaryFile'))            
            %% loading stuff
            scriptname = strcat(thispath,file);
            run(scriptname);
            %% will be loaded:
            % SURVEYS
            % MODELS
            %
            % Update_Setup_Tab();

            % load data files FDAT (Field DATa)
            FDAT = load_data2(working_folder,SURVEYS, datafile_columns,datafile_separator);
            if isempty(SURVEYS)% still empty
                warning('I was not able to load this project (empty SURVEYS). aborting...');
                fprintf('\n')
                return;
            end
            %% check the project is developed along X axis
            minx = SURVEYS{1}(1);
            maxx = SURVEYS{1}(1);
            miny = SURVEYS{1}(2);
            maxy = SURVEYS{1}(2);
            for ss = 1:size(SURVEYS,1)
                if SURVEYS{ss}(1)<minx; minx=SURVEYS{ss}(1); end
                if SURVEYS{ss}(1)>maxx; maxx=SURVEYS{ss}(1); end
                %
                if SURVEYS{ss}(2)<miny; miny=SURVEYS{ss}(2); end
                if SURVEYS{ss}(2)>maxy; maxy=SURVEYS{ss}(2); end
            end
            if minx==maxx && miny==maxy
		    fprintf('MESSAGE:  Seems that all measurements are located in the same point. Please check X-Y coordinated.\n')
		    fprintf('          Any image using interpolation will be disabled.\n')
		    fprintf('(pause, hit any key)\n')
		    pause
		    fprintf('\n')
		    fprintf('\n')
		    fprintf('\n')
		    set(hButtRF,'enable','off')
		    set(hButtVP,'enable','off')
		    set(hButtVS,'enable','off')
		    set(hButtRO,'enable','off')
		    set(hButtQS,'enable','off')
		    set(hButtQP,'enable','off')
		    
		    FLAG_enable_interpolated_images = 0;
            end
            %INIT_FDATS();

            % load subsurface starting models MDL (Field DATa)
            MDLS  = load_models(working_folder,SURVEYS,MODELS);
            
            %% init memory spaces
            INIT_tool_variables();
            %% pre-select location 1
            P.isshown.id = 1;
            
            %% update interface
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo)  
            Show_survey(0);
            %hold(hAx_1dprof,'off');
            draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);

        end
        %% check for reference models 
        reference_model_file1 = strcat(thispath,'reference_model_dh.txt');
        reference_model_file2 = strcat(thispath,'reference_model_xz.txt');
        if(exist(reference_model_file1,'file'))
            REFERENCE_MODEL_dH       = load(reference_model_file1,'-ascii');
        end
        if(exist(reference_model_file1,'file'))
            REFERENCE_MODEL_zpoints  = load(reference_model_file2,'-ascii');   
        end
    end
    function Menu_File_Set_file_format(~,~,~)
        prompt = {'Freq. column Id.','HVSR column Id.','Header/Data separator'};
        def = {num2str(datafile_columns(1)), ...
               num2str(datafile_columns(2)), ...
               datafile_separator};
        answer = inputdlg(prompt,'Set data-file format',1,def);
        if(~isempty(answer)) 
            datafile_columns(1) = str2double(answer{1});         
            datafile_columns(2) = str2double(answer{2});
            datafile_separator  = answer{3}; 
        end
    end

    function Menu_Model_Save_txt_set(~,~,~)
        folder_name = uigetdir(working_folder);
        if(folder_name)
            Nsurveys = size(SURVEYS,1);
            if Nsurveys>0
                for ii = 1:Nsurveys
                    [~,s,~]=fileparts(SURVEYS{ii,2});
                    fname = strcat(folder_name,'/',s,'_subsurface.txt');
                    dd = MDLS{ii};
                    save(fname,'dd','-ascii'); 
                end
            end
        end    
    end
    function Menu_Curve_Save_txt_set(~,~,~)
        folder_name = uigetdir(working_folder);
        if(folder_name)
            %modl_FDAT   = multiple_fwd_model();
            Nsurveys = size(SURVEYS,1);
            if Nsurveys>0
                if(~isempty(modl_FDAT))%%   P/S
                    for ii = 1:Nsurveys
                        [p,s,ext]=fileparts(SURVEYS{ii,2});
                        fname = strcat(folder_name,'/',s,'_sinthetic_hvsr_PS.txt');
                        dd = [modl_FDAT{ii,1},modl_FDAT{ii,2}];
                        save(fname,'dd','-ascii'); 
                    end
                end
            end 
            
        end
    end
    function Menu_Curve_Save_txt_set_sw(~,~,~)
        folder_name = uigetdir(working_folder);
        if(folder_name)
            %modl_FDATSW = multiple_fwd_model_sw();
            Nsurveys = size(SURVEYS,1);
            if Nsurveys>0
                if(~isempty(modl_FDATSW))%% SW
                    for ii = 1:Nsurveys
                        [p,s,ext]=fileparts(SURVEYS{ii,2});
                        fname = strcat(folder_name,'/',s,'_sinthetic_hvsr_SW.txt');
                        dd = [modl_FDATSW{ii,1},modl_FDATSW{ii,2}];
                        save(fname,'dd','-ascii'); 
                    end
                end
            end 
        end
    end
    function Menu_Save_as_newproject_set(~,~,~)
        folder_name = uigetdir(working_folder);
        if(folder_name)
            newprojectname = strcat(folder_name,'/project.m');
            fid = fopen(newprojectname,'w');

            fprintf(fid,'%% This is a project-file to input the program\n');
            fprintf(fid,'%% %s, %s\n',P.appname_3D,P.appversion_3D);
            fprintf(fid,'\n');
            fprintf(fid,'%% Determined how H/V files are read\n');
            fprintf(fid,'datafile_separator = ''%s'';\n', datafile_separator);
            fprintf(fid,'datafile_columns   = [%d %d %d];\n',datafile_columns);
            fprintf(fid,'\n');
            fprintf(fid,'\n');
            %modl_FDAT = multiple_fwd_model();
            
            Nsurveys = size(SURVEYS,1);
            if Nsurveys>0
                for ir = 1:Nsurveys
                    [~,s,ext]=fileparts(SURVEYS{ir,2});
                    fname = strcat(folder_name,'/',s,ext);
                    dd =[];
                    for ic = 1:size(FDAT,2)
                        dd = [dd,FDAT{ir,ic}];
                    end
                    save(fname,'dd','-ascii');
                    
                    
                    is = num2str(ir);
                    stringline = strcat('SURVEYS{',is,',1} = [',num2str(SURVEYS{ir,1}(1)),', ',num2str(SURVEYS{ir,1}(2)),', ',num2str(SURVEYS{ir,1}(3)),'];\n');
                    fprintf(fid,stringline);
                    %fname = strcat(s,'_sinthetic.txt');
                    %fname = SURVEYS{ir,2};
                    fname = strcat(s,ext);
                    stringline = strcat('SURVEYS{',is,',2} = ''',fname,''';\n');
                    fprintf(fid,stringline);
                end
                fprintf(fid,'\n');
                fprintf(fid,'\n');
                for ir = 1:Nsurveys
                    [~,s,~]=fileparts(SURVEYS{ir,2});
                    % model
                    fname = strcat(folder_name,'/',s,'_subsurface.txt');
                    dd = MDLS{ir};
                    save(fname,'dd','-ascii');
                    
                    is = num2str(ir);
                    fname = strcat(s,'_subsurface.txt');
                    stringline = strcat('MODELS{',is,',1} = ''',fname,''';\n');
                    fprintf(fid,stringline);
                    stringline = strcat('MODELS{',is,',2} = ',is,';\n');
                    fprintf(fid,stringline);
                end
            end
            fprintf(fid,'\n');
            fprintf(fid,'\n');
            %% check for reference models 
            reference_model_file1 = strcat(folder_name,'/reference_model_dh.txt');
            reference_model_file2 = strcat(folder_name,'/reference_model_xz.txt');
            if(~isempty(REFERENCE_MODEL_dH))
                save(reference_model_file1,'REFERENCE_MODEL_dH','-ascii');
            end
            if(~isempty(REFERENCE_MODEL_zpoints))
                save(reference_model_file2,'REFERENCE_MODEL_zpoints','-ascii');
            end
        end
    end

    function Menu_Save_elaboration(~,~,~)
        [file,thispath] =  uiputfile('*.mat','Save elaboration', strcat(working_folder,'Elaboration.mat'));
        %uigetfile('*.mat','Save Elaboration',strcat(working_folder,'/Elaboration.mat'));
        if(file ~= 0)
            OpenHVSR_elaboration_file_version = 2;% define which archive version is this
            
            ui_dist  = get(hRand,'Value');
            ui_hh_pc = get(h_hh_val, 'String');
            
            ui_vp_pc = get(h_vp_val, 'String');
            ui_vp_ww = get(h_vp_w,   'String');
            
            ui_vs_pc = get(h_vs_val, 'String');
            ui_vs_ww = get(h_vs_w,   'String');
            
            ui_ro_pc = get(h_ro_val, 'String');
            ui_ro_ww = get(h_ro_w,   'String');
            
            ui_qp_pc = get(h_qp_val, 'String');
            ui_qp_ww = get(h_qp_w,   'String');
            
            ui_qs_pc = get(h_qs_val, 'String');
            ui_qs_ww = get(h_qs_w,   'String');
            
            ui_ex    = get(h_ex_val, 'String');
            ui_fref  = get(h_fref_val, 'String');
            ui_frnge_1 = get(h_scale_min, 'String');
            ui_frnge_2 = get(h_scale_max, 'String');
            ui_frnge_d = get(h_dscale, 'String');

            datname = strcat(thispath,file);
            %save(datname);
                      save(datname, ...
  'OpenHVSR_elaboration_file_version', ...      
  ... % CHANGE 190404  ver 4.0.0: 'appname' -> P.appname_3D
  'file', ...
  'thispath', ...
  'ui_dist', ... 
  'ui_ex', ...   
  'ui_fref', ... 
  'ui_frnge_1', ...      
  'ui_frnge_2', ...      
  'ui_frnge_d', ...      
  'ui_hh_pc', ...        
  'ui_qp_pc', ...        
  'ui_qp_ww', ...        
  'ui_qs_pc', ...        
  'ui_qs_ww', ...        
  'ui_ro_pc', ...        
  'ui_ro_ww', ...        
  'ui_vp_pc', ...        
  'ui_vp_ww', ...        
  'ui_vs_pc', ...        
  'ui_vs_ww', ...        
  ... %  ---- gui_3D ----------------------------------------------------------------------------
  'BEST_ENERGIES', ...   
  'BEST_MISFITS', ...    
  'BEST_MODELS', ...     
  'BEST_SINGLE_MISFIT', ...  
  'BEST_SINGLE_MODELS', ...  
  'BREAKS', ...
  ... % Btn0                                                               
  'CW', ...
  'DISCARDS', ...            
  'DL', ...                  
  'DSP', ...                 
  'DW', ...                  
  'FDAT', ...                
  'FLAG__PC_features', ...   
  'HQEpicDistance', ...      
  'HQFocalDepth', ...        
  'HQMagnitude', ...         
  'HQRockRatio', ...         
  'HQfreq', ...              
  'LKT', ...                 
  'MDLS', ...                
  'MODELS', ...              
  'Matlab_Release', ...      
  'Misfit_curve_term_w', ... 
  'Misfit_slope_term_w', ... 
  'Misfit_vs_Iter', ...      
  'NresultsToKeep', ...      
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'Nrowa', ...               
  'QHspec', ...              
  'QPList', ... % (3D)
  'QSList', ... % (3D)
  'RCT', ...                 
  'REFERENCE_MODEL_dH', ...  
  'REFERENCE_MODEL_zpoints', ...    
  'ROList', ... % (3D)
  'SS', ...                          
  'SN_centralval', ...              
  'SN_dtamsf', ...                  
  'SN_parname', ...                 
  'SN_parscale', ...                
  'SN_xscale', ...                  
  'STORED_1d_daf_fits', ...         
  'STORED_1d_hh_fits', ...            
  'STORED_1d_qp_fits', ...            
  'STORED_1d_qs_fits', ...            
  'STORED_1d_ro_fits', ...            
  'STORED_1d_vp_fits', ...            
  'STORED_1d_vs_fits', ...            
  'STORED_2d_daf_fits', ...           
  'STORED_2d_hh_fits', ...            
  'STORED_2d_qp_fits', ...            
  'STORED_2d_qs_fits', ...            
  'STORED_2d_ro_fits', ...            
  'STORED_2d_vp_fits', ...            
  'STORED_2d_vs_fits', ...            
  'STORED_RESULTS_1d_misfit', ...     
  'STORED_RESULTS_2d_misfit', ...     
  'STORED_RESULTS_2d_misfit_profile', ...
  'SURVEYS', ...                         
  ... % Slider0     (3D)                                                       
  ... % Slider0b    (3D)                                                           
  ... % Slider1     (3D)                                                            
  ... % Slider1b    (3D)                                                           
  ... % Slider2     (3D)                                                            
  ... % Slider2b    (3D)                                                           
  ... % 'T2_P1_global_it_count', ...           
  ... % 'T2_P1_max_it', ...                    
  ... % 'T3_P1_inv', ...                       
  ... % 'T3_P1_invSW', ...                     
  ... % 'T3_P1_it_count', ...                  
  ... % 'T3_P1_max_it', ...                    
  ... % 'T3_P1_txt', ...                       
  ... % 'T3_p1_revert', ...
  ...                  
  ... % 'T5_P1_txtx', ...                    
  ... % 'T5_P1_txty', ...                    
  ... % 'T6_P1_txtx', ...                    
  'TO_INVERT', ...                     
  'VPList', ... % (3D)                     
  'VSList', ... % (3D)                            
  'X1', ...                            
  'X2', ...                            
  'ZZList', ... % (3D)                            
  ... % ans                           
  'basevalue', ...                     
  'basevaluew', ...                    
  'bedrock', ...                       
  'best_FDAT', ...                     
  ... % CHANGE 190404  ver 4.0.0: 'beta_stuff_enable_status' >> 'P.ExtraFeatures.beta_stuff_enable_status'     
  ...    
  'conf_1d_to_show_x', ...             
  'conf_1d_to_show_y', ...             
  'confidence_colormap', ...           
  'curve_plotmode', ...               
  'curve_weights_plotmode', ...       
  'cutplanes', ... % (3D)                         
  ... % CHANGE 190404  ver 4.0.0: 'data_1d_to_show' >> 'P.isshown.id', ...              
  'datafile_columns', ...             
  'datafile_separator', ...           
  'default_colormap', ...             
  'depth_weights_plotmode', ...       
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'dh', ...
  'dim', ... % (3D)                               
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'dw', ...                           
  'dx', ...                           
  ... % %   'eh52', ...                     
  ... % %   'eh52_childs', ...              
  ... % 180323  'enable_menu', ...                  
  ... % 180323  'fontsizeis', ...                   
  'gapx', ...                         
  'global_inversion_step', ...      
  ... % %   h0                                                         
  ... % %   h1                                                         
  ... % %   h10                                                        
  ... % %   h5                                                         
  ... % %   h51                                                        
  ... % %   h52                                                        
  ... % %   h5_1                                                       
  ... % %   h7                                                         
  ... % %   hAx_1d_confidence                                          
  ... % %   hAx_1dprof                                                 
  ... % %   hAx_1dprof_hcmenu                                          
  ... % %   hAx_2Dprof                                                 
  ... % %   hAx_2dprof_hcmenu                                          
  ... % %   hAx_MvsIT                                                  
  ... % %   hAx_MvsIT_hcmenu                                           
  ... % %   hAx_cnf_hcmenu                                             
  ... % %   hAx_cwf                                                    
  ... % %   hAx_cwf_hcmenu                                             
  ... % %   hAx_dat                                                    
  ... % %   hAx_dat_hcmenu                                             
  ... % %   hAx_dwf                                                    
  ... % %   hAx_dwf_hcmenu                                             
  ... % %   hAx_geo                                                    
  ... % %   hAx_geo_hcmenu                                             
  ... % %   hAx_sensitivity                                            
  ... % %   hAx_sns_hcmenu                                             
  ... % %   hRand                                                      
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.D                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   H.PANELS{P.tab_id}.A                                                     
  ... % %   H.PANELS{P.tab_id}.B                                                     
  ... % %   hTabGroup                                                  
  ... % %   hTab_1d_viewer                                             
  ... % %   hTab_2d_viewer                                             
  ... % %   hTab_Confidenc                                             
  ... % %   hTab_Inversion                                             
  ... % %   H.PANELS{P.tab_id}.B                                             
  ... % %   hTab_mod                                                   
  ... % %   hTab_mod_cnames                                    
  ... % %   hTab_mod_hcmenu                                            
  ... % %   h_1d_next                                                  
  ... % %   h_1d_prev                                                  
  ... % %   h_dscale                                                   
  ... % %   h_ex_val                                                   
  ... % %   h_fref_val                                                 
  ... % %   h_fwd_sw                                                   
  ... % %   H.gui                                                      
  ... % %   h_hh_val                                                   
  ... % %   h_qp_val                                                   
  ... % %   h_qp_w                                                     
  ... % %   h_qs_val                                                   
  ... % %   h_qs_w                                                     
  ... % %   h_realtime                                                 
  ... % %   h_ro_val                                                   
  ... % %   h_ro_w                                                     
  ... % %   h_scale_max                                                
  ... % %   h_scale_min
  ... % %   h_view_rotation       (3D)
  ... % %   h_vp_val                                                   
  ... % %   h_vp_w                                                     
  ... % %   h_vs_val                                                   
  ... % %   h_vs_w                                                     
  ... % %   hconf_nlevels                                              
  ... % %   hconf_nsmooth                                              
  ... % %   hconf_xlay                                                 
  ... % %   hconf_xprop                                                
  ... % %   hconf_ylay                                                 
  ... % %   hconf_yprop                                                
  ... % %   hsns_bound                                                 
  ... % %   hsns_nlevels                                               
  ... % %   hsns_step                                                  
  ... % %   hsns_xlay                                                  
  ... % %   hsns_xprop                                                 
  'i', ...                                                         
  'id', ...                                     
  'independent_optimiazation_cicles', ...       
  'init_single_FDAT', ...                       
  'init_value__dscale', ...                     
  'init_value__fref', ...                       
  'init_value__max_scale', ...                  
  'init_value__min_scale', ...                  
  'ixmax_id', ...                                                   
  'ixmin_id', ...                                                   
  'last_FDAT', ...                              
  'last_MDLS', ...                              
  'last_log_number', ...                                            
  'last_project_name', ...                      
  'last_single_FDAT', ...                       
  'last_single_MDL', ...                        
  'lsmooth', ...                                                    
  ... % NOT NEDEED 4.0.0:  'main_b', ...                                                     
  ... % NOT NEDEED 4.0.0:  'main_h', ...                                                    
  ... % NOT NEDEED 4.0.0:  'main_l', ...                                                     
  'main_scale', ...                             
  ... % NOT NEDEED 4.0.0:  'main_w', ...                                                     
  'max_H', ...                                                      
  'max_lat_dH', ...                                                 
  'max_lat_dQp', ...                                                
  'max_lat_dQs', ...                                                
  'max_lat_dRo', ...                                                
  'max_lat_dVp', ...                                                
  'max_lat_dVs', ...                                                
  'max_qp_qs_ratio', ...                                            
  'max_qs', ...                                                     
  'max_ro', ...                                                     
  'max_vp_vs_ratio', ...                                            
  'min_H', ...                                                      
  'min_qp_qs_ratio', ...                                            
  'min_qs', ...                                                     
  'min_ro', ...                                                     
  'min_vp_vs_ratio', ...                                            
  'min_vs', ...                                                     
  'misfit_over_sumweight', ...             
  'modl_FDAT', ...                                                    
  'modl_FDATSW', ...                                                  
  'n', ...                                                          
  'n_depth_levels', ...                                             
  'ndegfree', ...                                                   
  'nlaya', ...                                                      
  'nlayb', ...                                                      
  'nlvl', ...                                                       
  'nx_ticks', ...
  'ny_ticks', ...                                %(3D)                                                           
  'nz_ticks', ...                                                   
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'objh', ...                                                       
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'objn', ...                                                       
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'objw', ...                                                       
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'objx', ...                                                       
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'objy', ...                              
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'pos_axes', ...                                                   
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'pos_axes2', ...                                                  
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'pos_axis', ...                                                   
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'pos_panel', ...                                                  
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'pos_table', ...                                                  
  'poten', ...                                                     
  'prev_BEST_SINGLE_MISFIT', ...           
  'prev_BEST_SINGLE_MODELS', ...                                      
  'prev_MDLS', ...                                                    
  'prev_best_FDAT', ...                                               
  'prev_single_it', ...
  ...% CHANGE 190404  ver 4.0.0: 'profile_ids', ... % (3D)        is in P                                                
  ...% CHANGE 190404  ver 4.0.0:  'profile_line', ... % (3D)       is in P                                                
  'property_1d_to_show', ...                                        
  'property_23d_to_show', ...     %(3D)
  ...% CHANGE 190404  ver 4.0.0:  'r_distance_from_profile', ...  %(3D)  no more, or in P
  'r_reciprocicity', ...          %(3D)
  'receiver_locations', ...       %(3D)
  ... % CHANGE 190404  ver 4.0.0: NOT SAVED ANYMORE (USELESS): 'row', ...
  'sensitivity_colormap', ...               
  'smoothing_radius', ...                                           
  'smoothing_strategy', ...                                         
  'sns_1d_to_show', ...                                             
  ... % CHANGE 190404  ver 4.0.0: 'str', ...   NOT SAVED ANYMORE                             
  'sw_nmodes', ...                                                  
  'sw_nsmooth', ...                                                 
  'vala', ...                                                       
  'valb', ...                                                       
  'var1', ...                                                       
  'var2', ...                                                       
  ...% CHANGE 190404  ver 4.0.0:  'version' -> P.appversion_3D                             
  'vfst_MDLS', ...                                                    
  'view_max_scale', ...                                             
  'view_min_scale', ...
  'viewerview', ...                              %(3D)
  'weight_curv', ...                          
  'weight_dpth', ...                          
  'working_folder', ...                       
  'x', ...                                                          
  'xpositions', ...                           
  'zlevels', ...
  'inversion_is_started__inedipendent', ...%                               From version 3.0.0
  'inversion_is_started__global', ...%                                     From version 3.0.0
  'P', ...%                                                                   From version 4.0.0
  'Misfit_vs_Iter_MULPTIPLE_local', ...
  'Misfit_vs_Iter_MULPTIPLE', ...
  'best_MISFIT_by_location');

            fprintf('[Elaboration saved]\n')
        end
    end
    function Menu_Load_elaboration(~,~,~)
        [file,thispath] = uigetfile('*.mat','Resume Elaboration',strcat(working_folder,'/Elaboration.mat'));
        if(file ~= 0)
            datname = strcat(thispath,file);           
            BIN = load(datname, '-mat');%% load the store data
            
            %% Data archive version I:(first pubblication to version 3.0.0) 
            if ~isfield(BIN,'OpenHVSR_elaboration_file_version')
                fprintf('Loading archive version-I: (Up to V3.0.0)\n')
                %% if isfield(BIN,'');  = BIN.; end
                if isfield(BIN,'file'); file = BIN.file; end
                if isfield(BIN,'thispath'); thispath = BIN.thispath; end
                
                %   ---- gui_3D ----------------------------------------------------------------------------
                if isfield(BIN,'BEST_ENERGIES'); BEST_ENERGIES = BIN.BEST_ENERGIES; end
                if isfield(BIN,'BEST_MISFITS'); BEST_MISFITS = BIN.BEST_MISFITS; end
                if isfield(BIN,'BEST_MODELS'); BEST_MODELS = BIN.BEST_MODELS; end
                if isfield(BIN,'BEST_SINGLE_MISFIT'); BEST_SINGLE_MISFIT = BIN.BEST_SINGLE_MISFIT; end
                if isfield(BIN,'BEST_SINGLE_MODELS'); BEST_SINGLE_MODELS = BIN.BEST_SINGLE_MODELS; end
                if isfield(BIN,'BREAKS'); BREAKS = BIN.BREAKS; end
                %
                if isfield(BIN,'CW'); CW = BIN.CW; end
                if isfield(BIN,'DISCARDS'); DISCARDS = BIN.DISCARDS; end
                if isfield(BIN,'DL'); DL = BIN.DL; end
                if isfield(BIN,'DSP'); DSP = BIN.DSP; end
                if isfield(BIN,'DW'); DW = BIN.DW; end
                if isfield(BIN,'FDAT'); FDAT = BIN.FDAT; end
                if isfield(BIN,'FLAG__PC_features'); FLAG__PC_features = BIN.FLAG__PC_features; end
                if isfield(BIN,'HQEpicDistance'); HQEpicDistance = BIN.HQEpicDistance; end
                if isfield(BIN,'HQFocalDepth'); HQFocalDepth = BIN.HQFocalDepth; end
                if isfield(BIN,'HQMagnitude'); HQMagnitude = BIN.HQMagnitude; end
                if isfield(BIN,'HQRockRatio'); HQRockRatio = BIN.HQRockRatio; end
                if isfield(BIN,'HQfreq'); HQfreq = BIN.HQfreq; end
                if isfield(BIN,'LKT'); LKT = BIN.LKT; end
                if isfield(BIN,'MDLS'); MDLS = BIN.MDLS; end
                if isfield(BIN,'MODELS'); MODELS = BIN.MODELS; end
                if isfield(BIN,'Matlab_Release'); Matlab_Release = BIN.Matlab_Release; end
                if isfield(BIN,'Misfit_curve_term_w'); Misfit_curve_term_w = BIN.Misfit_curve_term_w; end
                if isfield(BIN,'Misfit_slope_term_w'); Misfit_slope_term_w = BIN.Misfit_slope_term_w; end
                if isfield(BIN,'Misfit_vs_Iter'); Misfit_vs_Iter = BIN.Misfit_vs_Iter; end
                if isfield(BIN,'NresultsToKeep'); NresultsToKeep = BIN.NresultsToKeep; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'Nrowa'); Nrowa = BIN.Nrowa; end
                if isfield(BIN,'QHspec'); QHspec = BIN.QHspec; end
                if isfield(BIN,'QPList'); QPList = BIN.QPList; end % (3D)
                if isfield(BIN,'QSList'); QSList = BIN.QSList; end % (3D)
                if isfield(BIN,'RCT'); RCT = BIN.RCT; end
                if isfield(BIN,'REFERENCE_MODEL_dH'); REFERENCE_MODEL_dH = BIN.REFERENCE_MODEL_dH; end
                if isfield(BIN,'REFERENCE_MODEL_zpoints'); REFERENCE_MODEL_zpoints = BIN.REFERENCE_MODEL_zpoints; end
                if isfield(BIN,'ROList'); ROList = BIN.ROList; end
                if isfield(BIN,'S'); SS = BIN.S; end% 190410 compatibility 4.0.0
                if isfield(BIN,'SN_centralval'); SN_centralval = BIN.SN_centralval; end
                if isfield(BIN,'SN_dtamsf'); SN_dtamsf = BIN.SN_dtamsf; end
                if isfield(BIN,'SN_parname'); SN_parname = BIN.SN_parname; end
                if isfield(BIN,'SN_parscale'); SN_parscale = BIN.SN_parscale; end
                if isfield(BIN,'SN_xscale'); SN_xscale = BIN.SN_xscale; end
                if isfield(BIN,'STORED_1d_daf_fits'); STORED_1d_daf_fits = BIN.STORED_1d_daf_fits; end
                if isfield(BIN,'STORED_1d_hh_fits'); STORED_1d_hh_fits = BIN.STORED_1d_hh_fits; end
                if isfield(BIN,'STORED_1d_qp_fits'); STORED_1d_qp_fits = BIN.STORED_1d_qp_fits; end
                if isfield(BIN,'STORED_1d_qs_fits'); STORED_1d_qs_fits = BIN.STORED_1d_qs_fits; end
                if isfield(BIN,'STORED_1d_ro_fits'); STORED_1d_ro_fits = BIN.STORED_1d_ro_fits; end
                if isfield(BIN,'STORED_1d_vp_fits'); STORED_1d_vp_fits = BIN.STORED_1d_vp_fits; end
                if isfield(BIN,'STORED_1d_vs_fits'); STORED_1d_vs_fits = BIN.STORED_1d_vs_fits; end
                if isfield(BIN,'STORED_2d_daf_fits'); STORED_2d_daf_fits = BIN.STORED_2d_daf_fits; end
                if isfield(BIN,'STORED_2d_hh_fits'); STORED_2d_hh_fits = BIN.STORED_2d_hh_fits; end
                if isfield(BIN,'STORED_2d_qp_fits'); STORED_2d_qp_fits = BIN.STORED_2d_qp_fits; end
                if isfield(BIN,'STORED_2d_qs_fits'); STORED_2d_qs_fits = BIN.STORED_2d_qs_fits; end
                if isfield(BIN,'STORED_2d_ro_fits'); STORED_2d_ro_fits = BIN.STORED_2d_ro_fits; end
                if isfield(BIN,'STORED_2d_vp_fits'); STORED_2d_vp_fits = BIN.STORED_2d_vp_fits; end
                if isfield(BIN,'STORED_2d_vs_fits'); STORED_2d_vs_fits = BIN.STORED_2d_vs_fits; end
                if isfield(BIN,'STORED_RESULTS_1d_misfit'); STORED_RESULTS_1d_misfit = BIN.STORED_RESULTS_1d_misfit; end
                if isfield(BIN,'STORED_RESULTS_2d_misfit'); STORED_RESULTS_2d_misfit = BIN.STORED_RESULTS_2d_misfit; end
                if isfield(BIN,'STORED_RESULTS_2d_misfit_profile'); STORED_RESULTS_2d_misfit_profile = BIN.STORED_RESULTS_2d_misfit_profile; end
                if isfield(BIN,'SURVEYS'); SURVEYS = BIN.SURVEYS; end
                % NO Slider0     (3D)                                                       
                % NO Slider0b    (3D)                                                           
                % NO Slider1     (3D)                                                            
                % NO Slider1b    (3D)                                                           
                % NO Slider2     (3D)                                                            
                % NO Slider2b    (3D)
                % NO  if isfield(BIN,'T2_P1_global_it_count'); T2_P1_global_it_count = BIN.T2_P1_global_it_count; end
                % NO  if isfield(BIN,'T2_P1_max_it'); T2_P1_max_it = BIN.T2_P1_max_it; end
                % NO  if isfield(BIN,'T3_P1_inv'); T3_P1_inv = BIN.T3_P1_inv; end
                % NO  if isfield(BIN,'T3_P1_invSW'); T3_P1_invSW = BIN.T3_P1_invSW; end
                % NO  if isfield(BIN,'T3_P1_it_count'); T3_P1_it_count = BIN.T3_P1_it_count; end
                % NO  if isfield(BIN,'T3_P1_max_it'); T3_P1_max_it = BIN.T3_P1_max_it; end
                % NO  if isfield(BIN,'T3_P1_txt'); T3_P1_txt = BIN.T3_P1_txt; end
                % NO  if isfield(BIN,'T3_p1_revert'); T3_p1_revert = BIN.T3_p1_revert; end
                % NO  if isfield(BIN,'T5_P1_HsMask'); T5_P1_HsMask = BIN.T5_P1_HsMask; end
                % NO  if isfield(BIN,'T5_P1_txtx'); T5_P1_txtx = BIN.T5_P1_txtx; end
                % NO  if isfield(BIN,'T5_P1_txty'); T5_P1_txty = BIN.T5_P1_txty; end
                % NO  if isfield(BIN,'T6_P1_txtx'); T6_P1_txtx = BIN.T6_P1_txtx; end
                if isfield(BIN,'TO_INVERT'); TO_INVERT = BIN.TO_INVERT; end
                if isfield(BIN,'VPList'); VPList = BIN.VPList; end % (3D)
                if isfield(BIN,'VSList'); VSList = BIN.VSList; end % (3D)
                if isfield(BIN,'X1'); X1 = BIN.X1; end
                if isfield(BIN,'X2'); X2 = BIN.X2; end
                if isfield(BIN,'ZZList'); ZZList = BIN.ZZList; end % (3D)
                % NO  if isfield(BIN,'ans'); ans = BIN.ans; end
x               %190404  if isfield(BIN,'appname'); appname = BIN.appname; end
                if isfield(BIN,'basevalue'); basevalue = BIN.basevalue; end
                if isfield(BIN,'basevaluew'); basevaluew = BIN.basevaluew; end
                if isfield(BIN,'bedrock'); bedrock = BIN.bedrock; end
                if isfield(BIN,'best_FDAT'); best_FDAT = BIN.best_FDAT; end
                %190404 if isfield(BIN,'beta_stuff_enable_status'); beta_stuff_enable_status = BIN.beta_stuff_enable_status; end
                if isfield(BIN,'P.ExtraFeatures.beta_stuff_enable_status'); P.ExtraFeatures.beta_stuff_enable_status = BIN.P.ExtraFeatures.beta_stuff_enable_status; end
                %  (2D)
                if isfield(BIN,'conf_1d_to_show_x'); conf_1d_to_show_x = BIN.conf_1d_to_show_x; end
                if isfield(BIN,'conf_1d_to_show_y'); conf_1d_to_show_y = BIN.conf_1d_to_show_y; end
                if isfield(BIN,'confidence_colormap'); confidence_colormap = BIN.confidence_colormap; end
                if isfield(BIN,'curve_plotmode'); curve_plotmode = BIN.curve_plotmode; end
                if isfield(BIN,'curve_weights_plotmode'); curve_weights_plotmode = BIN.curve_weights_plotmode; end
                %% FIX if isfield(BIN,'P.isshown.id'); P.isshown.id = BIN.P.isshown.id; end
                %190404 if isfield(BIN,'data_1d_to_show'); data_1d_to_show = BIN.data_1d_to_show; end
                %    cutplanes (load no need)
                if isfield(BIN,'datafile_columns'); datafile_columns = BIN.datafile_columns; end
                if isfield(BIN,'datafile_separator'); datafile_separator = BIN.datafile_separator; end
                if isfield(BIN,'default_colormap'); default_colormap = BIN.default_colormap; end
                if isfield(BIN,'depth_weights_plotmode'); depth_weights_plotmode = BIN.depth_weights_plotmode; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'dh'); dh = BIN.dh; end
                if isfield(BIN,'dim'); dim = BIN.dim; end % (3D)
                % NOT NEDEED 4.0.0:  if isfield(BIN,'dw'); dw = BIN.dw; end
                if isfield(BIN,'dx'); dx = BIN.dx; end
                % NO  if isfield(BIN,'eh52'); eh52 = BIN.eh52; end
                % NO  if isfield(BIN,'eh52_childs'); eh52_childs = BIN.eh52_childs; end
                % 180323  if isfield(BIN,'enable_menu'); enable_menu = BIN.enable_menu; end
                % 180323  if isfield(BIN,'fontsizeis'); fontsizeis = BIN.fontsizeis; end
                if isfield(BIN,'gapx'); gapx = BIN.gapx; end
                if isfield(BIN,'global_inversion_step'); global_inversion_step = BIN.global_inversion_step; end
                % %   h0                                                         
                % %   h1                                                         
                % %   h10                                                        
                % %   h5                                                         
                % %   h51                                                        
                % %   h52                                                        
                % %   h5_1                                                       
                % %   h7                                                         
                % %   hAx_1d_confidence                                          
                % %   hAx_1dprof                                                 
                % %   hAx_1dprof_hcmenu                                          
                % %   hAx_2Dprof                                                 
                % %   hAx_2dprof_hcmenu                                          
                % %   hAx_MvsIT                                                  
                % %   hAx_MvsIT_hcmenu                                           
                % %   hAx_cnf_hcmenu                                             
                % %   hAx_cwf                                                    
                % %   hAx_cwf_hcmenu                                             
                % %   hAx_dat                                                    
                % %   hAx_dat_hcmenu                                             
                % %   hAx_dwf                                                    
                % %   hAx_dwf_hcmenu                                             
                % %   hAx_geo                                                    
                % %   hAx_geo_hcmenu                                             
                % %   hAx_sensitivity                                            
                % %   hAx_sns_hcmenu                                             
                % %   hRand                                                      
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.D                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   hTabGroup                                                  
                % %   hTab_1d_viewer                                             
                % %   hTab_2d_viewer                                             
                % %   hTab_Confidenc                                             
                % %   hTab_Inversion                                             
                % %   H.PANELS{P.tab_id}.B                                             
                % %   hTab_mod                                                   
                % %   hTab_mod_cnames                                    
                % %   hTab_mod_hcmenu                                            
                % %   h_1d_next                                                  
                % %   h_1d_prev                                                  
                % %   h_dscale                                                   
                % %   h_ex_val                                                   
                % %   h_fref_val                                                 
                % %   h_fwd_sw                                                   
                % %   H.gui                                                      
                % %   h_hh_val                                                   
                % %   h_qp_val                                                   
                % %   h_qp_w                                                     
                % %   h_qs_val                                                   
                % %   h_qs_w                                                     
                % %   h_realtime                                                 
                % %   h_ro_val                                                   
                % %   h_ro_w                                                     
                % %   h_scale_max                                                
                % %   h_scale_min
                % %   h_view_rotation       (3D)
                % %   h_vp_val                                                   
                % %   h_vp_w                                                     
                % %   h_vs_val                                                   
                % %   h_vs_w                                                     
                % %   hconf_nlevels                                              
                % %   hconf_nsmooth                                              
                % %   hconf_xlay                                                 
                % %   hconf_xprop                                                
                % %   hconf_ylay                                                 
                % %   hconf_yprop                                                
                % %   hsns_bound                                                 
                % %   hsns_nlevels                                               
                % %   hsns_step                                                  
                % %   hsns_xlay                                                  
                % %   hsns_xprop                                                 
                if isfield(BIN,'i'); i = BIN.i; end
                if isfield(BIN,'id'); id = BIN.id; end
                if isfield(BIN,'independent_optimiazation_cicles'); independent_optimiazation_cicles = BIN.independent_optimiazation_cicles; end
                if isfield(BIN,'init_single_FDAT'); init_single_FDAT = BIN.init_single_FDAT; end
                if isfield(BIN,'init_value__dscale'); init_value__dscale = BIN.init_value__dscale; end
                if isfield(BIN,'init_value__fref'); init_value__fref = BIN.init_value__fref; end
                if isfield(BIN,'init_value__max_scale'); init_value__max_scale = BIN.init_value__max_scale; end
                if isfield(BIN,'init_value__min_scale'); init_value__min_scale = BIN.init_value__min_scale; end
                if isfield(BIN,'ixmax_id'); ixmax_id = BIN.ixmax_id; end
                if isfield(BIN,'ixmin_id'); ixmin_id = BIN.ixmin_id; end
                if isfield(BIN,'last_FDAT'); last_FDAT = BIN.last_FDAT; end
                if isfield(BIN,'last_MDLS'); last_MDLS = BIN.last_MDLS; end
                if isfield(BIN,'last_log_number'); last_log_number = BIN.last_log_number; end
                if isfield(BIN,'last_project_name'); last_project_name = BIN.last_project_name; end
                if isfield(BIN,'last_single_FDAT'); last_single_FDAT = BIN.last_single_FDAT; end
                if isfield(BIN,'last_single_MDL'); last_single_MDL = BIN.last_single_MDL; end
                if isfield(BIN,'lsmooth'); lsmooth = BIN.lsmooth; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_b'); main_b = BIN.main_b; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_h'); main_h = BIN.main_h; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_l'); main_l = BIN.main_l; end
                if isfield(BIN,'main_scale'); main_scale = BIN.main_scale; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_w'); main_w = BIN.main_w; end
                if isfield(BIN,'max_H'); max_H = BIN.max_H; end
                if isfield(BIN,'max_lat_dH'); max_lat_dH = BIN.max_lat_dH; end
                if isfield(BIN,'max_lat_dQp'); max_lat_dQp = BIN.max_lat_dQp; end
                if isfield(BIN,'max_lat_dQs'); max_lat_dQs = BIN.max_lat_dQs; end
                if isfield(BIN,'max_lat_dRo'); max_lat_dRo = BIN.max_lat_dRo; end
                if isfield(BIN,'max_lat_dVp'); max_lat_dVp = BIN.max_lat_dVp; end
                if isfield(BIN,'max_lat_dVs'); max_lat_dVs = BIN.max_lat_dVs; end
                if isfield(BIN,'max_qp_qs_ratio'); max_qp_qs_ratio = BIN.max_qp_qs_ratio; end
                if isfield(BIN,'max_qs'); max_qs = BIN.max_qs; end
                if isfield(BIN,'max_ro'); max_ro = BIN.max_ro; end
                if isfield(BIN,'max_vp_vs_ratio'); max_vp_vs_ratio = BIN.max_vp_vs_ratio; end
                if isfield(BIN,'min_H'); min_H = BIN.min_H; end
                if isfield(BIN,'min_qp_qs_ratio'); min_qp_qs_ratio = BIN.min_qp_qs_ratio; end
                if isfield(BIN,'min_qs'); min_qs = BIN.min_qs; end
                if isfield(BIN,'min_ro'); min_ro = BIN.min_ro; end
                if isfield(BIN,'min_vp_vs_ratio'); min_vp_vs_ratio = BIN.min_vp_vs_ratio; end
                if isfield(BIN,'min_vs'); min_vs = BIN.min_vs; end
                if isfield(BIN,'misfit_over_sumweight'); misfit_over_sumweight = BIN.misfit_over_sumweight; end
                if isfield(BIN,'modl_FDAT'); modl_FDAT = BIN.modl_FDAT; end
                if isfield(BIN,'modl_FDATSW'); modl_FDATSW = BIN.modl_FDATSW; end
                if isfield(BIN,'n'); n = BIN.n; end
                if isfield(BIN,'n_depth_levels'); n_depth_levels = BIN.n_depth_levels; end
                if isfield(BIN,'ndegfree'); ndegfree = BIN.ndegfree; end
                if isfield(BIN,'nlaya'); nlaya = BIN.nlaya; end
                if isfield(BIN,'nlayb'); nlayb = BIN.nlayb; end
                if isfield(BIN,'nlvl'); nlvl = BIN.nlvl; end
                if isfield(BIN,'nx_ticks'); nx_ticks = BIN.nx_ticks; end
                if isfield(BIN,'ny_ticks'); ny_ticks = BIN.ny_ticks; end
                if isfield(BIN,'nz_ticks'); nz_ticks = BIN.nz_ticks; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objh'); objh = BIN.objh; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objn'); objn = BIN.objn; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objw'); objw = BIN.objw; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objx'); objx = BIN.objx; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objy'); objy = BIN.objy; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_axes'); pos_axes = BIN.pos_axes; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_axes2'); pos_axes2 = BIN.pos_axes2; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_axis'); pos_axis = BIN.pos_axis; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_panel'); pos_panel = BIN.pos_panel; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_table'); pos_table = BIN.pos_table; end
                if isfield(BIN,'poten'); poten = BIN.poten; end
                if isfield(BIN,'prev_BEST_SINGLE_MISFIT'); prev_BEST_SINGLE_MISFIT = BIN.prev_BEST_SINGLE_MISFIT; end
                if isfield(BIN,'prev_BEST_SINGLE_MODELS'); prev_BEST_SINGLE_MODELS = BIN.prev_BEST_SINGLE_MODELS; end
                if isfield(BIN,'prev_MDLS'); prev_MDLS = BIN.prev_MDLS; end
                if isfield(BIN,'prev_best_FDAT'); prev_best_FDAT = BIN.prev_best_FDAT; end
                if isfield(BIN,'prev_single_it'); prev_single_it = BIN.prev_single_it; end
                % SEE COMPATIBILITY PATCH 4.0.0:  if isfield(BIN,'profile_ids');  profile_ids = BIN.profile_ids; end% (3D)                                                        
                % SEE COMPATIBILITY PATCH 4.0.0:  if isfield(BIN,'profile_line'); profile_line= BIN.profile_line; end% (3D) 
                if isfield(BIN,'property_1d_to_show'); property_1d_to_show = BIN.property_1d_to_show; end
                if isfield(BIN,'property_23d_to_show'); property_23d_to_show = BIN.property_23d_to_show; end% (3D)
                % NOT NEDEED 4.0.0:  if isfield(BIN,'r_distance_from_profile')  r_distance_from_profile= BIN.r_distance_from_profile; end % (3D)
                if isfield(BIN,'r_reciprocicity');         r_reciprocicity= BIN.r_reciprocicity; end % (3D)
                if isfield(BIN,'receiver_locations');      receiver_locations= BIN.receiver_locations; end % (3D)
                % NOT NEDEED 4.0.0:  if isfield(BIN,'row'); row = BIN.row; end
                if isfield(BIN,'sensitivity_colormap'); sensitivity_colormap = BIN.sensitivity_colormap; end
                if isfield(BIN,'smoothing_radius'); smoothing_radius = BIN.smoothing_radius; end
                if isfield(BIN,'smoothing_strategy'); smoothing_strategy = BIN.smoothing_strategy; end
                if isfield(BIN,'sns_1d_to_show'); sns_1d_to_show = BIN.sns_1d_to_show; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'str'); str = BIN.str; end
                if isfield(BIN,'sw_nmodes'); sw_nmodes = BIN.sw_nmodes; end
                if isfield(BIN,'sw_nsmooth'); sw_nsmooth = BIN.sw_nsmooth; end
                if isfield(BIN,'vala'); vala = BIN.vala; end
                if isfield(BIN,'valb'); valb = BIN.valb; end
                if isfield(BIN,'var1'); var1 = BIN.var1; end
                if isfield(BIN,'var2'); var2 = BIN.var2; end
                %190404 if isfield(BIN,'version'); version = BIN.version; end
                if isfield(BIN,'vfst_MDLS'); vfst_MDLS = BIN.vfst_MDLS; end
                if isfield(BIN,'view_max_scale'); view_max_scale = BIN.view_max_scale; end
                if isfield(BIN,'view_min_scale'); view_min_scale = BIN.view_min_scale; end
                if isfield(BIN,'viewerview');     viewerview = BIN.viewerview; end  %(3D)
                if isfield(BIN,'weight_curv');    weight_curv = BIN.weight_curv; end
                if isfield(BIN,'weight_dpth');    weight_dpth = BIN.weight_dpth; end
                if isfield(BIN,'working_folder'); working_folder = BIN.working_folder; end
                if isfield(BIN,'x'); x = BIN.x; end
                if isfield(BIN,'xpositions'); xpositions = BIN.xpositions; end
                if isfield(BIN,'zlevels'); zlevels = BIN.zlevels; end
                %
                %% Compatibility Patch 3.0.0
                inversion_is_started__inedipendent= 'NA';% From version 3.0.0
                inversion_is_started__global      = 'NA';% From version 3.0.0
                %
                %% Compatibility Patch 4.0.0
                if isfield(BIN,'profile_ids')  
                    if ~isempty(BIN.profile_ids)
                        P.profile_ids = cell(1); P.profile_ids{1,1}=BIN.profile_ids;
                        if isfield(BIN,'profile_line')
                            P.profile_line = cell(1); P.profile_line{1,1}=BIN.profile_line;
                        end
                        P.profile_name  = cell(1); P.profile_name{1,1} ='none';
                        temp_onoff = zeros( size(SURVEYS,1) ,1);
                        temp_onoff(P.profile_ids{1,1}(:,1)) = 1;
                        P.profile_onoff = cell(1); P.profile_onoff{1,1}=temp_onoff;
                    end
                end
            end% load version 1 (first pubblication)
            %% Data archive version II:(from version 4.0.0) 
            if  isfield(BIN,'OpenHVSR_elaboration_file_version') && (BIN.OpenHVSR_elaboration_file_version==2)
                fprintf('Loading archive version-II: (Up to V4.0.0)\n')
                
                %% if isfield(BIN,'');  = BIN.; end
                if isfield(BIN,'file'); file = BIN.file; end
                if isfield(BIN,'thispath'); thispath = BIN.thispath; end
                
                %   ---- gui_3D ----------------------------------------------------------------------------
                if isfield(BIN,'BEST_ENERGIES'); BEST_ENERGIES = BIN.BEST_ENERGIES; end
                if isfield(BIN,'BEST_MISFITS'); BEST_MISFITS = BIN.BEST_MISFITS; end
                if isfield(BIN,'BEST_MODELS'); BEST_MODELS = BIN.BEST_MODELS; end
                if isfield(BIN,'BEST_SINGLE_MISFIT'); BEST_SINGLE_MISFIT = BIN.BEST_SINGLE_MISFIT; end
                if isfield(BIN,'BEST_SINGLE_MODELS'); BEST_SINGLE_MODELS = BIN.BEST_SINGLE_MODELS; end
                if isfield(BIN,'BREAKS'); BREAKS = BIN.BREAKS; end
                %
                if isfield(BIN,'CW'); CW = BIN.CW; end
                if isfield(BIN,'DISCARDS'); DISCARDS = BIN.DISCARDS; end
                if isfield(BIN,'DL'); DL = BIN.DL; end
                if isfield(BIN,'DSP'); DSP = BIN.DSP; end
                if isfield(BIN,'DW'); DW = BIN.DW; end
                if isfield(BIN,'FDAT'); FDAT = BIN.FDAT; end
                if isfield(BIN,'FLAG__PC_features'); FLAG__PC_features = BIN.FLAG__PC_features; end
                if isfield(BIN,'HQEpicDistance'); HQEpicDistance = BIN.HQEpicDistance; end
                if isfield(BIN,'HQFocalDepth'); HQFocalDepth = BIN.HQFocalDepth; end
                if isfield(BIN,'HQMagnitude'); HQMagnitude = BIN.HQMagnitude; end
                if isfield(BIN,'HQRockRatio'); HQRockRatio = BIN.HQRockRatio; end
                if isfield(BIN,'HQfreq'); HQfreq = BIN.HQfreq; end
                if isfield(BIN,'LKT'); LKT = BIN.LKT; end
                if isfield(BIN,'MDLS'); MDLS = BIN.MDLS; end
                if isfield(BIN,'MODELS'); MODELS = BIN.MODELS; end
                if isfield(BIN,'Matlab_Release'); Matlab_Release = BIN.Matlab_Release; end
                if isfield(BIN,'Misfit_curve_term_w'); Misfit_curve_term_w = BIN.Misfit_curve_term_w; end
                if isfield(BIN,'Misfit_slope_term_w'); Misfit_slope_term_w = BIN.Misfit_slope_term_w; end
                if isfield(BIN,'Misfit_vs_Iter'); Misfit_vs_Iter = BIN.Misfit_vs_Iter; end
                if isfield(BIN,'NresultsToKeep'); NresultsToKeep = BIN.NresultsToKeep; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'Nrowa'); Nrowa = BIN.Nrowa; end
                if isfield(BIN,'QHspec'); QHspec = BIN.QHspec; end
                if isfield(BIN,'QPList'); QPList = BIN.QPList; end % (3D)
                if isfield(BIN,'QSList'); QSList = BIN.QSList; end % (3D)
                if isfield(BIN,'RCT'); RCT = BIN.RCT; end
                if isfield(BIN,'REFERENCE_MODEL_dH'); REFERENCE_MODEL_dH = BIN.REFERENCE_MODEL_dH; end
                if isfield(BIN,'REFERENCE_MODEL_zpoints'); REFERENCE_MODEL_zpoints = BIN.REFERENCE_MODEL_zpoints; end
                if isfield(BIN,'ROList'); ROList = BIN.ROList; end
                if isfield(BIN,'S'); S = BIN.S; end%         190410 compatibility
                if isfield(BIN,'SS'); SS = BIN.SS; end%  190410 compatibility
                if isfield(BIN,'SN_centralval'); SN_centralval = BIN.SN_centralval; end
                if isfield(BIN,'SN_dtamsf'); SN_dtamsf = BIN.SN_dtamsf; end
                if isfield(BIN,'SN_parname'); SN_parname = BIN.SN_parname; end
                if isfield(BIN,'SN_parscale'); SN_parscale = BIN.SN_parscale; end
                if isfield(BIN,'SN_xscale'); SN_xscale = BIN.SN_xscale; end
                if isfield(BIN,'STORED_1d_daf_fits'); STORED_1d_daf_fits = BIN.STORED_1d_daf_fits; end
                if isfield(BIN,'STORED_1d_hh_fits'); STORED_1d_hh_fits = BIN.STORED_1d_hh_fits; end
                if isfield(BIN,'STORED_1d_qp_fits'); STORED_1d_qp_fits = BIN.STORED_1d_qp_fits; end
                if isfield(BIN,'STORED_1d_qs_fits'); STORED_1d_qs_fits = BIN.STORED_1d_qs_fits; end
                if isfield(BIN,'STORED_1d_ro_fits'); STORED_1d_ro_fits = BIN.STORED_1d_ro_fits; end
                if isfield(BIN,'STORED_1d_vp_fits'); STORED_1d_vp_fits = BIN.STORED_1d_vp_fits; end
                if isfield(BIN,'STORED_1d_vs_fits'); STORED_1d_vs_fits = BIN.STORED_1d_vs_fits; end
                if isfield(BIN,'STORED_2d_daf_fits'); STORED_2d_daf_fits = BIN.STORED_2d_daf_fits; end
                if isfield(BIN,'STORED_2d_hh_fits'); STORED_2d_hh_fits = BIN.STORED_2d_hh_fits; end
                if isfield(BIN,'STORED_2d_qp_fits'); STORED_2d_qp_fits = BIN.STORED_2d_qp_fits; end
                if isfield(BIN,'STORED_2d_qs_fits'); STORED_2d_qs_fits = BIN.STORED_2d_qs_fits; end
                if isfield(BIN,'STORED_2d_ro_fits'); STORED_2d_ro_fits = BIN.STORED_2d_ro_fits; end
                if isfield(BIN,'STORED_2d_vp_fits'); STORED_2d_vp_fits = BIN.STORED_2d_vp_fits; end
                if isfield(BIN,'STORED_2d_vs_fits'); STORED_2d_vs_fits = BIN.STORED_2d_vs_fits; end
                if isfield(BIN,'STORED_RESULTS_1d_misfit'); STORED_RESULTS_1d_misfit = BIN.STORED_RESULTS_1d_misfit; end
                if isfield(BIN,'STORED_RESULTS_2d_misfit'); STORED_RESULTS_2d_misfit = BIN.STORED_RESULTS_2d_misfit; end
                if isfield(BIN,'STORED_RESULTS_2d_misfit_profile'); STORED_RESULTS_2d_misfit_profile = BIN.STORED_RESULTS_2d_misfit_profile; end
                if isfield(BIN,'SURVEYS'); SURVEYS = BIN.SURVEYS; end
                % NO Slider0     (3D)                                                       
                % NO Slider0b    (3D)                                                           
                % NO Slider1     (3D)                                                            
                % NO Slider1b    (3D)                                                           
                % NO Slider2     (3D)                                                            
                % NO Slider2b    (3D)
                % NO  if isfield(BIN,'T2_P1_global_it_count'); T2_P1_global_it_count = BIN.T2_P1_global_it_count; end
                % NO  if isfield(BIN,'T2_P1_max_it'); T2_P1_max_it = BIN.T2_P1_max_it; end
                % NO  if isfield(BIN,'T3_P1_inv'); T3_P1_inv = BIN.T3_P1_inv; end
                % NO  if isfield(BIN,'T3_P1_invSW'); T3_P1_invSW = BIN.T3_P1_invSW; end
                % NO  if isfield(BIN,'T3_P1_it_count'); T3_P1_it_count = BIN.T3_P1_it_count; end
                % NO  if isfield(BIN,'T3_P1_max_it'); T3_P1_max_it = BIN.T3_P1_max_it; end
                % NO  if isfield(BIN,'T3_P1_txt'); T3_P1_txt = BIN.T3_P1_txt; end
                % NO  if isfield(BIN,'T3_p1_revert'); T3_p1_revert = BIN.T3_p1_revert; end
                % NO  if isfield(BIN,'T5_P1_HsMask'); T5_P1_HsMask = BIN.T5_P1_HsMask; end
                % NO  if isfield(BIN,'T5_P1_txtx'); T5_P1_txtx = BIN.T5_P1_txtx; end
                % NO  if isfield(BIN,'T5_P1_txty'); T5_P1_txty = BIN.T5_P1_txty; end
                % NO  if isfield(BIN,'T6_P1_txtx'); T6_P1_txtx = BIN.T6_P1_txtx; end
                if isfield(BIN,'TO_INVERT'); TO_INVERT = BIN.TO_INVERT; end
                if isfield(BIN,'VPList'); VPList = BIN.VPList; end % (3D)
                if isfield(BIN,'VSList'); VSList = BIN.VSList; end % (3D)
                if isfield(BIN,'X1'); X1 = BIN.X1; end
                if isfield(BIN,'X2'); X2 = BIN.X2; end
                if isfield(BIN,'ZZList'); ZZList = BIN.ZZList; end % (3D)
                % NO  if isfield(BIN,'ans'); ans = BIN.ans; end
                %190404 if isfield(BIN,'appname'); appname = BIN.appname; end
                if isfield(BIN,'basevalue'); basevalue = BIN.basevalue; end
                if isfield(BIN,'basevaluew'); basevaluew = BIN.basevaluew; end
                if isfield(BIN,'bedrock'); bedrock = BIN.bedrock; end
                if isfield(BIN,'best_FDAT'); best_FDAT = BIN.best_FDAT; end
                %190404 if isfield(BIN,'beta_stuff_enable_status'); beta_stuff_enable_status = BIN.beta_stuff_enable_status; end
                if isfield(BIN,'P.ExtraFeatures.beta_stuff_enable_status'); P.ExtraFeatures.beta_stuff_enable_status = BIN.P.ExtraFeatures.beta_stuff_enable_status; end
                %  (2D)
                if isfield(BIN,'conf_1d_to_show_x'); conf_1d_to_show_x = BIN.conf_1d_to_show_x; end
                if isfield(BIN,'conf_1d_to_show_y'); conf_1d_to_show_y = BIN.conf_1d_to_show_y; end
                if isfield(BIN,'confidence_colormap'); confidence_colormap = BIN.confidence_colormap; end
                if isfield(BIN,'curve_plotmode'); curve_plotmode = BIN.curve_plotmode; end
                if isfield(BIN,'curve_weights_plotmode'); curve_weights_plotmode = BIN.curve_weights_plotmode; end
                %% FIX if isfield(BIN,'P.isshown.id'); P.isshown.id = BIN.P.isshown.id; end
                %190404 if isfield(BIN,'data_1d_to_show'); data_1d_to_show = BIN.data_1d_to_show; end
                %    cutplanes (load no need)
                if isfield(BIN,'datafile_columns'); datafile_columns = BIN.datafile_columns; end
                if isfield(BIN,'datafile_separator'); datafile_separator = BIN.datafile_separator; end
                if isfield(BIN,'default_colormap'); default_colormap = BIN.default_colormap; end
                if isfield(BIN,'depth_weights_plotmode'); depth_weights_plotmode = BIN.depth_weights_plotmode; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'dh'); dh = BIN.dh; end
                if isfield(BIN,'dim'); dim = BIN.dim; end % (3D)
                % NOT NEDEED 4.0.0:  if isfield(BIN,'dw'); dw = BIN.dw; end
                if isfield(BIN,'dx'); dx = BIN.dx; end
                % NO  if isfield(BIN,'eh52'); eh52 = BIN.eh52; end
                % NO  if isfield(BIN,'eh52_childs'); eh52_childs = BIN.eh52_childs; end
                % 180323  if isfield(BIN,'enable_menu'); enable_menu = BIN.enable_menu; end
                % 180323  if isfield(BIN,'fontsizeis'); fontsizeis = BIN.fontsizeis; end
                if isfield(BIN,'gapx'); gapx = BIN.gapx; end
                if isfield(BIN,'global_inversion_step'); global_inversion_step = BIN.global_inversion_step; end
                % %   h0                                                         
                % %   h1                                                         
                % %   h10                                                        
                % %   h5                                                         
                % %   h51                                                        
                % %   h52                                                        
                % %   h5_1                                                       
                % %   h7                                                         
                % %   hAx_1d_confidence                                          
                % %   hAx_1dprof                                                 
                % %   hAx_1dprof_hcmenu                                          
                % %   hAx_2Dprof                                                 
                % %   hAx_2dprof_hcmenu                                          
                % %   hAx_MvsIT                                                  
                % %   hAx_MvsIT_hcmenu                                           
                % %   hAx_cnf_hcmenu                                             
                % %   hAx_cwf                                                    
                % %   hAx_cwf_hcmenu                                             
                % %   hAx_dat                                                    
                % %   hAx_dat_hcmenu                                             
                % %   hAx_dwf                                                    
                % %   hAx_dwf_hcmenu                                             
                % %   hAx_geo                                                    
                % %   hAx_geo_hcmenu                                             
                % %   hAx_sensitivity                                            
                % %   hAx_sns_hcmenu                                             
                % %   hRand                                                      
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.D                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   H.PANELS{P.tab_id}.A                                                     
                % %   H.PANELS{P.tab_id}.B                                                     
                % %   hTabGroup                                                  
                % %   hTab_1d_viewer                                             
                % %   hTab_2d_viewer                                             
                % %   hTab_Confidenc                                             
                % %   hTab_Inversion                                             
                % %   H.PANELS{P.tab_id}.B                                             
                % %   hTab_mod                                                   
                % %   hTab_mod_cnames                                    
                % %   hTab_mod_hcmenu                                            
                % %   h_1d_next                                                  
                % %   h_1d_prev                                                  
                % %   h_dscale                                                   
                % %   h_ex_val                                                   
                % %   h_fref_val                                                 
                % %   h_fwd_sw                                                   
                % %   H.gui                                                      
                % %   h_hh_val                                                   
                % %   h_qp_val                                                   
                % %   h_qp_w                                                     
                % %   h_qs_val                                                   
                % %   h_qs_w                                                     
                % %   h_realtime                                                 
                % %   h_ro_val                                                   
                % %   h_ro_w                                                     
                % %   h_scale_max                                                
                % %   h_scale_min
                % %   h_view_rotation       (3D)
                % %   h_vp_val                                                   
                % %   h_vp_w                                                     
                % %   h_vs_val                                                   
                % %   h_vs_w                                                     
                % %   hconf_nlevels                                              
                % %   hconf_nsmooth                                              
                % %   hconf_xlay                                                 
                % %   hconf_xprop                                                
                % %   hconf_ylay                                                 
                % %   hconf_yprop                                                
                % %   hsns_bound                                                 
                % %   hsns_nlevels                                               
                % %   hsns_step                                                  
                % %   hsns_xlay                                                  
                % %   hsns_xprop                                                 
                if isfield(BIN,'i'); i = BIN.i; end
                if isfield(BIN,'id'); id = BIN.id; end
                if isfield(BIN,'independent_optimiazation_cicles'); independent_optimiazation_cicles = BIN.independent_optimiazation_cicles; end
                if isfield(BIN,'init_single_FDAT'); init_single_FDAT = BIN.init_single_FDAT; end
                if isfield(BIN,'init_value__dscale'); init_value__dscale = BIN.init_value__dscale; end
                if isfield(BIN,'init_value__fref'); init_value__fref = BIN.init_value__fref; end
                if isfield(BIN,'init_value__max_scale'); init_value__max_scale = BIN.init_value__max_scale; end
                if isfield(BIN,'init_value__min_scale'); init_value__min_scale = BIN.init_value__min_scale; end
                if isfield(BIN,'ixmax_id'); ixmax_id = BIN.ixmax_id; end
                if isfield(BIN,'ixmin_id'); ixmin_id = BIN.ixmin_id; end
                if isfield(BIN,'last_FDAT'); last_FDAT = BIN.last_FDAT; end
                if isfield(BIN,'last_MDLS'); last_MDLS = BIN.last_MDLS; end
                if isfield(BIN,'last_log_number'); last_log_number = BIN.last_log_number; end
                if isfield(BIN,'last_project_name'); last_project_name = BIN.last_project_name; end
                if isfield(BIN,'last_single_FDAT'); last_single_FDAT = BIN.last_single_FDAT; end
                if isfield(BIN,'last_single_MDL'); last_single_MDL = BIN.last_single_MDL; end
                if isfield(BIN,'lsmooth'); lsmooth = BIN.lsmooth; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_b'); main_b = BIN.main_b; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_h'); main_h = BIN.main_h; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_l'); main_l = BIN.main_l; end
                if isfield(BIN,'main_scale'); main_scale = BIN.main_scale; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'main_w'); main_w = BIN.main_w; end
                if isfield(BIN,'max_H'); max_H = BIN.max_H; end
                if isfield(BIN,'max_lat_dH'); max_lat_dH = BIN.max_lat_dH; end
                if isfield(BIN,'max_lat_dQp'); max_lat_dQp = BIN.max_lat_dQp; end
                if isfield(BIN,'max_lat_dQs'); max_lat_dQs = BIN.max_lat_dQs; end
                if isfield(BIN,'max_lat_dRo'); max_lat_dRo = BIN.max_lat_dRo; end
                if isfield(BIN,'max_lat_dVp'); max_lat_dVp = BIN.max_lat_dVp; end
                if isfield(BIN,'max_lat_dVs'); max_lat_dVs = BIN.max_lat_dVs; end
                if isfield(BIN,'max_qp_qs_ratio'); max_qp_qs_ratio = BIN.max_qp_qs_ratio; end
                if isfield(BIN,'max_qs'); max_qs = BIN.max_qs; end
                if isfield(BIN,'max_ro'); max_ro = BIN.max_ro; end
                if isfield(BIN,'max_vp_vs_ratio'); max_vp_vs_ratio = BIN.max_vp_vs_ratio; end
                if isfield(BIN,'min_H'); min_H = BIN.min_H; end
                if isfield(BIN,'min_qp_qs_ratio'); min_qp_qs_ratio = BIN.min_qp_qs_ratio; end
                if isfield(BIN,'min_qs'); min_qs = BIN.min_qs; end
                if isfield(BIN,'min_ro'); min_ro = BIN.min_ro; end
                if isfield(BIN,'min_vp_vs_ratio'); min_vp_vs_ratio = BIN.min_vp_vs_ratio; end
                if isfield(BIN,'min_vs'); min_vs = BIN.min_vs; end
                if isfield(BIN,'misfit_over_sumweight'); misfit_over_sumweight = BIN.misfit_over_sumweight; end
                if isfield(BIN,'modl_FDAT'); modl_FDAT = BIN.modl_FDAT; end
                if isfield(BIN,'modl_FDATSW'); modl_FDATSW = BIN.modl_FDATSW; end
                if isfield(BIN,'n'); n = BIN.n; end
                if isfield(BIN,'n_depth_levels'); n_depth_levels = BIN.n_depth_levels; end
                if isfield(BIN,'ndegfree'); ndegfree = BIN.ndegfree; end
                if isfield(BIN,'nlaya'); nlaya = BIN.nlaya; end
                if isfield(BIN,'nlayb'); nlayb = BIN.nlayb; end
                if isfield(BIN,'nlvl'); nlvl = BIN.nlvl; end
                if isfield(BIN,'nx_ticks'); nx_ticks = BIN.nx_ticks; end
                if isfield(BIN,'ny_ticks'); ny_ticks = BIN.ny_ticks; end
                if isfield(BIN,'nz_ticks'); nz_ticks = BIN.nz_ticks; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objh'); objh = BIN.objh; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objn'); objn = BIN.objn; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objw'); objw = BIN.objw; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objx'); objx = BIN.objx; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'objy'); objy = BIN.objy; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_axes'); pos_axes = BIN.pos_axes; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_axes2'); pos_axes2 = BIN.pos_axes2; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_axis'); pos_axis = BIN.pos_axis; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_panel'); pos_panel = BIN.pos_panel; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'pos_table'); pos_table = BIN.pos_table; end
                if isfield(BIN,'poten'); poten = BIN.poten; end
                if isfield(BIN,'prev_BEST_SINGLE_MISFIT'); prev_BEST_SINGLE_MISFIT = BIN.prev_BEST_SINGLE_MISFIT; end
                if isfield(BIN,'prev_BEST_SINGLE_MODELS'); prev_BEST_SINGLE_MODELS = BIN.prev_BEST_SINGLE_MODELS; end
                if isfield(BIN,'prev_MDLS'); prev_MDLS = BIN.prev_MDLS; end
                if isfield(BIN,'prev_best_FDAT'); prev_best_FDAT = BIN.prev_best_FDAT; end
                if isfield(BIN,'prev_single_it'); prev_single_it = BIN.prev_single_it; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'profile_ids');  profile_ids = BIN.profile_ids; end% (3D)                                                        
                % NOT NEDEED 4.0.0:  if isfield(BIN,'profile_line'); profile_line= BIN.profile_line; end% (3D) 
                if isfield(BIN,'property_1d_to_show'); property_1d_to_show = BIN.property_1d_to_show; end
                if isfield(BIN,'property_23d_to_show'); property_23d_to_show = BIN.property_23d_to_show; end% (3D)
                % NOT NEDEED 4.0.0:  if isfield(BIN,'r_distance_from_profile')  r_distance_from_profile= BIN.r_distance_from_profile; end % (3D)
                if isfield(BIN,'r_reciprocicity');          r_reciprocicity= BIN.r_reciprocicity; end % (3D)
                if isfield(BIN,'receiver_locations');       receiver_locations= BIN.receiver_locations; end % (3D)
                % NOT NEDEED 4.0.0:  if isfield(BIN,'row'); row = BIN.row; end
                if isfield(BIN,'sensitivity_colormap'); sensitivity_colormap = BIN.sensitivity_colormap; end
                if isfield(BIN,'smoothing_radius'); smoothing_radius = BIN.smoothing_radius; end
                if isfield(BIN,'smoothing_strategy'); smoothing_strategy = BIN.smoothing_strategy; end
                if isfield(BIN,'sns_1d_to_show'); sns_1d_to_show = BIN.sns_1d_to_show; end
                % NOT NEDEED 4.0.0:  if isfield(BIN,'str'); str = BIN.str; end
                if isfield(BIN,'sw_nmodes'); sw_nmodes = BIN.sw_nmodes; end
                if isfield(BIN,'sw_nsmooth'); sw_nsmooth = BIN.sw_nsmooth; end
                if isfield(BIN,'vala'); vala = BIN.vala; end
                if isfield(BIN,'valb'); valb = BIN.valb; end
                if isfield(BIN,'var1'); var1 = BIN.var1; end
                if isfield(BIN,'var2'); var2 = BIN.var2; end
                %190404 if isfield(BIN,'version'); version = BIN.version; end
                if isfield(BIN,'vfst_MDLS'); vfst_MDLS = BIN.vfst_MDLS; end
                if isfield(BIN,'view_max_scale'); view_max_scale = BIN.view_max_scale; end
                if isfield(BIN,'view_min_scale'); view_min_scale = BIN.view_min_scale; end
                if isfield(BIN,'viewerview');     viewerview = BIN.viewerview; end  %(3D)
                if isfield(BIN,'weight_curv');    weight_curv = BIN.weight_curv; end
                if isfield(BIN,'weight_dpth');    weight_dpth = BIN.weight_dpth; end
                if isfield(BIN,'working_folder'); working_folder = BIN.working_folder; end
                if isfield(BIN,'x'); x = BIN.x; end
                if isfield(BIN,'xpositions'); xpositions = BIN.xpositions; end
                if isfield(BIN,'zlevels'); zlevels = BIN.zlevels; end
                %% From 3.0.0
                if isfield(BIN,'inversion_is_started__inedipendent');  inversion_is_started__inedipendent= BIN.inversion_is_started__inedipendent; end
                if isfield(BIN,'inversion_is_started__global');        inversion_is_started__global      = BIN.inversion_is_started__global; end
                %% From 4.0.0
                if isfield(BIN,'P');  P= BIN.P; end
                if isfield(BIN,'Misfit_vs_Iter_MULPTIPLE_local');  Misfit_vs_Iter_MULPTIPLE_local= BIN.Misfit_vs_Iter_MULPTIPLE_local; end
                if isfield(BIN,'Misfit_vs_Iter_MULPTIPLE');  Misfit_vs_Iter_MULPTIPLE= BIN.Misfit_vs_Iter_MULPTIPLE; end
                if isfield(BIN,'best_MISFIT_by_location');  best_MISFIT_by_location= BIN.best_MISFIT_by_location; end
                
            end% load version 2 (from 4.0.0)
            
            %% Update Interface
            if isfield(BIN,'ui_dist');   set(hRand,    'Value',    BIN.ui_dist);   end
            if isfield(BIN,'ui_hh_pc');  set(h_hh_val, 'String',   BIN.ui_hh_pc);   end

            if isfield(BIN,'ui_vp_pc');  set(h_vp_val, 'String',   BIN.ui_vp_pc);   end
            if isfield(BIN,'ui_vp_ww');  set(h_vp_w,   'String',   BIN.ui_vp_ww);   end

            if isfield(BIN,'ui_vs_pc');  set(h_vs_val, 'String',   BIN.ui_vs_pc);   end
            if isfield(BIN,'ui_vs_ww');  set(h_vs_w,   'String',   BIN.ui_vs_ww);   end

            if isfield(BIN,'ui_ro_pc');  set(h_ro_val, 'String',   BIN.ui_ro_pc);   end
            if isfield(BIN,'ui_ro_ww');  set(h_ro_w,   'String',   BIN.ui_ro_ww);   end

            if isfield(BIN,'ui_qp_pc');  set(h_qp_val, 'String',   BIN.ui_qp_pc);   end
            if isfield(BIN,'ui_qp_ww');  set(h_qp_w,   'String',   BIN.ui_qp_ww);   end

            if isfield(BIN,'ui_qs_pc');  set(h_qs_val, 'String',   BIN.ui_qs_pc);   end
            if isfield(BIN,'ui_qs_ww');  set(h_qs_w,   'String',   BIN.ui_qs_ww);   end

            if isfield(BIN,'ui_ex');     set(h_ex_val,   'String',   BIN.ui_ex);   end
            if isfield(BIN,'ui_fref');   set(h_fref_val, 'String',   BIN.ui_fref);   end
            if isfield(BIN,'ui_frnge_1');  set(h_scale_min,'String',   BIN.ui_frnge_1);   end
            if isfield(BIN,'ui_frnge_2');  set(h_scale_max,'String',   BIN.ui_frnge_2);   end
            if isfield(BIN,'ui_frnge_d');  set(h_dscale,   'String',   BIN.ui_frnge_d);   end
            
            fprintf('[Elaboration resumed Correctly]\n')
            %% Select location 1
            P.isshown.id = 1;
            %BEST_SINGLE_MISFIT = prev_BEST_SINGLE_MISFIT;
            %% graphics
            plot__curve_weights(0);
            plot__depth_weights(0);
            Show_survey(0);
            %
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);
        end
    end
%%      Settings
    function Menu_Settings_Setup(~,~,~)
        [min_vs, ...
         min_vp_vs_ratio,max_vp_vs_ratio, ...
         min_ro,max_ro, ...
         min_H,max_H, ...
         min_qs,max_qs, ...
         min_qp_qs_ratio,max_qp_qs_ratio, ...
         HQMagnitude, HQEpicDistance, HQFocalDepth,  HQRockRatio, ...
         sw_nmodes, sw_nsmooth] = setup_manager( ...
          min_vs, ... 
          min_vp_vs_ratio, max_vp_vs_ratio, ...
          min_ro,max_ro, ...
          min_H,max_H, ...
          min_qs,max_qs, ...
          min_qp_qs_ratio,max_qp_qs_ratio, ...
          HQMagnitude,  HQEpicDistance, HQFocalDepth, HQRockRatio, ...
          sw_nmodes, sw_nsmooth);
      
        %[fFS,FSraw]=FourierSpectrum(magn,delt,dept,rock); %Compute theoretical Fourier spectrum for target earthquake (see Setup)
        [HQfreq, QHspec] = FourierSpectrum( HQMagnitude,  HQEpicDistance, HQFocalDepth, HQRockRatio);
        %if(size(QHspec,2) == 1); QHspec=QHspec.'; end
    end
    function Menu_Settings_objective(~,~,~)
        if ~isempty(inversion_is_started__inedipendent)
	       if(~strcmp(inversion_is_started__inedipendent,''))
		   quest = 'These parameters must be set before the inversion is started and should not be modified afterwards. Continue?';
		   answer = questdlg(quest);
		   if strcmp(answer,'No'); return; end
		   if strcmp(answer,'Cancel'); return; end
	       end
	    end
        
        prompt = {'Curve Term %','Slope Term %'};
        def = {num2str(Misfit_curve_term_w), num2str(Misfit_slope_term_w)};
        answer = inputdlg(prompt,'Set Misfit Approach',1,def);
        if(~isempty(answer))
            Misfit_curve_term_w = str2double(answer{1});        
            Misfit_slope_term_w = str2double(answer{2});
        end
    end
%%      View
%%          interpolation
    function Menu_view_media_interp(~,~,~)
        prompt = {'N of x ticks','N of y  ticks','N of z  ticks'};
        def = {num2str(nx_ticks), num2str(ny_ticks), num2str(nz_ticks)};
        answer = inputdlg(prompt,'Set resolution of 2D/3D representation',1,def);
        nx_ticks_old = nx_ticks; ny_ticks_old = ny_ticks; nz_ticks_old = nz_ticks;
       
        nx_ticks = str2double(answer{1}); 
        ny_ticks = str2double(answer{2}); 
        nz_ticks = str2double(answer{3});
        if(nx_ticks<1 || ny_ticks<1 || nz_ticks<1); return; end
        
        if(nx_ticks < size(SURVEYS,1)) 
            msgbox(sprintf('Message: the vertical number of interpolating points cannot be less than %d',size(SURVEYS,1)))
            nx_ticks = size(SURVEYS,1); 
        end
        if(ny_ticks < size(SURVEYS,1)) 
            msgbox(sprintf('Message: the vertical number of interpolating points cannot be less than %d',size(SURVEYS,1)))
            ny_ticks = size(SURVEYS,1); 
        end
        if(nz_ticks < n_depth_levels)
            %fprintf('Message: the vertical number of interpolating points cannot be less than %d\n',n_depth_levels)
            %fprintf('\n')
            msgbox(sprintf('Message: the vertical number of interpolating points cannot be less than %d',n_depth_levels))
            nz_ticks = n_depth_levels; 
        end
        
        if( (nx_ticks_old ~= nx_ticks) || (ny_ticks_old ~= ny_ticks) || (nz_ticks_old ~= nz_ticks) )
            set(hRefresh,'BackgroundColor',[1,0,0]);
        end
    end
%%          smoothing
    function Menu_smoothing_strategy0_Callback(~,~,~)
        smoothing_strategy = 0; spunta(eh52_childs, smoothing_strategy);
        plot_2d_profile( 0,property_23d_to_show);
    end
    function Menu_smoothing_strategy1_Callback(~,~,~)
        smoothing_strategy = 1; 
        set_smoothing_radius();
        spunta(eh52_childs, smoothing_strategy);% disable_components();
        plot_2d_profile( 0,property_23d_to_show);
    end
    function Menu_smoothing_strategy2_Callback(~,~,~)
        smoothing_strategy = 2; 
        set_smoothing_radius();
        spunta(eh52_childs, smoothing_strategy);% disable_components();
        plot_2d_profile( 0,property_23d_to_show);
    end
    function Menu_smoothing_strategy3_Callback(~,~,~)
        smoothing_strategy = 3;
        set_smoothing_radius(); 
        spunta(eh52_childs, smoothing_strategy);% disable_components();
        plot_2d_profile( 0,property_23d_to_show);
    end
    function set_smoothing_radius()
        prompt = {'Smoothing Radius (0 = off)'};
        def = {num2str(smoothing_radius)};
        answer = inputdlg(prompt,'Smoothing',1,def);
        smoothing_radius = str2double(answer{1});
        %plot_2d_profile( 0,parameter_id)
    end
%%          colormap
    function Menu_view_cmap_Jet(~,~,~)
        set(H.gui,'CurrentAxes',hAx_2Dprof);
        color_map='Jet';
        colormap(hAx_2Dprof, color_map);
    end
    function Menu_view_cmap_Hot(~,~,~)
        set(H.gui,'CurrentAxes',hAx_2Dprof);
        color_map='Hot';
        colormap(hAx_2Dprof, color_map);
    end
    function Menu_view_cmap_Bone(~,~,~)
        set(H.gui,'CurrentAxes',hAx_2Dprof);
        color_map='Bone';
        colormap(hAx_2Dprof, color_map);
    end
    function Menu_View_clim(~,~,~)
        prompt = {'Choose Color Limits',''};
        if(isempty(color_limits)); return; end
        def = {num2str(color_limits(1)), num2str(color_limits(2))};
        answer = inputdlg(prompt,'Set color limits',1,def);
        if(~isempty(answer))
            color_limits(1) = str2double(answer{1});        
            color_limits(2) = str2double(answer{2});
        end
         caxis(hAx_2Dprof, color_limits);
    end
%%          curve  x.range
    function Menu_view_xcurverange_custom(~,~,~)
        prompt = {'min','max'};
        def = {num2str(view_min_scale), num2str(view_max_scale)};
        answer = inputdlg(prompt,'Set Freq. range to view',1,def);
        if(~isempty(answer))
            view_min_scale = str2double(answer{1});        
            view_max_scale = str2double(answer{2});
            Show_survey(0)
        end
    end
    function Menu_view_xcurverange_fitprocessed(~,~,~)
        view_min_scale = str2double( get(h_scale_min,'String') );
        view_max_scale = str2double( get(h_scale_max,'String') );
        Show_survey(0)
    end
    function Menu_view_xcurverange_fitdata(~,~,~)
        view_min_scale = min(main_scale);
        view_max_scale = max(main_scale);
        Show_survey(0)
    end
%%      About
    function Menu_About_Credits(~,~,~)
        msgbox(get(H.menu.credits,'UserData'),'CREDITS:')   
    end
%% TAB-1: ================================================= Main View
    function CB_hAx_geo_back(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = P.isshown.id;
            switch(P.isshown.id)
                case 0; val = Ndat; 
                case 1; val = Ndat;    
                otherwise; val = val -1;    
            end
            P.isshown.id = val;
            
            prev_MDLS = MDLS;
            prev_BEST_SINGLE_MODELS = BEST_SINGLE_MODELS;
            prev_best_FDAT = best_FDAT;
            prev_BEST_SINGLE_MISFIT = BEST_SINGLE_MISFIT;
            prev_single_it = independent_optimiazation_cicles(P.isshown.id);

            last_single_FDAT = cell(1,2); 
            
            set(T3_P1_it_count,'String',strcat( num2str(independent_optimiazation_cicles(P.isshown.id)),' so far'));
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);
            Show_survey(0);
            %plot_1d_profile(hAx_1dprof);
            
            hold(hAx_1dprof,'off');
            draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
        end
    end
    function CB_hAx_geo_next(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = P.isshown.id;
            switch(P.isshown.id)
                case 0; val = 1; 
                case Ndat; val = 1;    
                otherwise; val = val +1;    
            end
            P.isshown.id = val;

            prev_MDLS = MDLS;

            prev_BEST_SINGLE_MODELS = BEST_SINGLE_MODELS;
            prev_best_FDAT = best_FDAT;
            prev_BEST_SINGLE_MISFIT = BEST_SINGLE_MISFIT;
            prev_single_it = independent_optimiazation_cicles(P.isshown.id);

            last_single_FDAT = cell(1,2); 

            set(T3_P1_it_count,'String',strcat( num2str(independent_optimiazation_cicles(P.isshown.id)),' so far'));
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);
            Show_survey(0);
            %plot_1d_profile(hAx_1dprof);

            hold(hAx_1dprof,'off');
            draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
        end
    end
    function CB_hAx_geo_goto(~,~,~)
        if isempty(SURVEYS); return; end
        if P.isshown.id ==0; return; end
        %
        %
        Ndat = size(SURVEYS,1);
        prompt = {'Select Measurement ID'};
        def = {'0'};
        answer = inputdlg(prompt,'Unite with next',1,def);
        if(~isempty(answer))
            val = str2double(answer{1});
            if 0<val && val<=Ndat
                P.isshown.id= val;
                
                prev_MDLS = MDLS;

                prev_BEST_SINGLE_MODELS = BEST_SINGLE_MODELS;
                prev_best_FDAT = best_FDAT;
                prev_BEST_SINGLE_MISFIT = BEST_SINGLE_MISFIT;
                prev_single_it = independent_optimiazation_cicles(P.isshown.id);

                last_single_FDAT = cell(1,2); 

                set(T3_P1_it_count,'String',strcat( num2str(independent_optimiazation_cicles(P.isshown.id)),' so far'));
                Update_survey_locations(hAx_main_geo);
                Update_survey_locations(hAx_geo);
                Show_survey(0);
                %plot_1d_profile(hAx_1dprof);

                hold(hAx_1dprof,'off');
                draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
                %Update_Inversion_Parameters();
                %Update_profile_locations(hAx_main_geo);
            end
        end
    end
    %
    function CB_hAx_show_profile_back(~,~,~)
        if ~isempty(P.profile_ids)
            Ndat = size(P.profile_ids,1);
            val = P.profile.id;
            switch(P.profile.id)
                case 0; val = Ndat;
                case 1; val = Ndat;
                otherwise; val = val -1;
            end
            P.profile.id = val;
            Update_profile_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);
        else
            Message = sprintf('NO PROFILES WERE CREATED\n. \nProfile Creation: (On "Main View" Tab)\n1) Define profiles by right-clicking on the map.\n2) Click to set the profile''s start point.\n3) Click again to set the profile''s end point.\n4) Include stations by indicating the farthest station to be included.\n5) Use add/remove buttons to include/exclude single stations.\n \nProfile Visualization: (on this Tab)\n1) Select a profile to be shown using the [-][->][+] buttons.\n2) Select a the property to be shown using buttons on the rigth.');
            msgbox(Message,'INFO')
            return;
        end
    end
    function CB_hAx_show_profile_next(~,~,~)
        if ~isempty(P.profile_ids)
            Ndat = size(P.profile_ids,1);
            val = P.profile.id;
            switch(P.profile.id)
                case 0; val = 1;
                case Ndat; val = 1;
                otherwise; val = val +1;
            end
            P.profile.id = val;
            Update_profile_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);
        else
            Message = sprintf('NO PROFILES WERE CREATED\n. \nProfile Creation: (On "Main View" Tab)\n1) Define profiles by right-clicking on the map.\n2) Click to set the profile''s start point.\n3) Click again to set the profile''s end point.\n4) Include stations by indicating the farthest station to be included.\n5) Use add/remove buttons to include/exclude single stations.\n \nProfile Visualization: (on this Tab)\n1) Select a profile to be shown using the [-][->][+] buttons.\n2) Select a the property to be shown using buttons on the rigth.');
            msgbox(Message,'INFO')
            return;
        end
    end
    function CB_hAx_show_profile_goto(~,~,~)
        if ~isempty(P.profile_ids)
            prompt = {'Select Profile ID'};
            def = {'0'};
            answer = inputdlg(prompt,'Unite with next',1,def);
            if(~isempty(answer))
                val = str2double(answer{1});
                Ndat = size(P.profile_ids,1);
                if 0<val && val<=Ndat
                    P.profile.id = val;
                    Update_profile_locations(hAx_main_geo);
                    Update_survey_locations(hAx_geo);
                end
            end
        else
            Message = sprintf('NO PROFILES WERE CREATED\n. \nProfile Creation: (On "Main View" Tab)\n1) Define profiles by right-clicking on the map.\n2) Click to set the profile''s start point.\n3) Click again to set the profile''s end point.\n4) Include stations by indicating the farthest station to be included.\n5) Use add/remove buttons to include/exclude single stations.\n \nProfile Visualization: (on this Tab)\n1) Select a profile to be shown using the [-][->][+] buttons.\n2) Select a the property to be shown using buttons on the rigth.');
            msgbox(Message,'INFO')
            return;
        end
    end
    
    %
    function CB_hAx_profile_addrec(~,~,~)
        if P.profile.id==0; return; end
        if ~isempty(P.profile_ids)
            Ndat = size(SURVEYS,1);
            prompt = {'Select id'};
            def = {'0'};
            answer = inputdlg(prompt,'Add receiver',1,def);
            ispresent = 0;
            if(~isempty(answer))
                val = str2double(answer{1});
                if 1<=val && val<= Ndat
                    for ii=1:size(P.profile_ids{P.profile.id,1},1)
                        if val==P.profile_ids{P.profile.id,1}(ii,1)
                            ispresent=1;
                        end
                    end
                    if ispresent==0% add the point
                        additional = [];
                        xx    = P.profile_line{P.profile.id,1}(:,1);
                        yy    = P.profile_line{P.profile.id,1}(:,2);
                        recta_kind = 0;
                        if(xx(1)==xx(2)) % rect x=constant
                            recta_kind = 1;
                            dr = receiver_locations(val,2)-yy(1);
                            far = abs(receiver_locations(val,1)-xx(1));
                            additional = [val, dr, far];
                        end
                        if(yy(1)==yy(2)) % rect y=constant
                                recta_kind = 2;
                                dr = receiver_locations(val,1)-xx(1);
                                far = abs(receiver_locations(val,2)-yy(1));
                                additional = [val, dr, far];
                        end
                        if(recta_kind==0) % rect y=mx+q    q=y-mx
                            m1 = (yy(2)-yy(1))/(xx(2)-xx(1));
                            q1 = yy(1) - m1*xx(1);
                            dist = abs(receiver_locations(val,2) - (m1*receiver_locations(val,1) +q1))/sqrt(1+m1^2);% Equation 1
                            %% info
                            % r1:  y = m1 x + q1 (profile)
                            % r2:  y = m2 x + q2 (line through the receiver and perpendicular to r1)
                            %
                            % rect given endpoints
                            % r1 = m1 x + q1:    (ax +by +c = 0)
                            %     a = y2-y1
                            %     b = x2-x1
                            %     c = x2 y1 - y2 x1
                            %     m1 = -a/b = -(y2-y1)/(x2-x1) 
                            %     q1  = y1 -m1 x1
                            %
                            % distance of point p (receiver) from the rect r1 (the profile). (Equation 1)
                            % dist = |yp - m1 xp -q1 | / sqrt(1 + m1^1)
                            %
                            % rect (r2) through a point p and perpendicular to r1 (y=m1 x +q1):
                            % y = m2 xp + q2
                            % m2  = -1/m1
                            % q2 = yp - m2 xp == yp +xp/m1  (Equation 2)
                            %
                            % point of intersection of two rects
                            % [ y = m2 x + q2
                            % [ y = m1 x + q1
                            %
                            % [ y = m2 x + q2
                            % [ m2 x + q2 = m1 x + q1 -> x(m2-m1) = (q1-q2)
                            %
                            % [ y = m2 (q1-q2)/(m2-m1)+ q2
                            % [ x = (q1-q2)/(m2-m1) 
                            %%
                            m2 = -1/m1;
                            q2 = receiver_locations(val,2) + receiver_locations(val,1)/m1;%  (Equation 2)  
                            xp = (q1-q2)/(m2-m1);%             Point of intersection
                            yp = m2*(q1-q2)/(m2-m1)+q2;% Point of intersection 
                            drs= sqrt( (xx(1)-xp).^2 + (yy(1)-yp).^2 );% distances from beginning of profile
                            %
                            far = dist;
                            dr  = drs;
                            if(xp < xx)
                                dr = -dr;
                            end
                            % val = station-ID
                            % dr  = distance (along profile) from profile beginning
                            % far = distance from profile
                            additional = [val, dr, far];
                        end
                        %
                        % check for double entries (same longitudinal distance, to be avoided)     
                        if isempty(additional); return; end
                        [r,~]= find(P.profile_ids{P.profile.id,1}(:,2)==additional (2));
                        if ~isempty(r) 
                            Message = sprintf('COULD NOT ADD STATION TO THE PROFILE\nOnce projected, the selected station overlaps with station no. %d.',P.profile_ids{P.profile.id,1}( r(1), 1)   );
                            msgbox(Message,'INFO')
                            return; 
                        end
                        % if everything is Ok
                        P.profile_ids{P.profile.id,1} = [P.profile_ids{P.profile.id,1};  additional];
                        P.profile_onoff{P.profile.id,1}(val) = 1;
                        %
                        dummy = P.profile_ids{P.profile.id,1};
                        [~,idx] = sort(dummy(:,2)); % sort just the first column
                        sortedmat = dummy(idx,:);   % sort the whole matrix using the sort indices
                        P.profile_ids{P.profile.id,1}   = sortedmat;
                        %
                        %set(h_shown_prof,'String',['prof. ',num2str(P.profile.id)])
                    end
                end
            end
            Update_profile_locations(hAx_main_geo);
            %is_done();
        else
            Message = sprintf('NO PROFILES WERE CREATED\n. \nProfile Creation: (On "Main" Tab)\n1) Define profiles by right-clicking on the map.\n2) Click to set the profile''s start point.\n3) Click again to set the profile''s end point.\n4) Include stations by entering the desired distance from profile.\n5) Use add/remove buttons to include/exclude single stations.\n \nProfile Visualization: (on this Tab)\n1) Select a profile to be shown using the [-][->][+] buttons.\n2) Select a the property to be shown using buttons on the rigth.');
            msgbox(Message,'INFO')
            return;
        end
    end
    function CB_hAx_profile_remrec(~,~,~)
        if P.profile.id==0; return; end
        if ~isempty(P.profile_ids)
            Ndat = size(SURVEYS,1);
            prompt = {'Select id'};
            def = {'0'};
            answer = inputdlg(prompt,'Remove receiver',1,def);
            Nr = size(P.profile_ids{P.profile.id,1},1);
            Nn = 0;
            if(~isempty(answer))
                val = str2double(answer{1});
                if 1<=val && val<= Ndat
                    dummy_ids = 0*P.profile_ids{P.profile.id,1};
                    for ii = 1:Nr
                        if val~=P.profile_ids{P.profile.id,1}(ii,1)
                            Nn=Nn+1;
                            dummy_ids(Nn,:) = P.profile_ids{P.profile.id,1}(ii,:);
                        end
                    end
                    if Nn~=Nr% something changed
                        if Nn>1% two point (at least) must be present
                            dummy_ids = dummy_ids(1:Nn,:);
                            P.profile_ids{P.profile.id,1}   = dummy_ids;
                            % P.profile_line  > no update;
                            P.profile_onoff{P.profile.id,1}(val) = 0;
                            %
                            %set(h_shown_prof,'String',['prof. ',num2str(P.profile.id)])
                        else
                            fprintf('MESSAGE: Profile cannot comprise less than 2 stations.\n')
                            fprintf('         Action was not performed,\n')
                            fprintf('         station was not removed,\n')
                            fprintf('         profile %d is unchanged.\n',P.profile.id)
                        end
                    end
                end
            end
            Update_profile_locations(hAx_main_geo);
            %is_done();
        else
            Message = sprintf('NO PROFILES WERE CREATED\n. \nProfile Creation: (On "Main" Tab)\n1) Define profiles by right-clicking on the map.\n2) Click to set the profile''s start point.\n3) Click again to set the profile''s end point.\n4) Include stations by entering the desired distance from profile.\n5) Use add/remove buttons to include/exclude single stations.\n \nProfile Visualization: (on this Tab)\n1) Select a profile to be shown using the [-][->][+] buttons.\n2) Select a the property to be shown using buttons on the rigth.');
            msgbox(Message,'INFO')
            return;
        end
    end
%% TAB-2: ================================================= Inversion (Global)
%% TAB-2, Panel-1: Inversion
    function lock_table_modify(~,~,~)
        [LKT, RCT] = lockparameters_manager();
    end
    function B_start_model(~,~,~)
        if(~isempty(FDAT))
            modl_FDAT = multiple_fwd_model();
        else
            fprintf('No data was loaded. Please load a project.\n')
        end
    end
    function B_start_model_sw(~,~,~)
        if(~isempty(FDAT))
            set(h_fwd_sw, 'enable','off')
            set(h_fwd_sw, 'string','wait')
            modl_FDATSW = multiple_fwd_model_sw();
            set(h_fwd_sw, 'string','Add S.W.')
            set(h_fwd_sw, 'enable','on')
        else
            fprintf('No data was loaded. Please load a project.\n')
        end
    end
    function B_auto_lateral_weights(~,~,~)
        if ~isempty(MDLS)

            prompt = {'Vp','Vs','Ro','Qp','Qs'};
            def = {num2str(max_lat_dVp), ...
                num2str(max_lat_dVs), ...
                num2str(max_lat_dRo), ...
                num2str(max_lat_dQp), ...
                num2str(max_lat_dQs)};
            answer = inputdlg(prompt,'Expected lateral variation',1,def);


            if(~isempty(answer))
                [OUT] = multiple_fwd_model();

                Nmod = size(MDLS,2);
                misfits = zeros(1,Nmod);
                nlayers = zeros(1,Nmod);
                for m = 1:Nmod
                    [MFitx, ~,~,~] = get_single_model_misfit(m, OUT{m,2});
                    misfits(m) = MFitx;
                    nlayers(m) = size(MDLS{m},1);
                end
                maxmisf = max(misfits); 
                maxlayr = sum(nlayers);

                max_lat_dVp = str2double(answer{1});         
                max_lat_dVs = str2double(answer{2});
                max_lat_dRo = str2double(answer{3});
                max_lat_dQp = str2double(answer{4});         
                max_lat_dQs = str2double(answer{5});
                %
                if(max_lat_dVp>0)
                    www = 0.05*maxmisf/(   0.5*maxlayr*(max_lat_dVp^2)  );
                    set(h_vp_w, 'String', num2str(www)  );
                else
                    set(h_vp_w, 'String', '0'  );
                end
                %
                if(max_lat_dVs>0)
                    www = 0.05*maxmisf/(   0.5*maxlayr*(max_lat_dVs^2)  );
                    set(h_vs_w, 'String', num2str(www)  );
                else
                    set(h_vs_w, 'String', '0'  );
                end
                %
                if(max_lat_dRo>0)
                    www = 0.05*maxmisf/(   0.5*maxlayr*(max_lat_dRo^2)  );
                    set(h_ro_w, 'String', num2str(www)  );
                else
                    set(h_ro_w, 'String', '0'  );
                end
                %
                if(max_lat_dQp>0)
                    www = 0.05*maxmisf/(   0.5*maxlayr*(max_lat_dQp^2)  );
                    set(h_qp_w, 'String', num2str(www)  );
                else
                    set(h_qp_w, 'String', '0'  );
                end
                %
                if(max_lat_dQs>0)
                    www = 0.05*maxmisf/(   0.5*maxlayr*(max_lat_dQs^2)  );
                    set(h_qs_w, 'String', num2str(www)  );
                else
                    set(h_qs_w, 'String', '0'  );
                end
            end
        end
    end
    function B_start_inversion(~,~,~)
            if(isempty(FDAT))
                fprintf('No data was loaded. Please load a project.\n')
                return;
            end
            if ~isempty(inversion_is_started__global)
                if(~strcmp(inversion_is_started__global,'BW'))
                   quest = 'It is not advisable to mix Body and Surface Waves inversions. Continue?';
                   answer = questdlg(quest);
                   if strcmp(answer,'No'); return; end
                   if strcmp(answer,'Cancel'); return; end
                end
            end
            %
            bgc = [1 0.5 0.1];
            set(T2_P1_inv_button_bw,'BackgroundColor',bgc,'enable','off')
            set(T2_P1_inv_button_sw,'enable','off')
            %
            set(h_fwd_bw ,'enable','off')
            set(h_fwd_sw ,'enable','off')
            set(T2_P1_inv_button_lw,'enable','off')
            %
            set(T2_P1_inv_stop,'enable','on')
            set(T2_P1_inv_stop,'string','STOP')
            set(T2_P1_inv_stop,'BackgroundColor',bgc);
            %
            set(T2_P1_progress,'String','');       
                
            
            prev_MDLS = MDLS;
            setup_dpth_weights();

            %get curve x-ranges ids
            xmin = str2double( get(h_scale_min,'String') );
            xmax = str2double( get(h_scale_max,'String') );
            ddx   = str2double( get(h_dscale,   'String') );
            %[ixmin_id,ixmax_id] = 
            get_curve_xindex_bounds(xmin,xmax);


            %x_vec = linspace(xmin,xmax,(xmax-xmin)/ddx);
            nnx = abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx; 
            x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx); 


            ex   = str2double( get(h_ex_val,  'String') );
            fref = str2double( get(h_fref_val,'String') );  
            iii = 0;
            set(T2_P1_global_it_count,'String',strcat(num2str(global_inversion_step),' So far.'));
            togo = str2double(get(T2_P1_max_it,'String'));
            Nsurveys = size(SURVEYS,1);
            inversion_is_started__global = 'BW'; 
            the_best_energy  = min(BEST_ENERGIES);
            misfit_vector = zeros(1,Nsurveys);% 190410 
            er_vector     = zeros(1,Nsurveys);% 190410 
            while ( (Flag__stop_inversion==0) && (togo > 0) )
              iii = iii+1;
              if(iii == 1) 
                  last_MDLS = MDLS;
              else
                  last_MDLS = perturbe_models(MDLS);
              end
              %last_FDAT = FDAT;% last_FDAT{m,1} = FDAT{m,1};
              last_FDAT = FDAT;% last_FDAT{m,1} = FDAT{m,1};

              %% HERAk's routine translated by Bignardi here ! ================
              % vp       last_MDLS{model}(:,1)
              % vs       last_MDLS{model}(:,2)
              % ro       last_MDLS{model}(:,3)
              % h        last_MDLS{model}(:,4)
              % qs       last_MDLS{model}(:,5)
              % qp       last_MDLS{model}(:,6)
              % freq.    FDAT{model,1};
              %fullMisfit = 0;  %  190410
              %fuller = 0; %       190410
              fullCurve_term = 0;% 190410
              fullSlope_term = 0;% 190410
              for m = 1:Nsurveys
                %% ========================================================
                % as_Samuel(c,ro,h,q,ex,fref,f)  
                VP = last_MDLS{m}(:,1);
                VS = last_MDLS{m}(:,2);
                RO = last_MDLS{m}(:,3);
                HH = last_MDLS{m}(:,4);
                QP = last_MDLS{m}(:,5);
                QS = last_MDLS{m}(:,6);

                aswave = as_Samuel(VS,RO,HH,QS,ex,fref, x_vec);
                apwave = as_Samuel(VP,RO,HH,QP,ex,fref, x_vec);
                %last_FDAT{m,1} = FDAT{m,1};
                %warning('interpolation here');
                hvsr_teo = (aswave./apwave);

                %last_FDAT{m,2} = ( interp1(x_vec, hvsr_teo, main_scale(ixmin_id:ixmax_id) ) ).';
                last_FDAT{m,2} = 0*main_scale;
                last_FDAT{m,2}(ixmin_id:ixmax_id,1) = ( interp1(x_vec, hvsr_teo, main_scale(ixmin_id:ixmax_id) ) ).';
                %% ========================================================
                [DAF] = get_amplification_factor(x_vec,aswave);

                %% store
                [Single_Misfit,Curve_term,Slope_term,er] = get_single_model_misfit(m, last_FDAT{m,2} );
                %
                STORED_2d_vp_fits{m} = [STORED_2d_vp_fits{m}; VP.'];
                STORED_2d_vs_fits{m} = [STORED_2d_vs_fits{m}; VS.'];
                STORED_2d_ro_fits{m} = [STORED_2d_ro_fits{m}; RO.'];
                STORED_2d_hh_fits{m} = [STORED_2d_hh_fits{m}; HH.'];
                STORED_2d_qp_fits{m} = [STORED_2d_qp_fits{m}; QP.'];
                STORED_2d_qs_fits{m} = [STORED_2d_qs_fits{m}; QS.'];
                STORED_2d_daf_fits{m}= [STORED_2d_daf_fits{m}; DAF];
                %[Single_Misfit, er];
                STORED_RESULTS_2d_misfit{m} = [STORED_RESULTS_2d_misfit{m}; [Single_Misfit,er]];
                %fullMisfit = fullMisfit + Single_Misfit; % 190410
                %fuller     = fuller + er; % 190410
                fullCurve_term = fullCurve_term + Curve_term;% 190410
                fullSlope_term = fullSlope_term + Slope_term;% 190410
                misfit_vector(m) = Single_Misfit;% 190410
                er_vector(m)     = er;% 190410
                if(iii == 1) 
                    best_MISFIT_by_location(m) = Single_Misfit;% 190410
                end
              end
              %% 190410 >>>>>>>> Keep only location with decreased energy
%                   count =0;
              for m = 1:Nsurveys
                  if misfit_vector(m) >  best_MISFIT_by_location(m)
                    % this model was not improved (revert to previous) 
                    misfit_vector(m)=  best_MISFIT_by_location(m);
                    last_MDLS{m}   = MDLS{m};
                    last_FDAT{m,1} = best_FDAT{m,1};
%                         count = count+1;
                  end
              end
%                   if count>0
%                       clc
%                       fprintf('[%d]/%d were reverted\n',count,Nsurveys);
%                       pause
%                   end
              fullMisfit = sum( misfit_vector );
              fuller     = sum( er_vector );
              %% <<<<<<<< 190410

              %% ==============================================================
              global_inversion_step = global_inversion_step+1;
              set(T2_P1_global_it_count,'String',num2str(global_inversion_step));

              Rfit   = Regularize();
              Energy =  fullMisfit + Rfit;
              %fprintf('%d) ENERGY GAP[%f]pc    MISFIT[%f]  REGULARIZER[%f]\n',global_inversion_step,(100*(Energy-the_best_energy)/the_best_energy),fullMisfit,Rfit);

              %% profile misfit
              STORED_RESULTS_2d_misfit_profile = [STORED_RESULTS_2d_misfit_profile; [fullMisfit, fuller, Energy]];
                % fprintf('%d) ENERGY[%f]    MISFIT[%f]  REGULARIZER[%f]\n',global_inversion_step,Energy,fullMisfit,Rfit);
                if isnan(Energy)==1% then something went wrong and need correction
                    iii = iii-1;
                    %
                    STORED_2d_vp_fits{m} = STORED_2d_vp_fits{m}(1:(end-1),:);
                    STORED_2d_vs_fits{m} = STORED_2d_vs_fits{m}(1:(end-1),:);
                    STORED_2d_ro_fits{m} = STORED_2d_ro_fits{m}(1:(end-1),:);
                    STORED_2d_hh_fits{m} = STORED_2d_hh_fits{m}(1:(end-1),:);
                    STORED_2d_qp_fits{m} = STORED_2d_qp_fits{m}(1:(end-1),:);
                    STORED_2d_qs_fits{m} = STORED_2d_qs_fits{m}(1:(end-1),:);
                    STORED_2d_daf_fits{m}= STORED_2d_daf_fits{m}(1:(end-1),:);
                    %[Single_Misfit, er];
                    STORED_RESULTS_2d_misfit{m} = STORED_RESULTS_2d_misfit{m}(1:(end-1),:);
                    %
                    global_inversion_step = global_inversion_step-1;
                    %
                    STORED_RESULTS_2d_misfit_profile = STORED_RESULTS_2d_misfit_profile(1:(end-1),:);
                else% inversion step is acceptable
                    Store_Results(Energy, fullMisfit, Rfit, fullCurve_term,  fullSlope_term, misfit_vector);% 190410
                    togo = togo-1;
                    set(T2_P1_max_it,'String', num2str( togo  ) );
                    %fprintf('%d) ENERGY[%f]    MISFIT[%f]  REGULARIZER[%f]\n',global_inversion_step,Energy,fullMisfit,Rfit);
                    fprintf('%d) ENERGY GAP[%f]pc    REGULARIZER/MISFIT[%f]   MISFIT/[%f]   REGULARIZER[%f]\n', ...
                        global_inversion_step,(100*(Energy-the_best_energy)/the_best_energy), ...
                        Rfit/fullMisfit, ...
                        fullMisfit,Rfit);
                end
                drawnow%pause(0.005);
            end
            
            bgc = 0.9*[1 1 1];
            set(T2_P1_inv_button_bw,'BackgroundColor',bgc,'enable','on')
            set(T2_P1_inv_button_sw,'enable','on')
            %
            set(h_fwd_bw ,'enable','on')
            set(h_fwd_sw ,'enable','on')
            set(T2_P1_inv_button_lw,'enable','on')
            %
            set(T2_P1_inv_stop,'enable','off')
            set(T2_P1_inv_stop,'string','')
            set(T2_P1_inv_stop,'BackgroundColor',bgc);
            Flag__stop_inversion=0;
    end
    function B_start_inversion_SW(~,~,~)
         if(isempty(FDAT))
            fprintf('No data was loaded. Please load a project.\n')
            return;
         end
         %
        if ~isempty(inversion_is_started__global)
            if(~strcmp(inversion_is_started__global,'SW'))
               quest = 'It is not advisable to mix Body and Surface Waves inversions. Continue?';
               answer = questdlg(quest);
               if strcmp(answer,'No'); return; end
               if strcmp(answer,'Cancel'); return; end
            end
        end
        %
        bgc = [1 0.5 0.1];
        set(T2_P1_inv_button_sw,'BackgroundColor',bgc,'enable','off')
        set(T2_P1_inv_button_bw,'enable','off')
        %
        set(h_fwd_bw ,'enable','off')
        set(h_fwd_sw ,'enable','off')
        %
        set(T2_P1_inv_stop,'enable','on')
        set(T2_P1_inv_stop,'string','STOP')
        set(T2_P1_inv_stop,'BackgroundColor',bgc);
        %
        set(T2_P1_progress,'String',''); 
        
                
        prev_MDLS = MDLS;
        setup_dpth_weights();
        %
        %get curve x-ranges ids
        xmin = str2double( get(h_scale_min,'String') );
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,   'String') );
        %[ixmin_id,ixmax_id] = 
        get_curve_xindex_bounds(xmin,xmax);  
        %
        iii = 0;
        
        set(T2_P1_global_it_count,'String',strcat(num2str(global_inversion_step),' So far.'));
        togo = str2double(get(T2_P1_max_it,'String'));
        Nsurveys = size(SURVEYS,1);
        inversion_is_started__global = 'SW'; 
        the_best_energy  = min(BEST_ENERGIES);
        misfit_vector = zeros(1,Nsurveys);% 190410 
        % er_vector     = zeros(1,Nsurveys);% 190410 
        while ( (Flag__stop_inversion==0) && (togo > 0) )
          iii = iii+1;
          if(iii == 1) 
              last_MDLS = MDLS;
          else
              last_MDLS = perturbe_models(MDLS);
          end
          %last_FDAT = FDAT;% last_FDAT{m,1} = FDAT{m,1};
          last_FDAT = FDAT;% last_FDAT{m,1} = FDAT{m,1};

          %fullMisfit = 0;  %  190410
          %fuller = 0; %       190410
          fullCurve_term = 0;% 190410
          fullSlope_term = 0;% 190410
          for m = 1:Nsurveys
              drawnow
             %  set(T2_P1_progress,'String',num2str(Nsurveys+1-m));
            %  vp  vs  rho  h  Qp  Qs
            VP = last_MDLS{m}(:,1);
            VS = last_MDLS{m}(:,2);
            RO = last_MDLS{m}(:,3);
            HH = last_MDLS{m}(:,4);
            QP = last_MDLS{m}(:,5);
            QS = last_MDLS{m}(:,6);
            [FF,HV] = call_Albarello_2011(sw_nmodes, sw_nsmooth, ddx, xmax, HH,VP,VS,RO,QP,QS);
            FF=flipud(FF);
            HV=flipud(HV);

            last_FDAT{m,1} = main_scale;
            temphv = 0*main_scale;
            temphv(ixmin_id:ixmax_id,1) = ( interp1(FF, HV, main_scale(ixmin_id:ixmax_id) ) );
            last_FDAT{m,2} = temphv;%interp1(FF,HV,main_scale,'spline','extrap');
            DAF = 0;
            %% ========================================================
            %% store
            %[Single_Misfit,~,~,er] = get_single_model_misfit(m, last_FDAT{m,2} );
            [Single_Misfit,Curve_term,Slope_term,er] = get_single_model_misfit(m, last_FDAT{m,2} );% 190410

            STORED_2d_vp_fits{m} = [STORED_2d_vp_fits{m}; VP.'];
            STORED_2d_vs_fits{m} = [STORED_2d_vs_fits{m}; VS.'];
            STORED_2d_ro_fits{m} = [STORED_2d_ro_fits{m}; RO.'];
            STORED_2d_hh_fits{m} = [STORED_2d_hh_fits{m}; HH.'];
            STORED_2d_qp_fits{m} = [STORED_2d_qp_fits{m}; QP.'];
            STORED_2d_qs_fits{m} = [STORED_2d_qs_fits{m}; QS.'];
            STORED_2d_daf_fits{m}= [STORED_2d_daf_fits{m}; DAF];
            %[Single_Misfit, er];
            STORED_RESULTS_2d_misfit{m} = [STORED_RESULTS_2d_misfit{m}; [Single_Misfit,er]];
            %fullMisfit = fullMisfit + Single_Misfit; % 190410
            %fuller     = fuller + er; % 190410
            fullCurve_term = fullCurve_term + Curve_term;% 190410
            fullSlope_term = fullSlope_term + Slope_term;% 190410
            misfit_vector(m) = Single_Misfit;% 190410
            er_vector(m)     = er;% 190410
            if(iii == 1) 
                best_MISFIT_by_location(m) = Single_Misfit;% 190410
            end
          end
          %% 190410 >>>>>>>> Keep only location with decreased energy
%                   count =0;
          for m = 1:Nsurveys
              if (misfit_vector(m) >  best_MISFIT_by_location(m)) || isnan(misfit_vector(m))
                % this model was not improved (revert to previous) 
                misfit_vector(m)=  best_MISFIT_by_location(m);
                last_MDLS{m}   = MDLS{m};
                last_FDAT{m,1} = best_FDAT{m,1};
%                         count = count+1;
              end
          end
%                   if count>0
%                       clc
%                       fprintf('[%d]/%d were reverted\n',count,Nsurveys);
%                       pause
%                   end
          fullMisfit = sum( misfit_vector );
          fuller     = 0;
          %% <<<<<<<< 190410                  
          %% ==============================================================
          global_inversion_step = global_inversion_step+1;
          set(T2_P1_global_it_count,'String',num2str(global_inversion_step));

          Rfit   = Regularize();
          Energy =  fullMisfit + Rfit;
          %fprintf('%d) ENERGY GAP[%f]pc    MISFIT[%f]  REGULARIZER[%f]\n',global_inversion_step,(100*(Energy-the_best_energy)/the_best_energy),fullMisfit,Rfit);

          %% profile misfit
          STORED_RESULTS_2d_misfit_profile = [STORED_RESULTS_2d_misfit_profile; [fullMisfit, fuller, Energy]];

            if isnan(Energy)==1% then something went wrong and need correction
                iii = iii-1;
                %
                STORED_2d_vp_fits{m} = STORED_2d_vp_fits{m}(1:(end-1),:);
                STORED_2d_vs_fits{m} = STORED_2d_vs_fits{m}(1:(end-1),:);
                STORED_2d_ro_fits{m} = STORED_2d_ro_fits{m}(1:(end-1),:);
                STORED_2d_hh_fits{m} = STORED_2d_hh_fits{m}(1:(end-1),:);
                STORED_2d_qp_fits{m} = STORED_2d_qp_fits{m}(1:(end-1),:);
                STORED_2d_qs_fits{m} = STORED_2d_qs_fits{m}(1:(end-1),:);
                STORED_2d_daf_fits{m}= STORED_2d_daf_fits{m}(1:(end-1),:);
                %[Single_Misfit, er];
                STORED_RESULTS_2d_misfit{m} = STORED_RESULTS_2d_misfit{m}(1:(end-1),:);
                %
                global_inversion_step = global_inversion_step-1;
                %
                STORED_RESULTS_2d_misfit_profile = STORED_RESULTS_2d_misfit_profile(1:(end-1),:);
                fprintf('WARNING: Inversion step[%d] failed! retrying.\n',(iii+1))
            else% inversion step is acceptable
                %Store_Results(Energy,fullMisfit, fullCurve_term,  fullSlope_term);
                Store_Results(Energy, fullMisfit, Rfit, fullCurve_term,  fullSlope_term, misfit_vector);% 190410
                togo = togo-1;
                set(T2_P1_max_it,'String', num2str( togo  ) );
                %fprintf('%d) ENERGY[%f]    MISFIT[%f]  REGULARIZER[%f]\n',global_inversion_step,Energy,fullMisfit,Rfit);
                fprintf('%d) ENERGY GAP[%f]pc    REGULARIZER/MISFIT[%f]   MISFIT/[%f]   REGULARIZER[%f]\n', ...
                    global_inversion_step,(100*(Energy-the_best_energy)/the_best_energy), ...
                    Rfit/fullMisfit, ...
                    fullMisfit,Rfit);
            end
            pause(0.02);
        end

        bgc = 0.9*[1 1 1];
        set(T2_P1_inv_button_sw,'BackgroundColor',bgc,'enable','on')
        set(T2_P1_inv_button_bw,'enable','on')
        %
        set(h_fwd_bw ,'enable','on')
        set(h_fwd_sw ,'enable','on')
        %
        set(T2_P1_inv_stop,'enable','off')
        set(T2_P1_inv_stop,'string','')
        set(T2_P1_inv_stop,'BackgroundColor',bgc);
        Flag__stop_inversion=0;   
    end
    function B_stop_inversion(~,~,~)
        bgc = [1 0 0];
        set(T3_P1_inv_stop,'BackgroundColor',bgc);
        set(T3_P1_inv_stop,'String','stopping');
        set(T3_P1_inv_stop,'enable','off');
        Flag__stop_inversion = 1;
    end
    function B_stop_inversion_all(~,~,~)
        bgc = [1 0 0];
        set(T2_P1_inv_stop,'BackgroundColor',bgc);
        set(T2_P1_inv_stop,'String','stopping');
        set(T3_P1_inv_stop,'enable','off');
        Flag__stop_inversion = 1;
    end
%% TAB-2, Panel-2
    function CM_hAx_cwf_modify(~,~,~)
        L = size(weight_curv,1);
        if(L > 0)
            if ~isempty(inversion_is_started__inedipendent)
               if(~strcmp(inversion_is_started__inedipendent,''))
                   quest = 'These parameters must be set before the inversion is started and should not be modified afterwards. Continue?';
                   answer = questdlg(quest);
                   if strcmp(answer,'No'); return; end
                   if strcmp(answer,'Cancel'); return; end
               end
            end
            [boxx,boxy] = getsquare(weight_curv(1,1),weight_curv(L,1));
            drawsquare(hAx_cwf,boxx,boxy);
            
%             %[~,value] = ginput(1);% take points
%             %if Matlab_Release_num>2018% Solve ginput issuewith R2018a and above
%             if Matlab_Release_num>2017.1% Solve ginput issuewith R2017b and above
%                 [~,value] = sam2018b_ginput(1);
%             else
%                 [~,value] = ginput(1);
%             end
            [~,value] = BackwordCompatible_ginput(Matlab_Release_num, 1, hAx_cwf);% <-(MRelease, N, haxis); 200127
            if(value<0); value = 0; end
            
            %% update
            mmin = min(boxx);
            mmax = max(boxx);
            for tt = 1:L    
                if (mmin <= weight_curv(tt,1)) && (weight_curv(tt,1) <= mmax)
                    weight_curv(tt,2) = value; 
                end
            end
            plot__curve_weights(0)
        end
        setup_curve_weights();
    end
    function CM_set_logaritmic_decreasing(~,~,~)
        L = size(weight_curv,1);
        if(L > 0)
            if ~isempty(inversion_is_started__inedipendent)
               if(~strcmp(inversion_is_started__inedipendent,''))
                   quest = 'These parameters must be set before the inversion is started and should not be modified afterwards. Continue?';
                   answer = questdlg(quest);
                   if strcmp(answer,'No'); return; end
                   if strcmp(answer,'Cancel'); return; end
               end
            end
            [boxx,boxy] = getsquare(weight_curv(1,1),weight_curv(L,1));
            drawsquare(hAx_cwf,boxx,boxy);
            
            %% update
            % exp(0) = 1
            % exp(-2) = 0.13
            pt0 = min(boxx);
            pt1 = max(boxx);
            N0 = 1;  
            tau = 0.1*( pt1-pt0 );
            
            for tt = 1:L    
                if (pt0 >= weight_curv(tt,1)) 
                    N0 = weight_curv(tt,2);    
                end
                if (pt0 <= weight_curv(tt,1)) && (weight_curv(tt,1) <= pt1)
                    
                    ti = weight_curv(tt,1);
                    weight_curv(tt,2) = N0*exp( -(ti-pt0)/tau); 
                end
            end
            plot__curve_weights(0)
        end
        setup_curve_weights();
    end
    function CM_hAx_cwf_reset_to_1(~,~,~)
        if(size(weight_curv,1) > 0)
            if ~isempty(inversion_is_started__inedipendent)
               if(~strcmp(inversion_is_started__inedipendent,''))
                   quest = 'These parameters must be set before the inversion is started and should not be modified afterwards. Continue?';
                   answer = questdlg(quest);
                   if strcmp(answer,'No'); return; end
                   if strcmp(answer,'Cancel'); return; end
               end
            end
            weight_curv(:,2) = 1;
            plot__curve_weights(0)
        end
    end
    function CM_hAx_cwf_show_lin(~,~,~)
        if(size(weight_curv,1) > 0)
            curve_weights_plotmode = 0;
            plot__curve_weights(0)
        end
    end
    function CM_hAx_cwf_show_log(~,~,~)
        if(size(weight_curv,1) > 0)
            curve_weights_plotmode = 1;
            plot__curve_weights(0)
        end
    end
%% TAB-2, Panel-3
    function CM_hAx_dwf_modify(~,~,~)
        L = size(weight_dpth,1);
        if(L > 0)
            if ~isempty(inversion_is_started__inedipendent)
               if(~strcmp(inversion_is_started__inedipendent,''))
                   quest = 'These parameters must be set before the inversion is started and should not be modified afterwards. Continue?';
                   answer = questdlg(quest);
                   if strcmp(answer,'No'); return; end
                   if strcmp(answer,'Cancel'); return; end
               end
            end
            [boxx,boxy] = getsquare(weight_dpth(1,1),weight_dpth(L,1));
            drawsquare(hAx_dwf,boxx,boxy);
            
%             %[~,value] = ginput(1);% take points
%             %if Matlab_Release_num>2018% Solve ginput issuewith R2018a and above
%             if Matlab_Release_num>2017.1% Solve ginput issuewith R2017b and above
%                 [~,value] = sam2018b_ginput(1);
%             else
%                 [~,value] = ginput(1);
%             end
            [~,value] = BackwordCompatible_ginput(Matlab_Release_num, 1, hAx_dwf);% <-(MRelease, N, haxis); 200127
            if(value<0); value = 0; end
            
            %% update
            mmin = min(boxx);
            mmax = max(boxx);
            for tt = 1:L    
                if (mmin <= weight_dpth(tt,1)) && (weight_dpth(tt,1) <= mmax)
                    weight_dpth(tt,2) = value; 
                end
            end
            
            
            plot__depth_weights(0)
        end
        setup_dpth_weights();
    end
    function CM_hAx_dwf_reset_to_1(~,~,~)
        if(size(weight_dpth,1) > 0)
            if ~isempty(inversion_is_started__inedipendent)
               if(~strcmp(inversion_is_started__inedipendent,''))
                   quest = 'These parameters must be set before the inversion is started and should not be modified afterwards. Continue?';
                   answer = questdlg(quest);
                   if strcmp(answer,'No'); return; end
                   if strcmp(answer,'Cancel'); return; end
               end
            end
            weight_dpth(:,2) = 1;
            plot__depth_weights(0)
        end
    end
    function CM_hAx_dwf_show_lin(~,~,~)
        if(size(weight_dpth,1) > 0)
            depth_weights_plotmode = 0;
            plot__curve_weights(0)
        end
    end
    function CM_hAx_dwf_show_log(~,~,~)
        if(size(weight_dpth,1) > 0)
            depth_weights_plotmode = 1;
            plot__depth_weights(0)
        end
    end
%% TAB-3: =================================================  Inversion (Local)
%% TAB-3, Panel-1
    function B_lock_model(~,~,~)
        if (0 < P.isshown.id) && (P.isshown.id < length(TO_INVERT))
            if(TO_INVERT(P.isshown.id) ~= 0)
               TO_INVERT(P.isshown.id) = 2; 
               Update_survey_locations(hAx_main_geo);
               Update_survey_locations(hAx_geo);
            end
        end
    end
    function B_unlock_model(~,~,~)
        if (0 < P.isshown.id) && (P.isshown.id < length(TO_INVERT))
            if(TO_INVERT(P.isshown.id) ~= 0)
                TO_INVERT(P.isshown.id) = 1;
                Update_survey_locations(hAx_main_geo);
                Update_survey_locations(hAx_geo);
            end
        end
    end
    %
    function define_Profile(~,~,~)
        if isempty(SURVEYS); return; end
        Np = size(receiver_locations,1);
        recta_kind = 0;
%         if Matlab_Release_num>2017.1% Solve ginput issuewith R2017b and above
%             [xx,yy] = sam2018b_ginput(2, hAx_main_geo);%hAx_main_geo);
%         else
%             if Matlab_Release_num==2016.1
%                 axes(hAx_main_geo)
%                 [xx,yy] = ginput(2);
%             else
%                 [xx,yy] = ginput(2, hAx_main_geo);
%             end
%         end
        [xx,yy] = BackwordCompatible_ginput(Matlab_Release_num, 2, hAx_main_geo);% <-(MRelease, N, haxis); 200127
            
        if( (xx(1)==xx(2)) && (yy(1)==yy(2))); return; end
        dummy_ids = zeros(Np,3);
        dummy_line    = [xx,yy];
        dummy_onoff   = zeros(Np,1);% 
        %
        %axes(hAx_main_geo)
        lne = plot(hAx_main_geo,xx,yy,'k');
        %
        prompt = {'Select the ID of the farthest station','Custom name'};
        def = {'0','none'};
        %
        answer = inputdlg(prompt,'info request',[1 35],def);
        if(isempty(answer)); return; end
        %
        id_farhest = str2double(answer{1});
        profile_name = answer{2};
        if (0<id_farhest) && (id_farhest<=Np)
            % filter measurement points
            found_ids = 0;
            if(abs(xx(1)-xx(2))<0.000000001) % rect x=constant
                recta_kind = 1;
                r_distance_from_profile = abs(receiver_locations(id_farhest,1)-xx(1));
                for ii = 1:Np
                    if( abs(receiver_locations(ii,1)-xx(1)) <= r_distance_from_profile)
                        dr = receiver_locations(ii,2)-yy(1);
                        far = abs(receiver_locations(ii,1)-xx(1));
                        found_ids=found_ids+1;
                        dummy_ids(found_ids,1:3) = [ii, dr, far];
                    end
                end
            end
            if( abs(yy(1)-yy(2))<0.000000001) % rect y=constant
                r_distance_from_profile = abs(receiver_locations(id_farhest,2)-yy(1));
                for ii = 1:Np
                    recta_kind = 2;
                    if( abs(receiver_locations(ii,2)-yy(1)) <= r_distance_from_profile)
                        dr = receiver_locations(ii,1)-xx(1);
                        far = abs(receiver_locations(ii,2)-yy(1));
                        found_ids=found_ids+1;
                        dummy_ids(found_ids,1:3) = [ii, dr, far];
                    end
                end
            end
            if(recta_kind==0)% rect y=mx+q    q=y-mx            
                m1 = (yy(2)-yy(1))/(xx(2)-xx(1));
                q1 = yy(1) - m1*xx(1);
                dist = abs(receiver_locations(:,2) - (m1*receiver_locations(:,1) +q1))/sqrt(1+m1^2);% Equation 1
                r_distance_from_profile = dist(id_farhest);
                %% info
                % r1:  y = m1 x + q1 (profile)
                % r2:  y = m2 x + q2 (line through the receiver and perpendicular to r1)
                %
                % rect given endpoints
                % r1 = m1 x + q1:    (ax +by +c = 0)
                %     a = y2-y1
                %     b = x2-x1
                %     c = x2 y1 - y2 x1
                %     m1 = -a/b = -(y2-y1)/(x2-x1) 
                %     q1  = y1 -m1 x1
                %
                % distance of point p (receiver) from the rect r1 (the profile). (Equation 1)
                % dist = |yp - m1 xp -q1 | / sqrt(1 + m1^1)
                %
                % rect (r2) through a point p and perpendicular to r1 (y=m1 x +q1):
                % y = m2 xp + q2
                % m2  = -1/m1
                % q2 = yp - m2 xp == yp +xp/m1  (Equation 2)
                %
                % point of intersection of two rects
                % [ y = m2 x + q2
                % [ y = m1 x + q1
                %
                % [ y = m2 x + q2
                % [ m2 x + q2 = m1 x + q1 -> x(m2-m1) = (q1-q2)
                %
                % [ y = m2 (q1-q2)/(m2-m1)+ q2
                % [ x = (q1-q2)/(m2-m1) 
                %%
                m2 = -1/m1;
                q2 = receiver_locations(:,2) + receiver_locations(:,1)/m1;%  (Equation 2)
                xp = (q1-q2)/(m2-m1);%             Point of intersection
                yp = m2*(q1-q2)/(m2-m1)+q2;% Point of intersection 
                drs= sqrt( (xx(1)-xp).^2 + (yy(1)-yp).^2 );% distances from beginning of profile
                %
                for ii = 1:Np
                    far = dist(ii);
                    dr  = drs(ii);
                    if(xp(ii) < xx(1))
                        dr = -dr;
                    end

                    if( dist(ii) <= r_distance_from_profile)
                        found_ids=found_ids+1;
                        dummy_ids(found_ids,1:3) = [ii, dr, far];% [station-ID][distance from profile beginning][distance from profile]
                        % val = station-ID
                        % dr  = distance (along profile) from profile beginning
                        % far = distance from profile
                    end
                end
            end
            if found_ids>0% some suitable measurement were found
                dummy_ids = dummy_ids(1:found_ids,:);
                if found_ids>1% at least two station per profile
                    if ~isempty(P.profile_ids)
                        prid = size(P.profile_ids,1) +1;
                    else
                        prid=1;
                        P.profile.id=1;
                    end
                    %
                    [~,idx] = sort(dummy_ids(:,2)); % sort just the first column
                    sortedmat = dummy_ids(idx,:);   % sort the whole matrix using the sort indices
                    %
                    % check for double entries (same longitudinal distance, to be avoided)
                    original_sortedmat = sortedmat;
                    distance_checked = min(sortedmat(:,2))-1;
                    current_line=0; 
                    for pp=1:found_ids
                        [r,~]= find(original_sortedmat(:,2)==original_sortedmat(pp,2));
                        if original_sortedmat(pp,2) > distance_checked
                            current_line = current_line+1;
                            sortedmat( current_line, :) =  original_sortedmat(r(1),:);
                            distance_checked = original_sortedmat(pp,2); 
                        end
                    end
                    sortedmat = sortedmat(1:current_line,:);
                    if(isempty(sortedmat)); return; end 
                    if size(sortedmat,1)~=size(original_sortedmat,1)
                        Message = sprintf('MESSAGE: Some stations were not included in the profile\nbecause they would occupy the same location.');
                        %waitfor(warndlg(Message,'INFO'));
                        fprintf('%s\n',Message);
                    end
                    % set which surveys are included
                    dummy_onoff(sortedmat(:,1)) = 1; 
                    %
                    %
                    P.profile_ids{prid,1}   = sortedmat;
                    P.profile_line{prid,1}  = dummy_line;
                    P.profile_onoff{prid,1} = dummy_onoff;
                    P.profile_name{prid,1} = profile_name;
                    %profile_ids   = sortedmat;
                    %profile_line  = dummy_line;
                    %
                    Update_survey_locations(hAx_main_geo);
                    Update_survey_locations(hAx_geo)
                end
            end
        end
        delete(lne);
    end
    function reset_Profile(~,~,~)
        if isempty(SURVEYS); return; end
        P.profile_line = {};
        P.profile_ids  = {};
        P.profile_onoff = {};
        P.profile_name={};
        %  
        Update_survey_locations(hAx_main_geo);
        Update_survey_locations(hAx_geo)
    end
    function reset_one_Profile(~,~,~)
        if isempty(SURVEYS); return; end
        if isempty(P.profile_ids); return; end
        if size(P.profile_ids,1)<2
            P.profile_line = {};
            P.profile_ids  = {};
            P.profile_onoff = {};
            P.profile_name={};
        else

            prompt = {'Select the ID of the profile to discard'};
            def = {'0'};% {num2str(r_distance_from_profile)};
            answer = inputdlg(prompt,'ID?',1,def);
            if(isempty(answer)); return; end
            p_id = str2double(answer{1});
            if p_id > size(P.profile_ids,1); return; end
            if p_id <1; return; end

            Nprf = size(P.profile_ids,1);
            temp_line = P.profile_line;
            temp_ids = P.profile_ids;
            temp_onoff  = P.profile_onoff;
            temp_name = P.profile_name;

            P.profile_line = cell(Nprf-1,1);
            P.profile_ids = cell(Nprf-1,1);    
            P.profile_onoff = cell(Nprf-1,1);
            P.profile_name = cell(Nprf-1,1);
            nowid = 0;
            for ipid = 1:Nprf 
                if ipid == p_id; continue; end
                nowid = nowid + 1;
                P.profile_line{nowid,1} = temp_line{ipid,1};
                P.profile_ids{nowid,1}  = temp_ids{ipid,1};  
                P.profile_onoff{nowid,1} = temp_onoff{ipid,1};
                P.profile_name{nowid,1}  = temp_name{ipid,1}; 
            end
        end
        % 
        P.profile.id =1;
        Update_survey_locations(hAx_main_geo);
        Update_survey_locations(hAx_geo)
    end   
%% TAB-3, Panel-2: data
    function CM_hAx_dat_disable(~,~,~)
       [boxx,boxy] = getsquare();
       %drawsquare(hAx_dat,boxx,boxy)
       new_discards = find_graph_encosed_points( [FDAT{P.isshown.id,1},FDAT{P.isshown.id,2}], boxx,boxy);
       if(isempty(DISCARDS{P.isshown.id}))
           DISCARDS{P.isshown.id} = new_discards;
       else
           DISCARDS{P.isshown.id} = [ DISCARDS{P.isshown.id}; new_discards]; 
       end
       Show_survey(0);
    end
    function CM_hAx_dat_enable(~,~,~)
       DISCARDS{P.isshown.id} = [];
       Show_survey(0);
       %DISCARDS{P.isshown.id}%------------------------------------------ FIX  need to be more efficient
    end
    function CM_hAx_dat_show_lin(~,~,~)
        if(size(weight_curv,1) > 0)
            curve_plotmode = 0;
            Show_survey(0)
        end
    end
    function CM_hAx_dat_show_log(~,~,~)
        if(size(weight_curv,1) > 0)
            curve_plotmode = 1;
            Show_survey(0)
        end
    end
%% TAB-3, Panel-3: model
    function CM_hAx_mod_modify(~,~,~)
        if(isempty(MDLS)); return; end
        model_manager( get(hTab_mod,'Data') );
        set(hTab_mod,'Data', MDLS{P.isshown.id});
    end
%% TAB-3, Panel-4: local inversion
    function CM_hAx_keep_and_spread_model(~,~,~)
        for ii = 1:size(SURVEYS,1)
            if(ii ~= P.isshown.id)
                MDLS{ii} = MDLS{P.isshown.id};
            end
        end
    end
    function CM_hAx_keep_and_spread_left(~,~,~)
        if(P.isshown.id>1)
            MDLS{P.isshown.id-1} = MDLS{P.isshown.id};
        end
    end
    function CM_hAx_keep_and_spread_right(~,~,~)
        if(P.isshown.id<size(SURVEYS,1))
            MDLS{P.isshown.id+1} = MDLS{P.isshown.id};
        end
    end
    function CM_hAx_keep_and_spread_to(~,~,~)
        warning('Function under debug.')
        prompt = {'Select destination model'};
        def = {num2str(P.isshown.id)};
        answer = inputdlg(prompt,'Spread To',1,def)
        if(~isempty(answer))
            destination_id = str2double(answer)
            if (destination_id>0) && (destination_id<=size(SURVEYS,1))
                MDLS{destination_id} = MDLS{P.isshown.id};
                fprintf('Model %d copied to position %d.\n',P.isshown.id,destination_id)
            end
        end
    end
    function CM_hAx_double_all_layers(~,~,~)
        warning('Function under debug:CM_hAx_double_all_layers LOOK CONSEQUENCES.')
        %for ii = 1:size(SURVEYS,1)
        temp = MDLS{P.isshown.id};
        newm = zeros(2*size(temp,1)-1, size(temp,2));
        for ll = 1:size(temp,1)-1
            thick = 0.5*temp(ll,4);
            newm(2*ll-1,:) = temp(ll,:);
            newm(2*ll  ,:) = temp(ll,:);
            newm(2*ll-1,4) = thick;
            newm(2*ll  ,4) = thick;
        end
        newm(end,:) = temp(end,:);


        MDLS{P.isshown.id} = newm;
        
        Show_survey(0);
        hold(hAx_1dprof,'off');
        draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
            
    end
    function CM_hAx_double_a_layer(~,~,~)
        warning('Function under debug:CM_hAx_double_all_layers LOOK CONSEQUENCES.')
        
        prompt = {'Select layer to double'};
        def = {'0'};
        answer = inputdlg(prompt,'Unite with next',1,def);
        if(~isempty(answer))
            lid = str2double(answer{1});
            if (lid>0) && (lid<size(MDLS{P.isshown.id},1))
                temp = MDLS{P.isshown.id};
                newm = zeros( size(temp,1)+1, size(temp,2));
                countl = 0;
                for ll = 1:(size(temp,1)-1)% only layers
                    if(countl<size(newm,1))
                        if (ll~=lid)
                            countl = countl+1;
                            newm(countl,:)=temp(ll,:);
                        end
                        if (ll==lid)
                           thick = 0.5*temp(lid,4);
                           countl = countl+1; 
                           newm(countl,:) = temp(lid,:); 
                           newm(countl,4) = thick;
                           countl = countl+1;
                           newm(countl,:) = temp(lid,:); 
                           newm(countl,4) = thick; 
                           fprintf('Layer %d doubled\n',lid)
                        end
                    end
                    %pause
                    %clc
                end
                newm(end,:) = temp(end,:); 
                MDLS{P.isshown.id} = newm;
                
                %Update_survey_locations(hAx_geo);
                %Update_survey_locations(hAx_main_geo);
                Show_survey(0);
                %plot_1d_profile(hAx_1dprof);

                hold(hAx_1dprof,'off');
                draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
            end
        end
    end
    function CM_hAx_keep_unite_all_layers(~,~,~)
        warning('incomplete')
    end
    function CM_hAx_keep_and_unite_two_layers(~,~,~)
        warning('Function under debug:CM_hAx_double_all_layers LOOK CONSEQUENCES.')
        
        prompt = {'Select shallower layer'};
        def = {'0'};
        answer = inputdlg(prompt,'Unite with next',1,def);
        if(~isempty(answer))
            up = str2double(answer{1});
            dwn= up+1;
            if (up>0) && (up<size(MDLS{P.isshown.id},1)-1)
                temp = MDLS{P.isshown.id};
                newm = zeros( size(temp,1)-1, size(temp,2));
                countl = 0;
                for ll = 1:(size(temp,1)-1)% only layers
                    if(countl<size(newm,1))
                        if (ll~=dwn)
                            countl = countl+1;
                            newm(countl,:)=temp(ll,:);
                        end
                        if (ll==up)
                           newm(countl,:) = temp(up,:);%0.5*(temp(up,:) + temp(dwn,:)); 
                           newm(countl,4) = temp(up,4) + temp(dwn,4); 
                           fprintf('Layer %d united to %d\n',dwn,up)
                        end
                    end
                    %pause
                    %clc
                end
                newm(end,:) = temp(end,:); 
                MDLS{P.isshown.id} = newm;
                
                %Update_survey_locations(hAx_geo);
                %Update_survey_locations(hAx_main_geo);
                Show_survey(0);
                %plot_1d_profile(hAx_1dprof);

                hold(hAx_1dprof,'off');
                draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
            end
        end
    end
    function CM_hAx_keep_Equate_layer_number(~,~,~)
        warning('incomplete')
    end

    function CM_hAx_geo_show(~,~,~)
        if( get(T3_P1_inv,'Value') == 0 )
            prompt = {'Select survey to show'};
            def = {num2str(P.isshown.id)};
            answer = inputdlg(prompt,'aaa',1,def);
            P.isshown.id = str2double(answer);
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);
            Show_survey(0);
        end
    end
    function CM_hAx_geo_disable(~,~,~)
        if (0 < P.isshown.id) && (P.isshown.id < length(TO_INVERT))
            TO_INVERT(P.isshown.id) = 0;
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);    
        end
    end
    function CM_hAx_geo_enable(~,~,~)
        if (0 < P.isshown.id) && (P.isshown.id < length(TO_INVERT))
            TO_INVERT(P.isshown.id) = 1;
            Update_survey_locations(hAx_main_geo);
            Update_survey_locations(hAx_geo);   
        end
    end
    function B_start_inversion__independently(~,~,~)
        if(isempty(FDAT) || P.isshown.id==0)
           %fprintf('No data was loaded. Please load a project.\n')
            message = 'No data was loaded or no data was selected';
            msgbox(message,'Warning');
           return;
        end

       if(TO_INVERT(P.isshown.id) ~= 1)%                               Assuming model is not locked 
           if(TO_INVERT(P.isshown.id) == 0); msgbox('THIS MODEL IS NOT IN USE','Communication','warn'); end
           if(TO_INVERT(P.isshown.id) == 2); msgbox('THIS MODEL IS LOCKED.',   'Communication','warn'); end
       end
       if ~isempty(inversion_is_started__inedipendent)
           if(~strcmp(inversion_is_started__inedipendent,'BW'))
               quest = 'It is not advisable to mix Body and Surface Waves inversions. Continue?';
               answer = questdlg(quest);
               if strcmp(answer,'No'); return; end
               if strcmp(answer,'Cancel'); return; end
           end
       end
       bgc = [1 0.5 0.1];
       set(T3_P1_inv,'BackgroundColor',bgc,'enable','off')
       if strcmp(FLAG__PC_features,'on'); set(T3_P1_invSW,'enable','off'); end
        %
        set(T3_p1_revert,'enable','off')
        set(h_1d_spreadALL,'enable','off')
        set(h_1d_spreadR,'enable','off')
        set(h_1d_spreadL,'enable','off')
        set(h_1d_next,'enable','off') 
        set(h_1d_prev,'enable','off')
        set(h_1d_spreadTO,'enable','off')
        set(h_1d_disable,'enable','off')
        set(h_1d_enable,'enable','off')
        set(h_1d_Lock,'enable','off')
        set(h_1d_Unlock,'enable','off')
        %
        set(T3_P1_inv_stop,'enable','on')
        set(T3_P1_inv_stop,'string','STOP')
        set(T3_P1_inv_stop,'BackgroundColor',bgc);
       x_vec = get_x_ranges();
        %% init
        last_single_MDL = MDLS{P.isshown.id};
        last_single_FDAT{1,1} = main_scale;

        init_single_FDAT = cell(1,2);
        init_single_FDAT{1,1} = main_scale;            
        %% cycle
        previous_iii = independent_optimiazation_cicles(P.isshown.id);
        iii = 0;
        iii_global = previous_iii;
        %
        togo = str2double(get(T3_P1_max_it,'String'));

        inversion_is_started__inedipendent= 'BW';
        while (Flag__stop_inversion==0) && (togo > 0)%(get(hObject,'Value') && (togo > 0) )%while (get(hObject,'Value') && (togo > 0) )

            iii = iii+1;
            %fprintf('ITER[%d]\n',iii);
            iii_global = previous_iii + iii;
            set(T3_P1_it_count,'String',num2str(iii_global));
            if(iii > 1) 
                % iii == 1 is always the initial model evaluation
                %clc

                last_single_MDL = perturbe_single_model( MDLS{P.isshown.id} );
                %fprintf('perturbed!   %f\n',max(max( abs(MDLS{P.isshown.id}-last_single_MDL) )))
                %pause
            %else
            %    fprintf('model not perturbed\n')
            end
            %fprintf('%d][C] perturbation [%f][%f][%f][%f][%f][%f]\n',iii, max( abs(MDLS{P.isshown.id}-last_single_MDL) ) );
            %pause

            nc = 2;%size(FDAT,2);
            last_single_FDAT = cell(1,nc); 

            %% ====================================================
            OUT1 = single_fwd_model(last_single_MDL,x_vec);% this substitutes the commented code
            last_single_FDAT{1} = OUT1{1};
            last_single_FDAT{2} = OUT1{2};
            [DAF] = get_amplification_factor(OUT1{1},OUT1{4});

            if(iii == 1)
                init_single_FDAT{1,1} = last_single_FDAT{1,1};%                         this single optimization section: inittial model
                init_single_FDAT{1,2} = last_single_FDAT{1,2};%                         this single optimization section: inittial model
            end
            %% ====================================================
            %
            for j = 1:nc; last_FDAT{P.isshown.id,j} = last_single_FDAT{1,j}; end
            %           
            [Single_Misfit, ctrm, strm, er] = get_single_model_misfit(P.isshown.id, last_single_FDAT{2} );
            %fprintf('MOD[%d]   MISFIT[%f]\n',P.isshown.id,Single_Misfit);
            %
            %% results storage           
            Store_Single_Result(Single_Misfit,last_single_MDL, ctrm, strm);
            STORED_RESULTS_1d_misfit{P.isshown.id} = [STORED_RESULTS_1d_misfit{P.isshown.id}; [Single_Misfit, er]];
            STORED_1d_vp_fits{P.isshown.id} = [STORED_1d_vp_fits{P.isshown.id}; last_single_MDL(:,1).'];% VP.'];
            STORED_1d_vs_fits{P.isshown.id} = [STORED_1d_vs_fits{P.isshown.id}; last_single_MDL(:,2).'];% VS.'];
            STORED_1d_ro_fits{P.isshown.id} = [STORED_1d_ro_fits{P.isshown.id}; last_single_MDL(:,3).'];% RO.'];
            STORED_1d_hh_fits{P.isshown.id} = [STORED_1d_hh_fits{P.isshown.id}; last_single_MDL(:,4).'];% HH.'];
            STORED_1d_qp_fits{P.isshown.id} = [STORED_1d_qp_fits{P.isshown.id}; last_single_MDL(:,5).'];% QP.'];
            STORED_1d_qs_fits{P.isshown.id} = [STORED_1d_qs_fits{P.isshown.id}; last_single_MDL(:,6).'];% QS.'];
            STORED_1d_daf_fits{P.isshown.id}= [STORED_1d_daf_fits{P.isshown.id}; DAF];
            %
            %
            togo = togo-1;
            set(T3_P1_max_it,'String', num2str( togo  ) );
            %pause(0.002);
            drawnow
        end
        %% update
        Show_survey(0);
        hold(hAx_1dprof,'off')
        draw_1d_profile(hAx_1dprof, vfst_MDLS{P.isshown.id},'b',1);
        draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
        %plot_1d_profile(hAx_1dprof);
        hold(hAx_1dprof,'off')
        draw_Misfit_vs_it(0);

        independent_optimiazation_cicles(P.isshown.id) =  iii_global;
         set(T3_P1_it_count,'String',strcat( num2str(iii_global),' so far'));
       %
        set(T3_p1_revert,'enable','on')
        set(h_1d_spreadALL,'enable','on')
        set(h_1d_spreadR,'enable','on')
        set(h_1d_spreadL,'enable','on')
        set(h_1d_next,'enable','on') 
        set(h_1d_prev,'enable','on')
        set(h_1d_spreadTO,'enable','on')
        set(h_1d_disable,'enable','on')
        set(h_1d_enable,'enable','on')
        set(h_1d_Lock,'enable','on')
        set(h_1d_Unlock,'enable','on')
        %
       bgc = 0.9*[1 1 1];
       set(T3_P1_inv,'BackgroundColor',bgc,'enable','on')
       if strcmp(FLAG__PC_features,'on'); set(T3_P1_invSW,'enable','on'); end
        %
       set(T3_P1_inv_stop,'enable','off')
       set(T3_P1_inv_stop,'string','')
       set(T3_P1_inv_stop,'BackgroundColor',bgc);
       Flag__stop_inversion=0;
    end
    function B_start_inversion__independently_SW(~,~,~)
       if(isempty(FDAT) || P.isshown.id==0)
           %fprintf('No data was loaded. Please load a project.\n')
            message = 'No data was loaded or no data was selected';
            msgbox(message,'Warning');
           return;
       end
       if(TO_INVERT(P.isshown.id) ~= 1)%                               Assuming model is not locked 
           if(TO_INVERT(P.isshown.id) == 0); msgbox('THIS MODEL IS NOT IN USE','Communication','warn'); end
           if(TO_INVERT(P.isshown.id) == 2); msgbox('THIS MODEL IS LOCKED.',   'Communication','warn'); end
       end
       if ~isempty(inversion_is_started__inedipendent)
           if(~strcmp(inversion_is_started__inedipendent,'SW'))
               quest = 'It is not advisable to mix Body and Surface Waves inversions. Continue?';
               answer = questdlg(quest);
               if strcmp(answer,'No'); return; end
               if strcmp(answer,'Cancel'); return; end
           end
       end
        bgc = [1 0.5 0.1];
        set(T3_P1_invSW,'BackgroundColor',bgc,'enable','off')
        set(T3_P1_inv,'enable','off')
        %
        set(T3_p1_revert,'enable','off')
        set(h_1d_spreadALL,'enable','off')
        set(h_1d_spreadR,'enable','off')
        set(h_1d_spreadL,'enable','off')
        set(h_1d_next,'enable','off') 
        set(h_1d_prev,'enable','off')
        set(h_1d_spreadTO,'enable','off')
        set(h_1d_disable,'enable','off')
        set(h_1d_enable,'enable','off')
        set(h_1d_Lock,'enable','off')
        set(h_1d_Unlock,'enable','off')
        %
        set(T3_P1_inv_stop,'enable','on')
        set(T3_P1_inv_stop,'string','STOP')
        set(T3_P1_inv_stop,'BackgroundColor',bgc);
        get_x_ranges();
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,  'String') );
        %% init
        last_single_MDL = MDLS{P.isshown.id};
        last_single_FDAT{1,1} = main_scale;

        init_single_FDAT = cell(1,2);
        init_single_FDAT{1,1} = main_scale;            
        %% cycle
        previous_iii = independent_optimiazation_cicles(P.isshown.id);
        iii = 0;
        iii_global = previous_iii;
        %
        togo = str2double(get(T3_P1_max_it,'String'));

        inversion_is_started__inedipendent= 'SW';
        while (Flag__stop_inversion==0) && (togo > 0)%(get(hObject,'Value') && (togo > 0) )

            iii = iii+1;
            %fprintf('ITER[%d]\n',iii);
            iii_global = previous_iii + iii;
            set(T3_P1_it_count,'String',num2str(iii_global));
            if(iii > 1) 
                % iii == 1 is always the initial model evaluation
                %clc
                last_single_MDL = perturbe_single_model( MDLS{P.isshown.id} );
                %fprintf('perturbed!   %f\n',max(max( abs(MDLS{P.isshown.id}-last_single_MDL) )))
                %pause
            %else
            %    fprintf('model not perturbed\n')
            end
            %fprintf('%d][C] perturbation [%f][%f][%f][%f][%f][%f]\n',iii, max( abs(MDLS{P.isshown.id}-last_single_MDL) ) );
            %pause

            nc = 2;%size(FDAT,2);
            last_single_FDAT = cell(1,nc); 

            %%-------------------------------------------------
            %%% OUT1 = single_fwd_model(last_single_MDL,x_vec);% this substitutes the commented code
            %                     %  vp  vs  rho  h  Qp  Qs
            vp = last_single_MDL(:,1);
            vs = last_single_MDL(:,2);
            ro = last_single_MDL(:,3);
            hz = last_single_MDL(:,4);
            qp = last_single_MDL(:,5);
            qs = last_single_MDL(:,6);
            [FF,HV] = call_Albarello_2011(sw_nmodes, sw_nsmooth, ddx, xmax, hz,vp,vs,ro,qp,qs);
            FF=flipud(FF);
            HV=flipud(HV);

            last_single_FDAT{1} = main_scale;
            temphv = 0*main_scale;
            temphv(ixmin_id:ixmax_id,1) = ( interp1(FF, HV, main_scale(ixmin_id:ixmax_id) ) );
            % mend issues
            [rnan,~] = find(isnan(temphv)==1);
            if ~isempty(rnan)
                for p=rnan
                    %p
                    if p==1; temphv(p)=0;end
                    if p>1; temphv(p)=temphv(p-1);end
                end
            end
            last_single_FDAT{2} = temphv;%interp1(FF,HV,main_scale,'spline','extrap');
            DAF = 0;

            if(iii == 1)
                init_single_FDAT{1,1} = last_single_FDAT{1,1};%                         this single optimization section: inittial model
                init_single_FDAT{1,2} = last_single_FDAT{1,2};%                         this single optimization section: inittial model
            end
            %% ====================================================
            %
            for j = 1:nc; last_FDAT{P.isshown.id,j} = last_single_FDAT{1,j}; end
            %           
            [Single_Misfit, ctrm, strm, er] = get_single_model_misfit(P.isshown.id, last_single_FDAT{2} );
            %fprintf('MOD[%d]   MISFIT[%f]\n',P.isshown.id,Single_Misfit);
            %
            %% results storage        
            if ~isnan(Single_Misfit)
                Store_Single_Result(Single_Misfit,last_single_MDL, ctrm, strm);
                STORED_RESULTS_1d_misfit{P.isshown.id} = [STORED_RESULTS_1d_misfit{P.isshown.id}; [Single_Misfit, er]];
                STORED_1d_vp_fits{P.isshown.id} = [STORED_1d_vp_fits{P.isshown.id}; last_single_MDL(:,1).'];% VP.'];
                STORED_1d_vs_fits{P.isshown.id} = [STORED_1d_vs_fits{P.isshown.id}; last_single_MDL(:,2).'];% VS.'];
                STORED_1d_ro_fits{P.isshown.id} = [STORED_1d_ro_fits{P.isshown.id}; last_single_MDL(:,3).'];% RO.'];
                STORED_1d_hh_fits{P.isshown.id} = [STORED_1d_hh_fits{P.isshown.id}; last_single_MDL(:,4).'];% HH.'];
                STORED_1d_qp_fits{P.isshown.id} = [STORED_1d_qp_fits{P.isshown.id}; last_single_MDL(:,5).'];% QP.'];
                STORED_1d_qs_fits{P.isshown.id} = [STORED_1d_qs_fits{P.isshown.id}; last_single_MDL(:,6).'];% QS.'];
                STORED_1d_daf_fits{P.isshown.id}= [STORED_1d_daf_fits{P.isshown.id}; DAF];
                %
                %
                togo = togo-1;
                set(T3_P1_max_it,'String', num2str( togo  ) );
            else
                fprintf('Retrying it %d\n',iii)
                iii=iii-1;
            end
            if(Flag__stop_inversion==1); break; end
            drawnow%pause(0.002);
        end

        Show_survey(0);
        hold(hAx_1dprof,'off')
        draw_1d_profile(hAx_1dprof, vfst_MDLS{P.isshown.id},'b',1);
        draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
        %plot_1d_profile(hAx_1dprof);
        hold(hAx_1dprof,'off')
        draw_Misfit_vs_it(0);

        independent_optimiazation_cicles(P.isshown.id) =  iii_global;
        set(T3_P1_it_count,'String',strcat( num2str(iii_global),' so far'));
       
        %
        set(T3_p1_revert,'enable','on')
        set(h_1d_spreadALL,'enable','on')
        set(h_1d_spreadR,'enable','on')
        set(h_1d_spreadL,'enable','on')
        set(h_1d_next,'enable','on') 
        set(h_1d_prev,'enable','on')
        set(h_1d_spreadTO,'enable','on')
        set(h_1d_disable,'enable','on')
        set(h_1d_enable,'enable','on')
        set(h_1d_Lock,'enable','on')
        set(h_1d_Unlock,'enable','on')
        %
       
       
       bgc = 0.9*[1 1 1];
       set(T3_P1_invSW,'BackgroundColor',bgc,'enable','on')
        set(T3_P1_inv,'enable','on')
        %
       set(T3_P1_inv_stop,'enable','off')
       set(T3_P1_inv_stop,'string','')
       set(T3_P1_inv_stop,'BackgroundColor',bgc);
       Flag__stop_inversion=0;
    end    
    function B_revert_1d(~,~,~)
        if(~isempty(FDAT))
            MDLS = prev_MDLS;  

            BEST_SINGLE_MODELS = prev_BEST_SINGLE_MODELS;
            best_FDAT = prev_best_FDAT;
            BEST_SINGLE_MISFIT = prev_BEST_SINGLE_MISFIT;

            independent_optimiazation_cicles(P.isshown.id) = prev_single_it;
            set(T3_P1_it_count,'String',strcat( num2str(independent_optimiazation_cicles(P.isshown.id)),' so far'));


            %B_start_model();
            last_FDAT = multiple_fwd_model();
            Show_survey(0);
        else
            fprintf('No data was loaded. Please load a project.\n')
        end
    end
    function B_hAx_model_profile(~,~,parameter_id)
        property_1d_to_show = parameter_id;
        
        %plot_1d_profile(hAx_1dprof);
        hold(hAx_1dprof,'off');
        if( get(T3_P1_inv,'Value') == 0 )
            Show_bestmodels_family(0);
        else
            draw_1d_profile(hAx_1dprof, vfst_MDLS{P.isshown.id},'b',1);
            draw_1d_profile(hAx_1dprof,      MDLS{P.isshown.id},'k',1);    
        end
    end
%% TAB-4: =================================================
    function BT_refresh_modelview(~,~,~)
        bgc = [1 0.5 0.1];
        set(hRefresh,'BackgroundColor',bgc,'enable','off','String','Wait...')
        drawnow
        %
        refresh_models_list2D();
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
        if(get(hwi23D,'Value') == 2)
            plot_2d_profile( 0,property_23d_to_show);
        end
        bgc = 0.9*[1 1 1];
        set(hRefresh,'BackgroundColor',bgc,'enable','on','String','Refresh')
    end
    function BT_show_media(~,~,parameter_id)
        property_23d_to_show = parameter_id;
        %
        refresh_models_list2D();
        %
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
        if(get(hwi23D,'Value') == 2)
            plot_2d_profile( 0,property_23d_to_show);
        end
        bgc = 0.9*[1 1 1];
        set(hRefresh,'BackgroundColor',bgc,'enable','on','String','Refresh')
    end
    function Slider0_Callback(hObject, eventdata, handles)%             x-
        slider_value = get(hObject,'Value');
        cutplanes(1) =  slider_value;% x- x+ y- y+ z- z+
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
    end
    function Slider0b_Callback(hObject, eventdata, handles)%            x+
        slider_value = get(hObject,'Value');
        cutplanes(2) =  slider_value;% x- x+ y- y+ z- z+
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
    end
    function Slider1_Callback(hObject, eventdata, handles)%             y-
        slider_value = get(hObject,'Value');
        cutplanes(3) =  slider_value;% x- x+ y- y+ z- z+
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
    end
    function Slider1b_Callback(hObject, eventdata, handles)%            y+
        slider_value = get(hObject,'Value');
        cutplanes(4) =  slider_value;% x- x+ y- y+ z- z+
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
    end
    function Slider2_Callback(hObject, eventdata, handles)%             z-
        slider_value = get(hObject,'Value');
        cutplanes(5) =  slider_value;% x- x+ y- y+ z- z+
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
    end
    function Slider2b_Callback(hObject, eventdata, handles)%            z+
        slider_value = get(hObject,'Value');
        cutplanes(6) =  slider_value;% x- x+ y- y+ z- z+
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
    end
    function ResetSlices_Callback(hObject, eventdata, handles)
        set(Slider0,'Value',0); set(Slider0b,'Value',1);
        set(Slider1,'Value',0); set(Slider1b,'Value',1);
        set(Slider2,'Value',0); set(Slider2b,'Value',1);
        %isslice = dim;
        cutplanes = [0 1 0 1 0 1];
        if(get(hwi23D,'Value') == 1)
            plot_3d(0,property_23d_to_show);
        end
        if(get(hwi23D,'Value') == 2)
            plot_2d_profile( 0,property_23d_to_show);
        end
    end
%% TAB-5: =================================================
%% TAB-5, Panel-1
    function B_conf_backX(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = conf_1d_to_show_x;
            switch(conf_1d_to_show_x)
                case 0; val = Ndat; 
                case 1; val = Ndat;    
                otherwise; val = val -1;    
            end
            conf_1d_to_show_x = val;
            
            Update_confidence_view_x();
        end
    end
    function B_conf_nextX(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = conf_1d_to_show_x;
            switch(conf_1d_to_show_x)
                case 0; val = 1; 
                case Ndat; val = 1;    
                otherwise; val = val +1;    
            end
            conf_1d_to_show_x = val;
            
            Update_confidence_view_x();
        end
    end

    function B_conf_backY(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = conf_1d_to_show_y;
            switch(conf_1d_to_show_y)
                case 0; val = Ndat; 
                case 1; val = Ndat;    
                otherwise; val = val -1;    
            end
            conf_1d_to_show_y = val;
            
            Update_confidence_view_y();
        end
    end
    function B_conf_nextY(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = conf_1d_to_show_y;
            switch(conf_1d_to_show_y)
                case 0; val = 1; 
                case Ndat; val = 1;    
                otherwise; val = val +1;    
            end
            conf_1d_to_show_y = val;
            
            Update_confidence_view_y();
        end
    end

    function confidence_update_misfit(~,~,~)
        procede = 1;
        vala =get( hconf_xprop ,'value');%  parameter name 1
        valb =get( hconf_yprop ,'value');%  parameter name 2
        nlaya=get( hconf_xlay  ,'value');% id of layer under study 1
        nlayb=get( hconf_ylay  ,'value');% id of layer under study 2

        if((vala>3) && (nlaya>=size(MDLS{conf_1d_to_show_x},1))) ||  ((valb>3) && (nlayb>=size(MDLS{conf_1d_to_show_y},1))) 
           procede = 0; 
           Message = 'The half space investigation is not available for H Qp and Qs parameters.';
           msgbox(Message,'Warning'); 
        end
        if( (vala==0) || (valb==0) || (nlaya==0) || (nlayb==0) )
            procede = 0;
        end
        
        if(procede == 1)
            if( (conf_1d_to_show_x ~= 0) && ( conf_1d_to_show_y ~= 0) )
                if(conf_1d_to_show_x == conf_1d_to_show_y)
                    if( independent_optimiazation_cicles(conf_1d_to_show_x) )
                        fprintf('Same  - model - confidence\n')
                        [vpfit,vsfit,rofit,hhfit,qpfit,qsfit,dafit] = Update_confidence_data();
                        [SS,poten, X1,X2, var1,var2] = confidence_get_limits(vpfit,vsfit,rofit,hhfit,qpfit,qsfit,dafit,  vala,valb, nlaya,nlayb);
                    else
                        message = 'Please run the inversion of this curve prior to attempt its confidence calculation.';
                        msgbox(message,'Warning');
                        return;
                    end
                else
                    fprintf('Cross - model - confidence\n')
                    if(global_inversion_step)
                        [vpfitx,vsfitx,rofitx,hhfitx,qpfitx,qsfitx,dafitx, ...
                          vpfity,vsfity,rofity,hhfity,qpfity,qsfity,dafity] = Update_confidence_data_x2();
                        [SS,poten, X1,X2, var1,var2] = confidence_get_limits_x2(vpfitx,vsfitx,rofitx,hhfitx,qpfitx,qsfitx,dafitx,vpfity,vsfity,rofity,hhfity,qpfity,qsfity,dafity, vala,valb, nlaya,nlayb);
                        %confidence_plot(SS,poten, X1,X2, var1,var2, vala,valb, nlaya,nlayb);
                    else
                        message = 'Please run Profile inversion prior to attempt cross-measurement confidence.';
                        msgbox(message,'Warning');
                        return;
                    end
                end
                
                if(~isempty(SS))
                    %set(hfig,'CurrentAxes',hax);
                    %set(H.gui,'CurrentAxes',hAx_1d_confidence);
                    confidence_plot(0, SS,poten, X1,X2, var1,var2, vala,valb, nlaya,nlayb);
                end
            end
        end
    end
%% TAB-6: =================================================
%% TAB-6, Panel-1
    function B_sns_back(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = sns_1d_to_show;
            switch(sns_1d_to_show)
                case 0; val = Ndat; 
                case 1; val = Ndat;    
                otherwise; val = val -1;    
            end
            sns_1d_to_show = val;
            
            Update_sensitivity_view();
        end
    end
    function B_sns_next(~,~,~)
        Ndat = size(FDAT,1);
        if(Ndat>0)
            val = sns_1d_to_show;
            switch(sns_1d_to_show)
                case 0; val = 1; 
                case Ndat; val = 1;    
                otherwise; val = val +1;    
            end
            sns_1d_to_show = val;
            
            Update_sensitivity_view()
        end
    end
    function sensitivity_update_misfit(~,~,~)
        procede = 1;
        idx = sns_1d_to_show;
        
        %% x-range
        xmin = str2double( get(h_scale_min,'String') );
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,   'String') );
        get_curve_xindex_bounds(xmin,xmax);%                            get new x-scale
        nnx = abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx; 
        x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx); 
            
        ex   = str2double( get(h_ex_val,  'String') );
        fref = str2double( get(h_fref_val,'String') );
        curve_data = FDAT{1,2}(ixmin_id:ixmax_id,1).';
        %%
        [par_id, layer] = sensitivity_parameter_id();
        if par_id==1, SN_parname = strcat('Vp-', num2str(layer) ); end
        if par_id==2, SN_parname = strcat('Vs-', num2str(layer) ); end
        if par_id==3, SN_parname = strcat('Ro-', num2str(layer) ); end
        if par_id==4, SN_parname = strcat('H-' , num2str(layer) ); end
        if par_id==5, SN_parname = strcat('Qp-', num2str(layer) ); end
        if par_id==6, SN_parname = strcat('Qs-', num2str(layer) ); end
        SN_centralval = MDLS{idx}(layer, par_id);
        
        pcv = str2double(get(hsns_bound,'String'));% variation
        pcs = str2double(get(hsns_step,'String'));%  step
        warning('Samuel: set physical bounds here')
        
        maxv = SN_centralval*(1 + pcv/100);  
        minv = SN_centralval*(1 - pcv/100);
        dv = SN_centralval*(pcs/100); 
        SN_parscale = linspace(minv,maxv, (fix((maxv-minv)/dv)+1) );   
        SN_xscale   = main_scale(ixmin_id:ixmax_id);
        
        Ncurves = length(SN_parscale);
        idxn = ixmax_id-ixmin_id+1;
        SN_curves = zeros(Ncurves, idxn);% store teo curves(future plots)
        SN_dtamsf = zeros(Ncurves, idxn);% store sensitivity matrix
        
        if( (par_id>3) && (layer >= size(MDLS{idx},1))  )
           procede = 0; 
           Message = 'The half space investigation is not available for H Qp and Qs parameters.';
           msgbox(Message,'Warning')
        end
        if(procede == 1)
            %% actual misfit(f)
            M0 = MDLS{idx};
            VP = M0(:,1);
            VS = M0(:,2);
            RO = M0(:,3);
            HH = M0(:,4);
            QP = M0(:,5);
            QS = M0(:,6);

            aswave = as_Samuel(VS,RO,HH,QS,ex,fref, x_vec);
            apwave = as_Samuel(VP,RO,HH,QP,ex,fref, x_vec);
            hvsr_teo = (aswave./apwave);
            hvsr_teo = interp1(x_vec, hvsr_teo, SN_xscale).';% store teo curves(future plots)
            misfit_vs_f0 = (hvsr_teo - curve_data).^2;

            %% others  misfit(f)
            for p = 1:length(SN_parscale)
                M0 = MDLS{idx};
                M0(layer, par_id) = SN_parscale(p);
                VP = M0(:,1);
                VS = M0(:,2);
                RO = M0(:,3);
                HH = M0(:,4);
                QP = M0(:,5);
                QS = M0(:,6);

                aswave = as_Samuel(VS,RO,HH,QS,ex,fref, x_vec);
                apwave = as_Samuel(VP,RO,HH,QP,ex,fref, x_vec);

                hvsr_teo = (aswave./apwave);
                hvsr_teo = interp1(x_vec, hvsr_teo, SN_xscale).';% store teo curves(future plots)
                SN_curves(p,:) = hvsr_teo;
                misfit_vs_f = (hvsr_teo - curve_data).^2;

                SN_dtamsf(p,:) = misfit_vs_f - misfit_vs_f0;
            end
            for ii=1:size(SN_dtamsf,2)
                SN_dtamsf(:,ii) = SN_dtamsf(:,ii)/max(abs(SN_dtamsf(:,ii)));
            end
            sensitivity_plot(0);   
        end
    end
%% *********************** MORE FUNCTIONS *********************************
    %% INITs and Updates
    function INIT_tool_variables()  
        fprintf('...init tool variables.\n')
        INIT_FDATS();
        INIT_MDLSS();
        INIT_LOCK_TABLE();
        INIT_LOCATIONS();
        INIT_PROFILING();
        
        N = size(SURVEYS,1);
        TO_INVERT = ones(1,N); 
        DISCARDS  = cell(1,N);
        %BREAKS    = zeros(1,N-1);
        
        BEST_SINGLE_MISFIT = realmax*ones(1,N);
        BEST_SINGLE_MODELS  = MDLS;

        %% weights on x-scale for the curves ==============================
        xmin  = 1e18;
        xmax  = 0;
        nxpt = 0;
        
        for d = 1:size(FDAT,1)
            L = length(FDAT{d,2});
            if(xmin > FDAT{d,1}(1)); xmin=FDAT{d,1}(1); end 
            if(FDAT{d,1}(L) > xmax); xmax=FDAT{d,1}(L); end 
            if(nxpt < L); nxpt = L; end
        end
        nxpt= 4*nxpt;
        
        
        %a = log10(xmin);
        %b = log10(xmax);
        weight_curv = ones(nxpt,2);
        weight_curv(:,1) = (linspace(xmin,xmax,nxpt)).';
        
        plot__curve_weights(0);  
        setup_curve_weights();
        %% weights on depth for the curves ================================
        [dzmax] = get_max_depth();
        weight_dpth = ones(n_depth_levels,2);
        weight_dpth(:,1) = linspace(0,dzmax,n_depth_levels);
        plot__depth_weights(0);
        setup_dpth_weights();
        if(isempty(USER_PREFERENCE_Subsurface_model_interpolation))
            nx_ticks = max(10,size(SURVEYS,1));
            ny_ticks = max(10,size(SURVEYS,1));
            nz_ticks = size(weight_dpth,1);
        else
            nx_ticks = USER_PREFERENCE_Subsurface_model_interpolation(1);
            ny_ticks = USER_PREFERENCE_Subsurface_model_interpolation(2);
            nz_ticks = USER_PREFERENCE_Subsurface_model_interpolation(3);
        end
        if(isempty(USER_PREFERENCE_Subsurface_model_color_limits))
            color_limits = [200, 3000];
        else
            color_limits = USER_PREFERENCE_Subsurface_model_color_limits;
        end
        if strcmp(USER_PREFERENCE_Subsurface_model_colormap,'')
            color_map='Jet';
        else
            color_map=USER_PREFERENCE_Subsurface_model_colormap;
        end
        %% results storage
        INIT_STORAGE();  
        %%
        %% more
        refresh_models_list2D();
        fprintf('[Initialization complete]\n')
    end
    function INIT_FDATS()
		fprintf('...init data space.\n')
        Ndata = size(FDAT,1);
        last_FDAT = cell( Ndata, 2);
        best_FDAT = cell( Ndata, 2);
        prev_best_FDAT = cell( Ndata, 2); 
        %% setup main scale
        main_scale =[];
        x_mins     = zeros(1,Ndata);
        x_maxs    = zeros(1,Ndata);
        x_lengths = zeros(1,Ndata);
        for iij = 1:Ndata
            if( ~isempty( FDAT{iij,1} )  )
                x_mins(iij)     = min(FDAT{iij,1});
                x_maxs(iij)    = max(FDAT{iij,1});
                x_lengths(iij) = length(FDAT{iij,1});
            end
        end
        
        x_min_min = max(x_mins);% most conservative choice
        x_max_max = min(x_maxs);
        nmax           = max(x_lengths);
        
        % get the main-scale corresponding to the most conservative choice
        for iij = 1:Ndata% get the first valid mainscale (most conservative)
            if( ~isempty( FDAT{iij,1} )  )
                if( (min(FDAT{iij,1}) == x_min_min) && (max(FDAT{iij,1}) == x_max_max) && (length(FDAT{iij,1}) == nmax) )
                    main_scale = FDAT{iij,1};% found good reference frequency scale
                    break;
                end
            end
        end
        
        % most conservative choice not available: select the first
        if( isempty( main_scale ) )          
            fprintf('MESSAGE: Data appares to be defined on different frequency scales\n')
            fprintf('    Using the frequency scale from the first valid data-file as a reference and\n') 
            fprintf('    checking all files whether interpolation on a common frequency scale is necessary.\n')
            for iij = 1:Ndata% get the first valid mainscale (most conservative)
                if( ~isempty( FDAT{iij,1} )  )
                    main_scale = FDAT{iij,1};
                    break;
                end
            end
            if( isempty(main_scale) )% NO main scale can be found
                fprintf('MESSAGE: NO REFERENCE FREQUENCY SCALE CAN BE FOUND. Contact the developer.\n')
                error('stopping the program.')
            end
            
            %check for interpolation
            for iij = 1:Ndata% get the first valid mainscale (most conservative)
                if(  (FDAT{iij,1}(1)~=main_scale(1)) || (FDAT{iij,1}(end)~=main_scale(end))  || (length(FDAT{iij,1})~=length(main_scale)) )
                    newhv = spline(FDAT{iij,1},FDAT{iij,2}, main_scale);
                    FDAT{iij,2} = newhv;
                    %
                    if(~isempty(FDAT{iij,3}) )
                        newEr = spline(FDAT{iij,1},FDAT{iij,3}, main_scale);
                        FDAT{iij,3} = newEr;
                    end
                    %
                    FDAT{iij,1} = main_scale;% record freq. scale
                    %
                    fprintf('[%d][%s] was interpolated on a new frequency scale.\n',iij, SURVEYS{iij,2});
                else
                    fprintf('[%d][%s] is OK.\n',iij, SURVEYS{iij,2});
                end
            end
        end
        
        independent_optimiazation_cicles = zeros(1,Ndata);
        view_min_scale = min(main_scale);
        view_max_scale = max(main_scale);
    end

    function INIT_MDLSS()
        fprintf('...init models space.\n')
        last_MDLS = MDLS;
        prev_MDLS = MDLS;
        vfst_MDLS = MDLS;
    end
    function INIT_STORAGE()
        fprintf('...init storages.\n')
        Nsurveys = size(SURVEYS,1);
        %% 1D independently
        STORED_RESULTS_1d_misfit= cell(1,Nsurveys);
        STORED_1d_vp_fits = cell(1,Nsurveys);                  
        STORED_1d_vs_fits = cell(1,Nsurveys);
        STORED_1d_ro_fits = cell(1,Nsurveys);
        STORED_1d_hh_fits = cell(1,Nsurveys);
        STORED_1d_qp_fits = cell(1,Nsurveys);
        STORED_1d_qs_fits = cell(1,Nsurveys);
        STORED_1d_daf_fits= cell(1,Nsurveys);
        %% 2D at the same time 
        STORED_RESULTS_2d_misfit= cell(1,Nsurveys);
        STORED_2d_vp_fits = cell(1,Nsurveys);                  
        STORED_2d_vs_fits = cell(1,Nsurveys);
        STORED_2d_ro_fits = cell(1,Nsurveys);
        STORED_2d_hh_fits = cell(1,Nsurveys);
        STORED_2d_qp_fits = cell(1,Nsurveys);
        STORED_2d_qs_fits = cell(1,Nsurveys);
        STORED_2d_daf_fits= cell(1,Nsurveys);
        %BEST_MISFITS_by_location = cell(1,Nsurveys);
        %% results list
        BEST_SINGLE_MISFIT = cell(Nsurveys,1);%{P.isshown.id}(id) = Single_Misfit;
        for m = 1:Nsurveys; BEST_SINGLE_MISFIT{m} = realmax()*ones(NresultsToKeep,1); end%{P.isshown.id}(id) = Single_Misfit;
        prev_BEST_SINGLE_MISFIT = BEST_SINGLE_MISFIT;
        %
        BEST_SINGLE_MODELS = cell(NresultsToKeep,Nsurveys);
        prev_BEST_SINGLE_MODELS = BEST_SINGLE_MODELS;
        
        Misfit_vs_Iter = cell(Nsurveys + 1, 1);
        for m = 1:Nsurveys; Misfit_vs_Iter{m} = []; end
    end
    function INIT_LOCK_TABLE()
        Nmod = size(MDLS,2);
        maxlay = 0;
        for ir=1:Nmod
            Nthis = size(MDLS{ir},1);
            if(maxlay < Nthis); maxlay = Nthis; end
        end
        % vp vs ro h qp qs
        LKT = ones(maxlay, 6);
        LKT(:,3)   = 0;
        LKT(:,5:6) = 0;
        LKT(end,:) = 0;

		RCT = zeros(maxlay, 1);% column1: relax Vp/Vs constrain
    end
    function INIT_LOCATIONS()
        Np = size(SURVEYS,1);
        receiver_locations = zeros(Np,3);
        for p = 1:Np
            receiver_locations(p,1:3) = SURVEYS{p,1};
        end
        
        % reciprocal weighted distances
        r_reciprocicity = zeros(Np);
        for pi = 1:Np
            for pj = 1:Np
                if(pj>pi)% upper triangular matrix
                    r_reciprocicity(pi,pj) = sqrt( sum( (receiver_locations(pi,:)-receiver_locations(pj,:)).^2 ) );
                    r_reciprocicity(pj,pi) = r_reciprocicity(pi,pj);
                end
            end
        end
        
        %% minimum distance: weight = 1.0
        %%                   weight = 0.1
        r_reciprocicity = r_reciprocicity/max(max(r_reciprocicity));% normal: 1 = maximum distance
        r_reciprocicity = 1.1-r_reciprocicity;
        r_reciprocicity = r_reciprocicity - 1.1*eye(Np);
        r_reciprocicity = r_reciprocicity/max(max(r_reciprocicity));
    end
    function INIT_PROFILING()
%         Np = size(SURVEYS,1);
%         Nf = size(FDAT{1,1},1);% Corve same length
%         CXList = zeros(Nf,Np);
%         CYList = zeros(Nf,Np);
%         for m = 1:Np
%             CXList(:,m) = FDAT{m, 1};% WARNING: works only if curves ave the same length !!!
%             CYList(:,m) = FDAT{m, 2};
%         end
    end
    function Update_survey_locations(hhdl)
        if nargin>0
            if (hhdl==hAx_main_geo) || (hhdl==hAx_geo) 
                set(H.gui,'CurrentAxes',hhdl);
                hold(hhdl,'off')
                plot(0,0)
                cla(hhdl)
            end
        else
            hfig= figure('name','Survey geometry'); 
            hhdl= axes('Parent',hfig,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
            set(hfig,'CurrentAxes',hhdl);
        end
        
        hold(hhdl,'on')
%         if(hhdl==hAx_main_geo) || (hhdl==hAx_geo)
%             set(H.gui,'CurrentAxes',hhdl);
%         end
%         hold(hhdl,'off')
        %
        Nhv = size(SURVEYS,1);
        XY= zeros(Nhv,2);
        for ri = 1:Nhv; XY(ri,1:2) = SURVEYS{ri,1}(1:2); end
        
        %% plot measuremet locations
        for p = 1:Nhv
            colr = [0 0 0];
            if TO_INVERT(p) == 0;  colr = [1.0 0.0 0.0];  end% not to be used in inversion
            if TO_INVERT(p) == 2;  colr = [0.0 1.0 0.0];  end% LOCKED: not modify during inversion
                
            plot(hhdl, XY(p,1), XY(p,2), 'marker','o','markerfacecolor',colr,'markersize',8); 
            hold(hhdl,'on')
            text(XY(p,1), XY(p,2)+0.1, strcat('R',num2str(p)),'HorizontalAlignment','left');
        end
        %% plot selected data
        if (P.isshown.id > 0)
            plot(hhdl, XY(P.isshown.id,1),XY(P.isshown.id,2),'or', 'markersize',15);
            hold(hhdl,'on')
            if(hhdl==hAx_main_geo)
                set(T1_PC_dataid_txt,   'String', num2str(P.isshown.id)   );
                set(T1_PC_datafile_txt, 'String', SURVEYS{P.isshown.id,2} );
                set(T1_PC_modelfile_txt,'String', MODELS{P.isshown.id,1} );
                %
                % profiles
                if isempty(P.profile_ids)
                    Prf_avail='0';
                    Prf_active='0';
                else
                    Prf_avail  = num2str( size(P.profile_ids,1) );
                    Prf_active = num2str( P.profile.id );
                end
                set(T1_PC_n_of_profiles_txt,  'String', Prf_avail);
                set(T1_PC_active_profiles_txt,'String', Prf_active );
            end
            if(hhdl==hAx_geo); set(T3_P1_txt,'String',SURVEYS{P.isshown.id,2}); end
            
        end
        %% subset profile
        if(~isempty(P.profile_line))
            for ii=1:size(P.profile_line,1)
                if(~isempty(P.profile_line{ii,1}))
                    plot(hhdl, P.profile_line{ii,1}(:,1), P.profile_line{ii,1}(:,2),'r','linewidth',2); hold(hhdl,'on')
                    if strcmp(P.profile_name{ii,1},'none')
                        text(P.profile_line{ii,1}(end,1), P.profile_line{ii,1}(end,2),strcat('Prof.',num2str(ii))); hold(hhdl,'on')
                    else
                        text(P.profile_line{ii,1}(end,1), P.profile_line{ii,1}(end,2),strcat('(',num2str(ii),') ',P.profile_name{ii,1})); hold(hhdl,'on')
                    end
                end
            end
        end
        drawnow
       
        hold(hhdl,'on')
        xlim(hhdl, [min(XY(:,1))-1, max(XY(:,1))+1]);
        ylim(hhdl, [min(XY(:,2))-1, max(XY(:,2))+1]);
        xlabel(hhdl, 'X');
        ylabel(hhdl, 'Y');
        grid on
        
        %% breaks
        if(~isempty(BREAKS))
            for b=1:length(BREAKS)
                if BREAKS(b)==1
                    x0=SURVEYS{b-1,1}(1);
                    x1=SURVEYS{b  ,1}(1);
                    xmid = (x1+x0)/2;
                    plot(hhdl, [xmid,xmid],[min(XY(:,2))-1, max(XY(:,2))+1]/4,'--r');% break line
                end
            end
        end
        drawnow
    end
    function Update_profile_locations(hhdl)
        if isempty(P.profile_ids); return; end
        if nargin>0
            if (hhdl==hAx_main_geo)
                set(H.gui,'CurrentAxes',hhdl);
                hold(hhdl,'off')
                cla(hhdl)
            end
        else
            figure('name','Survey geometry');
            hhdl  = gca; 
            %get(h_fig,'CurrentAxes');
        end
        hold(hhdl,'on')
        %
        Nhv = size(SURVEYS,1);
        XY= zeros(Nhv,2);
        for ri = 1:Nhv; XY(ri,1:2) = SURVEYS{ri,1}(1:2); end
        
        hold(hhdl,'on')
        %% plot measuremet locations (color depending on profile)
        for p = 1:Nhv% show
            colr = [0 0 0];
            if ~isempty(P.profile_onoff{P.profile.id,1})
                if P.profile_onoff{P.profile.id,1}(p) == 1;  colr = [0.0 1.0 0.0];  end% Point is included in the profile
            end
            plot(XY(p,1), XY(p,2), 'marker','o','Color',colr,'markerfacecolor',colr,'markersize',8);
            hold(hhdl,'on')
            text(XY(p,1), XY(p,2), strcat(' R',num2str(p)),'HorizontalAlignment','left');
        end
        %% subset profile
        %plot(hhdl, P.profile_line{P.profile.id,1}(:,1), P.profile_line{P.profile.id,1}(:,2),'r','linewidth',2); hold(hhdl,'on')
        %text(P.profile_line{P.profile.id,1}(end,1), P.profile_line{P.profile.id,1}(end,2),strcat('Prof.',num2str(P.profile.id))); hold(hhdl,'on')
        if(~isempty(P.profile_line))
            for ii=1:size(P.profile_line,1)
                colr = 'k';
                linw = 1;
                if(~isempty(P.profile_line{ii,1}))
                    if ii==P.profile.id
                        colr = 'r';
                        linw = 2;
                    end
                    plot(hhdl, P.profile_line{ii,1}(:,1), P.profile_line{ii,1}(:,2),colr,'linewidth',linw); hold(hhdl,'on')
                    if strcmp(P.profile_name{ii,1},'none')
                        text(P.profile_line{ii,1}(end,1), P.profile_line{ii,1}(end,2),strcat('Prof.',num2str(ii))); hold(hhdl,'on')
                    else
                        text(P.profile_line{ii,1}(end,1), P.profile_line{ii,1}(end,2),strcat('(',num2str(ii),') ',P.profile_name{ii,1})); hold(hhdl,'on')
                    end
                end
            end
        end
       
        % info profiles
        if isempty(P.profile_ids)
            Prf_avail='0';
            Prf_active='0';
        else
            Prf_avail  = num2str( size(P.profile_ids,1) );
            Prf_active = num2str( P.profile.id );
        end
        set(T1_PC_n_of_profiles_txt,  'String', Prf_avail);
        set(T1_PC_active_profiles_txt,'String', Prf_active );
        %
        grid on
        drawnow
    end


    function Update_confidence_view_x()
        idx = conf_1d_to_show_x;
        set(T5_P1_txtx,'String',SURVEYS{idx,2});
        
        nlayx = size(MDLS{idx},1)-1;%% FIX: half space not included
        set(hconf_xlay,'string', strvcat(num2str([(1:nlayx)']),'Hs') );
    end
    function Update_confidence_view_y()
        idy = conf_1d_to_show_y;
        set(T5_P1_txty,'String',SURVEYS{idy,2});
        
        nlayy = size(MDLS{idy},1)-1;%% FIX: half space not included
        set(hconf_ylay,'string', strvcat(num2str([(1:nlayy)']),'Hs') );
    end
    function Update_sensitivity_view()
        idx = sns_1d_to_show;
        set(T6_P1_txtx,'String',SURVEYS{idx,2});
        
        nlayx = size(MDLS{idx},1)-1;%% FIX: half space not included
        set(hsns_xlay,'string', strvcat(num2str([(1:nlayx)']),'Hs') );
    end
    function [vpfit,vsfit,rofit,hhfit,qpfit,qsfit,dafit] = Update_confidence_data()
        %% x-axis
        id = conf_1d_to_show_x;
        misfit_over_sumweight = [];
        vpfit = [];
        vsfit = [];
        rofit = [];
        hhfit = [];
        qpfit = [];
        qsfit = [];
        dafit = [];
        if(~isempty(STORED_RESULTS_1d_misfit))
            if(~isempty(STORED_RESULTS_1d_misfit{id}))
                misfit_over_sumweight = [misfit_over_sumweight; STORED_RESULTS_1d_misfit{id}(:,2)];
                vpfit = [vpfit; STORED_1d_vp_fits{id}];
                vsfit = [vsfit; STORED_1d_vs_fits{id}];
                rofit = [rofit; STORED_1d_ro_fits{id}];
                hhfit = [hhfit; STORED_1d_hh_fits{id}];
                qpfit = [qpfit; STORED_1d_qp_fits{id}];
                qsfit = [qsfit; STORED_1d_qs_fits{id}];
                dafit = [dafit; STORED_1d_daf_fits{id}];
                fprintf('Single-model contributions\n')
            end
        end
        if(~isempty(STORED_RESULTS_2d_misfit))
            if(~isempty(STORED_RESULTS_2d_misfit{id}))
                misfit_over_sumweight = [misfit_over_sumweight; STORED_RESULTS_2d_misfit{id}(:,2)];
                vpfit = [vpfit; STORED_2d_vp_fits{id}];
                vsfit = [vsfit; STORED_2d_vs_fits{id}];
                rofit = [rofit; STORED_2d_ro_fits{id}];
                hhfit = [hhfit; STORED_2d_hh_fits{id}];
                qpfit = [qpfit; STORED_2d_qp_fits{id}];
                qsfit = [qsfit; STORED_2d_qs_fits{id}];
                dafit = [dafit; STORED_2d_daf_fits{id}];
                fprintf('Multiple-model contributions\n')
            end
        end
        nlay = size(MDLS{id},1);
        misfit_over_sumweight =  misfit_over_sumweight./min(misfit_over_sumweight);% -> sF
        ndegfree = (nlay*6 -3) - get_locked_dof_1d(id);      
        misfit_over_sumweight = fcdf(misfit_over_sumweight,ndegfree,ndegfree); % sF rescaled !!!
    end
    function [vpfitx,vsfitx,rofitx,hhfitx,qpfitx,qsfitx,dafitx, ...
              vpfity,vsfity,rofity,hhfity,qpfity,qsfity,dafity] = Update_confidence_data_x2()
        %% x-axis
        idx = conf_1d_to_show_x;
        vpfitx = [];
        vsfitx = [];
        rofitx = [];
        hhfitx = [];
        qpfitx = [];
        qsfitx = [];
        dafitx = [];
        if(~isempty(STORED_RESULTS_2d_misfit))
            if(~isempty(STORED_RESULTS_2d_misfit{idx}))
                vpfitx = [vpfitx; STORED_2d_vp_fits{idx}];
                vsfitx = [vsfitx; STORED_2d_vs_fits{idx}];
                rofitx = [rofitx; STORED_2d_ro_fits{idx}];
                hhfitx = [hhfitx; STORED_2d_hh_fits{idx}];
                qpfitx = [qpfitx; STORED_2d_qp_fits{idx}];
                qsfitx = [qsfitx; STORED_2d_qs_fits{idx}];
                dafitx = [dafitx; STORED_2d_daf_fits{idx}];
                fprintf('Multiple-model contributions (x)\n')
            end
        end
        %% y-axis
        idy = conf_1d_to_show_y;
        vpfity = [];
        vsfity = [];
        rofity = [];
        hhfity = [];
        qpfity = [];
        qsfity = [];
        dafity = [];
        if(~isempty(STORED_RESULTS_2d_misfit))
            if(~isempty(STORED_RESULTS_2d_misfit{idy}))
                
                vpfity = [vpfity; STORED_2d_vp_fits{idy}];
                vsfity = [vsfity; STORED_2d_vs_fits{idy}];
                rofity = [rofity; STORED_2d_ro_fits{idy}];
                hhfity = [hhfity; STORED_2d_hh_fits{idy}];
                qpfity = [qpfity; STORED_2d_qp_fits{idy}];
                qsfity = [qsfity; STORED_2d_qs_fits{idy}];
                dafity = [dafity; STORED_2d_daf_fits{idy}];
                fprintf('Multiple-model contributions (y)\n')
            end
        end
        %% misfit
        if(~isempty(STORED_RESULTS_2d_misfit_profile))
            misfit_over_sumweight = STORED_RESULTS_2d_misfit_profile(:,2);
        end
        
        
        dof = 0;
        for m = 1:size(MDLS,2)
            nlay = size(MDLS{m},1);
            dof = dof + (nlay*6 -3);
        end
        
        misfit_over_sumweight =  misfit_over_sumweight./min(misfit_over_sumweight);% -> sF
        ndegfree = dof - get_locked_dof_2d();      
        misfit_over_sumweight = fcdf(misfit_over_sumweight,ndegfree,ndegfree); % sF rescaled !!!  
    end
    
    function Show_survey(newfigure)
        if (0 < P.isshown.id) && (P.isshown.id <= length(TO_INVERT))

            if(newfigure)
                figure_handle = figure('name',strcat('Best model Family: Site',num2str(P.isshown.id)));
                hhdl = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
            else
                figure_handle = H.gui;
                hhdl = hAx_dat;
            end
            set(figure_handle,'CurrentAxes',hhdl);
            hold(hhdl,'off')
            %% show original data
            cc = 2;% column containing the curve 
            scale= FDAT{P.isshown.id,1}();
            lgnd = '     data';
            show_data = abs( FDAT{P.isshown.id,2} );
            if( curve_plotmode == 0)
                plot(hhdl, scale, show_data,'k','linewidth',2);
            else
                semilogx(hhdl, scale, show_data,'k','linewidth',2);
            end
            hold(hhdl,'on')
            
            %% synthetics
            if( ixmax_id>ixmin_id && ixmax_id>0)
                xvec = main_scale(ixmin_id:ixmax_id);
                %% show simple modeled (last user pressed 'MODEL' button P/S waves)
                if(~isempty(modl_FDAT))
                    if(size(modl_FDAT,2)>2)
                        if(~isempty(modl_FDAT{1,3}))
                            %% P-amp
                            show_curve = abs( modl_FDAT{P.isshown.id,3}(ixmin_id:ixmax_id) );
                            if(max(show_curve) >= min(show_curve))
                                lgnd = [lgnd; 'P-amplif.'];
                                if( curve_plotmode == 0)
                                    plot(hhdl, xvec, show_curve,'--c','linewidth',2);
                                else
                                    semilogx(hhdl, xvec, show_curve,'--c','linewidth',2);
                                end
                            end
                        end
                        if(~isempty(modl_FDAT{1,4}))
                            %% S-amp
                            show_curve = abs( modl_FDAT{P.isshown.id,4}(ixmin_id:ixmax_id) );
                            if(max(show_curve) >= min(show_curve))
                                lgnd = [lgnd; 'S-amplif.'];
                                if( curve_plotmode == 0)
                                    plot(hhdl, xvec, show_curve,'--m','linewidth',2);
                                else
                                    semilogx(hhdl, xvec, show_curve,'--m','linewidth',2);
                                end
                            end
                        end
                    end
                    if(~isempty(modl_FDAT{1,2}))
                        %% HVSR model
                        lgnd = [lgnd; 'model-P/S'];
                        show_curve = abs( modl_FDAT{P.isshown.id,2}(ixmin_id:ixmax_id) );
                        if(max(show_curve) ~= min(show_curve))
                            if( curve_plotmode == 0)
                                plot(hhdl, xvec, show_curve,'g','linewidth',2);
                            else
                                semilogx(hhdl, xvec, show_curve,'.-g','linewidth',2);
                            end
                        end
                    end
                end
                %% surface waves
                if(~isempty(modl_FDATSW))
                    if(~isempty(modl_FDATSW{1,2}))
                        %% HVSR model
                        lgnd = [lgnd; ' model-SW'];
                        show_xvec  = modl_FDATSW{P.isshown.id,1};% (ixmin_id:ixmax_id) );
                        show_curve = abs( modl_FDATSW{P.isshown.id,2} );% (ixmin_id:ixmax_id) );
                        if(max(show_curve) ~= min(show_curve))
                            if( curve_plotmode == 0)
                                plot(hhdl, show_xvec, show_curve,'y','linewidth',2);
                            else
                                semilogx(hhdl, show_xvec, show_curve,'.-y','linewidth',2);
                            end
                        end
                    end
                end
                
                %% show initial sinthetic data
                if(~isempty(init_single_FDAT))
                    if(~isempty(init_single_FDAT{1,cc}))
                        show_curve = abs( init_single_FDAT{1,cc}(ixmin_id:ixmax_id) );
                        if(max(show_curve) ~= min(show_curve))
                            lgnd = [lgnd; '  initial'];
                            %semilogx(hhdl, xvec, show_curve,'y','linewidth',1);
                            if( curve_plotmode == 0)
                                plot(hhdl, xvec, show_curve,'y','linewidth',2);
                            else
                                semilogx(hhdl, xvec, show_curve,'y','linewidth',2);
                            end
                        end
                    end
                end
                %% show best sinthetic data
                if(~isempty(best_FDAT))
                    if(~isempty(best_FDAT{P.isshown.id,cc}))
                        show_curve = abs( best_FDAT{P.isshown.id,cc}(ixmin_id:ixmax_id) );
                        if(max(show_curve) ~= min(show_curve))
                            lgnd = [lgnd; 'best modl'];
                            %semilogx(hhdl, xvec, show_curve,'r','linewidth',2);
                            if( curve_plotmode == 0)
                                plot(hhdl, xvec, show_curve,'r','linewidth',2);
                            else
                                semilogx(hhdl, xvec, show_curve,'r','linewidth',2);
                            end
                        end
                    end
                end
                %% show last runned sinthetic data
                if(~isempty(last_FDAT))
                    if(~isempty(last_FDAT{P.isshown.id,cc}))
                        show_curve = abs( last_FDAT{P.isshown.id,cc}(ixmin_id:ixmax_id) );
                        if(max(show_curve) ~= min(show_curve))
                            %semilogx(hhdl, xvec, show_curve,'b','linewidth',2);
                            lgnd = [lgnd; ' last run'];
                            if( curve_plotmode == 0)
                                plot(hhdl, xvec, show_curve,'b','linewidth',2);
                            else
                                semilogx(hhdl, xvec, show_curve,'b','linewidth',2);
                            end
                        end
                    end
                end                
            end
            %% show Uncertainity
            
            if(~isempty(FDAT{P.isshown.id,3}))
                lgnd = [lgnd; '    error'];
                if( curve_plotmode == 0)
                    plot(hhdl, scale, show_data+FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.3 0.3 0.3]);
                else
                    semilogx(hhdl, scale, show_data+FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.3 0.3 0.3]);
                end
                legend(lgnd);
                if( curve_plotmode == 0)
                    plot(hhdl, scale, show_data-FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.3 0.3 0.3]);
                else
                    semilogx(hhdl, scale, show_data-FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.3 0.3 0.3]);
                end
            else
                legend(lgnd);
            end
            %% info
            xlabel(hhdl,'Fr.')
            ylabel(hhdl,'HVSR')
            
            xlim(hhdl,[view_min_scale,view_max_scale])
            DL = modeldepths(P.isshown.id);
            DL(end) = Inf;
            tabledata = [ MDLS{P.isshown.id}, DL(2:end)];
            if(hhdl==hAx_dat)
                %set(hTab_mod,'ColumnEditable', logical(zeros(1,size(tabledata,2))) )
                set(hTab_mod,'Data',tabledata);%% FIX  this does not show
            end
            grid on
            drawnow
        end
    end
    function Show_bestmodels_family(newfigure)
        %if(hhdl==hAx_1dprof); set(H.gui,'CurrentAxes',hAx_1dprof); end
        
        if(newfigure)
            figure_handle = figure('name',strcat('Best model Family: Site',num2str(P.isshown.id)));
            hhdl = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            figure_handle = H.gui;
            hhdl = hAx_1dprof;
        end
        set(figure_handle,'CurrentAxes',hhdl);
        
        hold(hhdl,'off')
        linecol = [0.7, 0.7, 0.7];
        linew   = 0.5;
        for ii = 1:NresultsToKeep
            TMDL = BEST_SINGLE_MODELS{ii,P.isshown.id};
            draw_1d_profile(hhdl, TMDL,linecol,linew);
        end
        
        if(not(isempty(vfst_MDLS)))
            linecol = 'b';
            linew   = 2;
            draw_1d_profile(hhdl, vfst_MDLS{P.isshown.id}, linecol,linew);
        end
        linecol = 'r';
        linew   = 2;
        draw_1d_profile(hhdl, MDLS{P.isshown.id}, linecol,linew);
    end
    function plot__curve_weights(newfigure)
        if(newfigure)
            figure_handle = figure('name','Curve weights');
            hhdl = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            figure_handle = H.gui;
            hhdl = hAx_cwf;
        end
        set(figure_handle,'CurrentAxes',hhdl);
        
        if(curve_weights_plotmode == 0)
            plot(hhdl, weight_curv(:,1), weight_curv(:,2), 'k', 'linewidth',2);
        else
            semilogx(hhdl, weight_curv(:,1), weight_curv(:,2), 'k', 'linewidth',2);
        end
        
        xlabel(hhdl,'Frequence');
        ylabel(hhdl,'Weight');
        boundmax = max([1.2,  (max(weight_curv(:,2))+0.2) ]);
        ylim(hhdl, [-0.2, boundmax]);
        grid on
        drawnow;
    end
    function plot__depth_weights(newfigure)
        if(newfigure)
            figure_handle = figure('name','Depth weights');
            hhdl = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            figure_handle = H.gui;
            hhdl = hAx_dwf;
        end
        set(figure_handle,'CurrentAxes',hhdl);
        
        if(depth_weights_plotmode == 0)
            plot(hhdl, weight_dpth(:,1), weight_dpth(:,2), 'k', 'linewidth',2);
        else
            semilogx(hhdl, weight_dpth(:,1), weight_dpth(:,2), 'k', 'linewidth',2);
        end
        
        xlabel(hhdl,'Depth');
        ylabel(hhdl,'Weight');
        boundmax = max([1.2,  (max(weight_dpth(:,2))+0.2) ]);
        ylim(hhdl, [-0.2, boundmax]);
        grid on
        drawnow;
    end

    function setup_curve_weights()
%        for d = 1 :size(FDAT,1)
            CW = cell(1);
            d=1;
            CW{d}= spline(weight_curv(:,1), weight_curv(:,2), main_scale);
%             figure
%             plot(weight_curv(:,1), weight_curv(:,2),'k'); hold on
%             plot(main_scale, CW{d},'.b')

%>>               CW{d} = weight_curv(:,2);%ones(nti,1);

%             nti = length(main_scale); %   n of time samples of the data
%             CW{d} = ones(nti,1);
%             for fi = 1:length(main_scale)
%                 if(CW{d}(fi) < 0.0000001)
%                     CW{d}(fi) = 0;
%                 end
%             end
 %       end
    end
    function setup_dpth_weights()
        Nmodels = size(MDLS,2); 
        DW = cell(1,Nmodels);
        if Nmodels > 0
            for m = 1:Nmodels%                                models (Cycle)
                Nlay = size(MDLS{m}, 1);%                     half space is not considered
                DW{m} = zeros(Nlay,1);
                for l = 1:Nlay%                                layers (Cycle)
                    if l == 1
                        ref_depth = MDLS{m}(1, 4)/2;
                    else
                        ref_depth = sum(MDLS{m}(1:(l-1), 4)) + MDLS{m}(l,4)/2;
                    end

                    diff_depth_vec = abs(weight_dpth(:,1) - ref_depth);
                    deph_weight_id = find(diff_depth_vec == min(diff_depth_vec));
                    deph_weight_id = deph_weight_id(1);
                    %fprintf('    Layer[%d]   Ref-Depth[%f]   corresponding h[%f]\n',l,ref_depth, weight_dpth(deph_weight_id,1) );
                    wh = weight_dpth(deph_weight_id(1),2);

                    DW{m}(l,1) = wh;
                end
            end
        end
    end
    %
    function [OUT] = multiple_fwd_model()
%         %get curve x-ranges ids
%         xmin = str2double( get(h_scale_min,'String') );
%         xmax = str2double( get(h_scale_max,'String') );
%         ddx   = str2double( get(h_dscale,   'String') );
%         get_curve_xindex_bounds(xmin,xmax);
%         %ixmax_id
%         %ixmin_id
%         %FDAT{1,1}
%         
%          
% %         if(ddx==0)
% %             %% TRIK
% %             fprintf('Using data curve resolution\n');
% %             x_vec = main_scale(ixmin_id:ixmax_id);
% %         else
%             %% NORMAL
%             nnx = fix(abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx);
%             x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx);
% %         end
%         
%         %nnx
        x_vec = get_x_ranges();
        %x_vec
        OUT = cell(size(SURVEYS,1),2);
        for m = 1:size(SURVEYS,1);
            % VP VS RO HH QP QS
            MDL = MDLS{m};
            OUT1 = single_fwd_model(MDL,x_vec);%,ddx);
            OUT{m,1} = OUT1{1,1};
            OUT{m,2} = OUT1{1,2};
            OUT{m,3} = OUT1{1,3};% p-amp 
            OUT{m,4} = OUT1{1,4};% s-amp
        end
    end
    function [OUT] = multiple_fwd_model_sw()
        get_x_ranges();
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,  'String') );
        
        %x_vec = get_x_ranges();
        OUT = cell(size(SURVEYS,1),2);
        for m = 1:size(SURVEYS,1)
            % VP VS RO HH QP QS
            vp = MDLS{m}(:,1);
            vs = MDLS{m}(:,2);
            ro = MDLS{m}(:,3);
            hz = MDLS{m}(:,4);
            qp = MDLS{m}(:,5);
            qs = MDLS{m}(:,6);
            [FF,HV] = call_Albarello_2011(sw_nmodes, sw_nsmooth, ddx, xmax, hz,vp,vs,ro,qp,qs);
            OUT{m,1} = FF;
            OUT{m,2} = HV;
        end
    end
    function [OUT1] = single_fwd_model(MDL,x_vec)
        ex   = str2double( get(h_ex_val,  'String') );
        fref = str2double( get(h_fref_val,'String') );
        
        % as_Samuel(c,ro,h,q,ex,fref,f)  
        VP = MDL(:,1);
        VS = MDL(:,2);
        RO = MDL(:,3);
        HH = MDL(:,4);
        QP = MDL(:,5);
        QS = MDL(:,6);

        aswave = as_Samuel(VS,RO,HH,QS,ex,fref, x_vec);
        apwave = as_Samuel(VP,RO,HH,QP,ex,fref, x_vec);
        hvsr_teo = (aswave./apwave);

        OUT1{1} = main_scale;
        OUT1{2} = 0*main_scale;
        %% NORMAL
        OUT1{2}(ixmin_id:ixmax_id,1) = ( interp1(x_vec, hvsr_teo, main_scale(ixmin_id:ixmax_id) ) ).';
        OUT1{3} = 0*main_scale;
        OUT1{3}(ixmin_id:ixmax_id,1) = ( interp1(x_vec, apwave, main_scale(ixmin_id:ixmax_id) ) ).';
        OUT1{4} = 0*main_scale;
        OUT1{4}(ixmin_id:ixmax_id,1) = ( interp1(x_vec, aswave, main_scale(ixmin_id:ixmax_id) ) ).';
    end
    function [OUT1] = single_fwd_model_SW(MDL)
        get_x_ranges();
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,  'String') );
        
        % as_Samuel(c,ro,h,q,ex,fref,f)  
        VP = MDL(:,1);
        VS = MDL(:,2);
        RO = MDL(:,3);
        HH = MDL(:,4);
        QP = MDL(:,5);
        QS = MDL(:,6);
    
        [FF,hvsr_teo] = call_Albarello_2011(sw_nmodes, sw_nsmooth, ddx, xmax, HH,VP,VS,RO,QP,QS);% [FF,HV] =
        %OUT1{1} = FF;
        %OUT1{2} = HV;
        
        OUT1{1} = main_scale;
        OUT1{2} = 0*main_scale;
        %% NORMAL
        OUT1{2}(ixmin_id:ixmax_id,1) = ( interp1(FF, hvsr_teo, main_scale(ixmin_id:ixmax_id) ) ).';
        OUT1{3} = 0*main_scale;
        OUT1{4} = 0*main_scale;
    end
    function [x_vec] = get_x_ranges()
        xmin = str2double( get(h_scale_min,'String') );
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,  'String') );
        get_curve_xindex_bounds(xmin,xmax);

		%% NORMAL
		nnx = fix(abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx);
		x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx);
    end

    function spunta(handle_vector, property_value)
        % spunta for menus
        for ir = 1:length(handle_vector)
            if ir == property_value +1;
                set(handle_vector(ir),'Checked','on');
            else
                set(handle_vector(ir),'Checked','off');
            end
        end
    end
    function [dzmax] = get_max_depth()
        dzmax = 0;
        bedrock = zeros(3,size(SURVEYS,1));% [x;y;z]
        for d = 1:size(SURVEYS,1)
            dz = sum(MDLS{d}( 1:(end-1), 4));% depth is col 4:  vp vs ro h qp qs 
            bedrock(1,d) = SURVEYS{d,1}(1);
            bedrock(2,d) = SURVEYS{d,1}(2);
            bedrock(3,d) = -dz;
            if(dzmax < dz); dzmax = dz; end
        end
        dzmax = dzmax +5;%%  5 meters to represent HS
    end
    function model_manager(data)
        newdata = data;
        OUT1 = [];
        DSP = get(0,'ScreenSize');
        main_l = 0.1 * DSP(3);
        main_b = 0.1 * DSP(4);
        main_w = 0.6 * DSP(3);
        main_h = 0.8 * DSP(4);

        hdiag = figure('name','Model Manager','Visible','on','OuterPosition',[main_l, main_b, main_w, main_h],'NumberTitle','off');
        P0 = uipanel(hdiag,'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[ 0,   0, 0.2, 1]); 
        P1 = uipanel(hdiag,'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[ 0.2, 0, 0.4, 1]);
        P2 = uipanel(hdiag,'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[ 0.6, 0, 0.4, 1]);

        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Quit','Position',[0., 0.69, 1, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_quit});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Revert','Position',[0., 0.66, 1, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_revert});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Save and exit','Position',[0., 0.6, 1, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_save});
        hbut_bw = uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Test correction (P/S)','Position',[0., 0.5, 1, 0.03]', ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_test_BW});
        hbut_sw = uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Test correction (SW)','Position',[0., 0.46, 1, 0.03]', ...
            'Enable',FLAG__PC_features, ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_test_SW});
        
        uicontrol('Parent',P0,'Style','text','Units','normalized','String','Misfit (to minimize)','Position',[0., 0.23,  1.0, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize);
        uicontrol('Parent',P0,'Style','text','Units','normalized','String','Before','Position',[0., 0.2,  0.4, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize);
        holdmisf = uicontrol('Parent',P0,'Style','text','Units','normalized','String','0','Position',[0.4, 0.2,  0.6, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize);
        uicontrol('Parent',P0,'Style','text','Units','normalized','String','After','Position',[0., 0.17,  0.4, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize);
        hnewmisf = uicontrol('Parent',P0,'Style','text','Units','normalized','String','0','Position',[0.4, 0.17, 0.6, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize);
        
        cnames = {'Vp','Vs','Ro','H','Qp','Qs'};
        TB = uitable('Parent',P1,'ColumnName',cnames,'Units','normalized','Position',[0.0 0.0 1 1], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'ColumnFormat',{'bank','bank','bank','bank','bank','bank'}, ...
            'ColumnWidth',{75 75 50 50 50 50}); 
        set(TB, 'ColumnEditable',logical([1 1 1 1 1 1 0]))
        set(TB,'Data',newdata);
        
        hAx_mm= axes('Parent',P2,'Units', 'normalized','Units','normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position', [0.1 0.1 0.8 0.8]);
        %% get original misfit
        xmin = str2double( get(h_scale_min,'String') );
        xmax = str2double( get(h_scale_max,'String') );
        ddx   = str2double( get(h_dscale,   'String') );
        get_curve_xindex_bounds(xmin,xmax);
        nnx = abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx; 
        x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx);            
        MDL = get(TB,'Data');
        MDL = MDL(:,1:6);
        OUT1 = single_fwd_model(MDL,x_vec);
        [oMFit,~,~,~] = get_single_model_misfit(P.isshown.id, OUT1{2});
        set(holdmisf,'String',num2str(oMFit));
        
        %% draw    
        subredrow()

        function B_quit(~,~,~)% quit without changes
            newdata = data;
            close(hdiag)
        end
        function B_revert(~,~,~)% revert to original
            newdata = data;
            set(TB,'Data',newdata);
        end

        function B_save(~,~,~)% save and exit 
            xmin = str2double( get(h_scale_min,'String') );
            xmax = str2double( get(h_scale_max,'String') );
            ddx   = str2double( get(h_dscale,   'String') );
            get_curve_xindex_bounds(xmin,xmax);

            nnx = abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx; 
            x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx); 
            
            MDL = get(TB,'Data');
            MDL = MDL(:,1:6);
            OUT1 = single_fwd_model(MDL,x_vec);
            [tMFit,~, ~, ~] = get_single_model_misfit(P.isshown.id, OUT1{2});
            MDLS{P.isshown.id}    = MDL;
            
            last_MDLS{P.isshown.id} = MDL;
            last_FDAT{P.isshown.id,1} = OUT1{1,1};
            last_FDAT{P.isshown.id,2} = OUT1{1,2};
            
            last_single_MDL  = MDL;
            last_single_FDAT{1,1} = OUT1{1,1};
            last_single_FDAT{1,2} = OUT1{1,2};
            
            Store_Single_Result(tMFit,MDL,0,0)
	    % Store_Single_Result(tMFit,MDL,tctrm,tstrm)
            %set(hnewmisf,'String',num2str(tMFit));
            %%
            
            
            
            close(hdiag)
        end
        function B_test_BW(~,~,~)% save and exit 
            bgc = [1 0.5 0.1];
            set(hbut_bw,'BackgroundColor',bgc, 'String', 'Working');
            %
            xmin = str2double( get(h_scale_min,'String') );
            xmax = str2double( get(h_scale_max,'String') );
            ddx   = str2double( get(h_dscale,   'String') );
            get_curve_xindex_bounds(xmin,xmax);

            nnx = abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx; 
            x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx); 
            
            MDL = get(TB,'Data');
            MDL = MDL(:,1:6);
            OUT1 = single_fwd_model(MDL,x_vec);
            [tMFit,~,~,~] = get_single_model_misfit(P.isshown.id, OUT1{2});
            set(hnewmisf,'String',num2str(tMFit));
            
            subredrow();
            bgc = 0.9*[1 1 1];
            set(hbut_bw,'BackgroundColor',bgc, 'String', 'Test correction (P/S)');
        end
        function B_test_SW(~,~,~)% save and exit 
            bgc = [1 0.5 0.1];
            set(hbut_sw,'BackgroundColor',bgc, 'String', 'Working');
            %
            xmin = str2double( get(h_scale_min,'String') );
            xmax = str2double( get(h_scale_max,'String') );
            ddx   = str2double( get(h_dscale,   'String') );
            get_curve_xindex_bounds(xmin,xmax);

            nnx = abs(main_scale(ixmax_id)-main_scale(ixmin_id))/ddx; 
            x_vec = linspace( main_scale(ixmin_id), main_scale(ixmax_id),nnx); 
            
            MDL = get(TB,'Data');
            MDL = MDL(:,1:6);
            OUT1 = single_fwd_model_SW(MDL);
            [tMFit,~,~,~] = get_single_model_misfit(P.isshown.id, OUT1{2});
            set(hnewmisf,'String',num2str(tMFit));
            
            subredrow();
            bgc = 0.9*[1 1 1];
            set(hbut_sw,'BackgroundColor',bgc, 'String' ,'Test correction (SW)');
        end
    %
        function subredrow()% -----------------------------------------------------------------------------------------------
            set(hdiag,'CurrentAxes',hAx_mm);
           
            %% show original data
            hold(hAx_mm,'off')
            cc = 2;% column containing the curve 
            scale   = FDAT{P.isshown.id,1}();
            show_data = abs( FDAT{P.isshown.id,2} );
            lgnd = 'data';
            semilogx(hAx_mm, scale, show_data,'k','linewidth',2);
            
%             if( curve_plotmode == 0)
%                 plot(hAx_mm, scale, show_curve,'k','linewidth',2);
%             else
%                 semilogx(hAx_mm, scale, show_curve,'k','linewidth',2);
%             end
            hold(hAx_mm,'on')
            %% synthetics
            if( ixmax_id>ixmin_id && ixmax_id>0)
                xvec = main_scale(ixmin_id:ixmax_id);
                %% show best sinthetic data
                if(~isempty(best_FDAT))
                    if(~isempty(best_FDAT{P.isshown.id,cc}))
                        show_curve = abs( best_FDAT{P.isshown.id,cc}(ixmin_id:ixmax_id) );
                        if(max(show_curve) ~= min(show_curve))
                            lgnd = [lgnd; 'best'];
                            semilogx(hAx_mm, xvec, show_curve,'r','linewidth',2);
%                             if( curve_plotmode == 0)
%                                 plot(hAx_dat, xvec, show_curve,'r','linewidth',2);
%                             else
%                                 semilogx(hAx_dat, xvec, show_curve,'r','linewidth',2);
%                             end
                        end
                    end
                end 
                %% show proposed model
                if(~isempty(OUT1))
                    lgnd = [lgnd; 'test'];
                    show_curve = abs( OUT1{cc}(ixmin_id:ixmax_id) );
                    if(max(show_curve) ~= min(show_curve))
                        semilogx(hAx_mm, xvec, show_curve,'b','linewidth',2);
%                             if( curve_plotmode == 0)
%                                 plot(hAx_dat, xvec, show_curve,'g','linewidth',2);
%                             else
%                                 semilogx(hAx_dat, xvec, show_curve,'g','linewidth',2);
%                             end
                    end
                end
                               
            end
            %% info
            xlabel(hAx_mm,'T [k]data [g]First, [b]Last [r]Best ')
            ylabel(hAx_mm,'HVSR')
            
            xlim(hAx_mm,[view_min_scale,view_max_scale])
            
            grid on
            drawnow
            
            %% show Uncertainity
            if(~isempty(FDAT{P.isshown.id,3}))
                lgnd = [lgnd; 'err.'];
%                 if( curve_plotmode == 0)
                    semilogx(hAx_mm, scale, show_data+FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.5 0.5 0.5]);
                    
%                 else
%                     semilogx(hAx_dat, scale, show_curve+FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.5 0.5 0.5]);
%                     semilogx(hAx_dat, scale, show_curve-FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.5 0.5 0.5]);
%                 end
            end
            legend(lgnd)
            if(~isempty(FDAT{P.isshown.id,3}))
%                 if( curve_plotmode == 0)
                    semilogx(hAx_mm, scale, show_data-FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.5 0.5 0.5]);
%                 else
%                     semilogx(hAx_dat, scale, show_curve+FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.5 0.5 0.5]);
%                     semilogx(hAx_dat, scale, show_curve-FDAT{P.isshown.id,3},'linewidth',0.5,'color',[0.5 0.5 0.5]);
%                 end
            end
            
        end
        waitfor(hdiag)% -----------------------------------------------------------------------------------------------------
    end
    function [ newdata,except] = lockparameters_manager()
        newdata = LKT;
        except  = RCT;
        DSP = get(0,'ScreenSize');
        main_l = 0.1 * DSP(3);
        main_b = 0.1 * DSP(4);
        main_w = 0.6 * DSP(3);
        main_h = 0.8 * DSP(4);

        hdiag = figure('name','Lock Parameters','Visible','on','OuterPosition',[main_l, main_b, main_w, main_h],'NumberTitle','off');
        set(hdiag,'MenuBar','none');
        P0 = uipanel(hdiag,'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[ 0, 0, 0.4, 1]);
        P1 = uipanel(hdiag,'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[ 0.4, 0, 0.6, 1]);
        
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock Vp',  'Position',[0.0, 0.97, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  1});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock Vp','Position',[0.5, 0.97, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,1});
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock Vs',  'Position',[0.0, 0.94, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  2});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock Vs','Position',[0.5, 0.94, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,2});
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock Ro',  'Position',[0.0, 0.91, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  3});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock Ro','Position',[0.5, 0.91, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,3});
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock H',   'Position',[0.0, 0.88, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  4});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock H', 'Position',[0.5, 0.88, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,4});
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock Qp',  'Position',[0.0, 0.85, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  5});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock Qp','Position',[0.5, 0.85, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,5});
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock Qs',  'Position',[0.0, 0.82, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  6});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock Qs','Position',[0.5, 0.82, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,6});
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Lock Half-space',  'Position',[0.0, 0.76, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_lock,  10});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Unlock Half-space','Position',[0.5, 0.76, 0.5, 0.03],'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_unlock,10});
        
        
        
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Quit','Position',[0., 0.69, 1, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_quit});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Revert','Position',[0., 0.66, 1, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_revert});
        uicontrol('Parent',P0,'Style','pushbutton','Units','normalized','String','Save and exit','Position',[0., 0.6, 1, 0.03], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'Callback',{@B_save});
       
        uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',P1,'String','Perturbe parameters:','Units','normalized','Position',[0.0, 0.9, 1, 0.1]);
        cnames = {'Vp','Vs','Ro','H','Qp','Qs'};
        columnformat = {'logical', 'logical', 'logical', 'logical', 'logical', 'logical'};
        TB = uitable('Parent',P1,'ColumnName',cnames,'Units','normalized','Position',[0.0 0.5 1 0.4], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'ColumnFormat',columnformat , ...
            'ColumnWidth','auto','ColumnEditable',logical([1 1 1 1 1 1]));
        set(TB,'Data',logical(newdata));
        
        % relaxes
        uicontrol('FontSize',USER_PREFERENCE_interface_objects_fontsize,'Style','text','parent',P1,'String','Relax Constrains:','Units','normalized','Position',[0.0, 0.4, 1, 0.1]);
        cnames = {'max Vp/Vs'};
        TB_relaxations = uitable('Parent',P1,'ColumnName',cnames,'Units','normalized','Position',[0.0 0.0 1 0.4], ...
            'FontSize',USER_PREFERENCE_interface_objects_fontsize,'ColumnFormat',columnformat , ...
            'ColumnWidth','auto','ColumnEditable',logical([1]));
        set(TB_relaxations,'Data',logical(except));
        
        function B_lock(~,~,id)
            if id<7 
                newdata(:,id) = 0;
            else
                newdata(end,:)= 0;
            end
            update_table();
        end
        function B_unlock(~,~,id)
            if id<7 
                newdata(:,id) = 1;
            else
                newdata(end,:)= 1;
            end
            update_table();
        end
        
        function B_quit(~,~,~)% quit without changes
            close(hdiag)
        end
        function B_revert(~,~,~)% revert to original
            newdata = LKT;
            except = RCT;
            set(TB,'Data',logical(newdata));
            set(TB_relaxations,'Data',logical(except));
        end

        function B_save(~,~,~)% save and exit 
            newdata = get(TB,'Data');
            except = get(TB_relaxations,'Data');
            close(hdiag)
        end
        
        
        function update_table()
            newdata(end,(end-2):end) = 0; 
            
           set(TB,'Data',logical(newdata)); 
        end
        waitfor(hdiag)% -----------------------------------------------------------------------------------------------------
    
        
    end
    %% Multiple optimization 
    function [OUTMS] = perturbe_models(INMS)
        if strcmp( get(hRand,'String'), 'Uniform ')
        end
        OUTMS = INMS;
        
        % MTP: Model To Perturbe
        %  [vp vs ro h qp qs]
        Nmodels = size(INMS,2);
        [pctk, pcvp,pcvs, pcro, pcqp,pcqs] = get_perturbations();
        
        for m = 1:Nmodels%                                models (Cycle)
            %fprintf('MODEL  [%d]\n',m);
            if(TO_INVERT(m) == 1)%                                         Perturbe this model  
                %                                                          
                %                                                          [0] Do not use.
                %                                                          [1] Use! try to optimize model -> PERTURBE!!.
                %                                                          [2] Use! keep the model fixed.
                INM = INMS{m};
                Nlay = size(INM, 1);
%                 %random_mode=1;
%                 if ( get(hRand,'Value') == 1)% Uniform
%                     P = (randi(1000, Nlay,6)-500)/500;% [-1 , -1] uniform, dr = 0.001    
%                 end
%                 if ( get(hRand,'Value') == 2)% Gaussian
%                     % gaussian distribution here 
%                     % the selected varietion [-max perturb, +max perturbation]
%                     % will correspond to 2*sigma. 
%                     % i.e. 99% of random trials
%                     %
%                     %x= (value*variation/100) * (randn(1000000,1)/4);
%                     % = delta *  (randn(1000000,1)/4) 
%                     P = (randn(Nlay,6)/4);
%                 end
                [PRB] = get_probability(Nlay);% PRB = (n-layers, 6 columns)
                
                %% perturbed model     
                [OUTM] = get_perturbed_model(INM,PRB,pctk, pcvp,pcvs, pcro, pcqp,pcqs,DW{m});%dptW);
                 
                %% check for media constrains
                OUTMS{m} = check_phisical_constrains(OUTM);
            end
        end
    end
    function Store_Results(Energy,GlobalMisfit,RegularizerValue, Curv_term,Slop_term, misfitvector)
        the_worst_energy = max(BEST_ENERGIES);
        the_best_energy  = min(BEST_ENERGIES);
        if(Energy <= the_worst_energy)% keep this model
            idp = find( BEST_ENERGIES == the_worst_energy);%% id of location to replace 
            idp = idp(1);
            BEST_ENERGIES(idp) = Energy;
            BEST_MISFITS(idp)  = GlobalMisfit;
            BEST_MODELS{idp}   = last_MDLS;
            
            %fprintf('     >> kept.\n')

            % record the best
            if(Energy < the_best_energy)
                %fprintf('     >> new best model found.\n')
                best_FDAT = last_FDAT;
                MDLS = last_MDLS;
                best_MISFIT_by_location = misfitvector;
                
                nsofar = size(Misfit_vs_Iter_MULPTIPLE, 1);
                Misfit_vs_Iter_MULPTIPLE = [Misfit_vs_Iter_MULPTIPLE; [nsofar ,Energy, GlobalMisfit, RegularizerValue, Curv_term,Slop_term] ]; 
                Misfit_vs_Iter_MULPTIPLE_local = [Misfit_vs_Iter_MULPTIPLE_local; misfitvector];
                
                %if(get(h_realtime,  'Value')==0)% update if a new best model is found
                draw_Misfit_vs_it__MULTIPLE(0);
                %end
            end
        end
    end
    function RFit = Regularize()
        refresh_models_list2D()
        nmodels = size(MDLS,2);
        RFit = 0;
        wvp = str2double( get(h_vp_w, 'String') );
        wvs = str2double( get(h_vs_w, 'String') ); 
        wro = str2double( get(h_ro_w, 'String') );
        wqp = str2double( get(h_qp_w, 'String') );
        wqs = str2double( get(h_qs_w, 'String') ); 
        for mi = 2:nmodels
            for mj = 2:nmodels
                vp_part=sum( VPList(:,mi) - VPList(:,mj) );
                vs_part=sum( VSList(:,mi) - VSList(:,mj) );
                ro_part=sum( ROList(:,mi) - ROList(:,mj) );
                qp_part=sum( QPList(:,mi) - QPList(:,mj) );
                qs_part=sum( QSList(:,mi) - QSList(:,mj) );
    %            end
                distance_weight = r_reciprocicity(mi,mj);
                value = ( (wro*ro_part)^2 + (wvp*vp_part)^2 + (wvs*vs_part)^2 + (wqp*qp_part)^2 + (wqs*qs_part)^2 );
                RFit = RFit + distance_weight * value;
            end
        end
    end
    %% Sigle model optimization
    function [OUTM] = perturbe_single_model(INM)
%%        % MTP: Model To Perturbe
        %  [vp vs ro h qp qs]
        [pctk, pcvp,pcvs, pcro, pcqp,pcqs] = get_perturbations();
        
        Nlay = size(INM, 1);
        dptW = DW{P.isshown.id};
        [PRB] = get_probability(Nlay);
        
        %% perturbed model
        OUTM = get_perturbed_model(INM,PRB,pctk, pcvp,pcvs, pcro, pcqp,pcqs,dptW);
        %fprintf('  [A] perturbation [%f][%f][%f][%f][%f][%f]\n', max( abs(OUTM - INM ) ) );
                    
        
        %% check for media constrains
        [OUTM] = check_phisical_constrains(OUTM);
        %fprintf('  [B] perturbation [%f][%f][%f][%f][%f][%f]\n', max( abs(OUTM - INM ) ) );
        %pause
    end
    function [pctk, pcvp,pcvs, pcro, pcqp,pcqs] = get_perturbations()
        pcvp = str2double(get(h_vp_val, 'String'))/100;
        pcvs = str2double(get(h_vs_val, 'String'))/100;
        pctk = str2double(get(h_hh_val, 'String'))/100;%  get the maximum % changes (between [0,1])
        pcro = str2double(get(h_ro_val, 'String'))/100;
        pcqp = str2double(get(h_qp_val, 'String'))/100;
        pcqs = str2double(get(h_qs_val, 'String'))/100;
    end
    function [PRB] = get_probability(Nlay)
        if ( get(hRand,'Value') == 1)% Uniform
            PRB = (randi(1000, Nlay,6)-500)/500;% [-1 , -1] uniform, dr = 0.001    
        end
        if ( get(hRand,'Value') == 2)% Gaussian
            % gaussian distribution here 
            % the selected varietion [-max perturb, +max perturbation]
            % will correspond to 2*sigma. 
            % i.e. 99% of random trials
            %
            %x= (value*variation/100) * (randn(1000000,1)/4);
            % = delta *  (randn(1000000,1)/4) 
            PRB = (randn(Nlay,6)./4);
        end
    end
    function [O] = get_perturbed_model(IN,PP,pctk, pcvp,pcvs, pcro, pcqp,pcqs,dptW)
        nls  = size(IN,1);
        chng = PP.*IN;
        Mtrix= 0*chng;
        %dptW = DW{PP.isshown.id};
        
        Mtrix(:,1) = dptW .* pcvp .* chng(:,1);% Vp
        Mtrix(:,2) = dptW .* pcvs .* chng(:,2);% Vs
        Mtrix(:,3) = dptW .* pcro .* chng(:,3);% Ro
        %
        L = 1:(nls-1);
        Mtrix(L,4) = dptW(L) .* pctk .* chng(L,4);% H
        Mtrix(L,5) = dptW(L) .* pcqp .* chng(L,5);% Qp
        Mtrix(L,6) = dptW(L) .* pcqs .* chng(L,6);% Qs
        
        O = IN + LKT(1:nls, :).*Mtrix; 
    end
    function [OUTM] = check_phisical_constrains(OUTM)
        %newdata = LKT;
        %except  = RCT;
         %% check for media constrains
         
        for l = 1:size(OUTM,1)%                                layers (Cycle)
            VP = OUTM(l,1);
            VS = OUTM(l,2);
            RO = OUTM(l,3);

            %%  CHECK VS
            if( VS < min_vs ); 
                OUTM(l,2) = min_vs; 
            end
            %%  CHECK VP/VS
            if( VP < min_vp_vs_ratio*VS ); 
                %fprintf('lay[%d]  [VP/VS<min_vp_vs_ratio]  -- [%f/%f]<%f enforced\n',l,VP,VS,min_vp_vs_ratio);
                OUTM(l,1) = VS*min_vp_vs_ratio; 
                %fprintf('VP/VS < min_vp_vs_ratio -- enforced\n',l);
            end
            if RCT(l,1) == 0 
                %fprintf('RCT(%d,1) ',l);
                if( VP/VS > max_vp_vs_ratio ); 
                    OUTM(l,1) = VS*max_vp_vs_ratio; 
                %    fprintf('enforced\n',l);
                %else
                %    fprintf('no need\n',l);
                end
            %else
            %    fprintf('RCT(%d,1) relax\n',l);
            end
            %%  CHECK RO
            if( RO < min_ro); 
                OUTM(l,3) = min_ro; 
            end
            if( RO > max_ro ); 
                OUTM(l,3) = max_ro; 
            end
        end   
        for l = 1:(size(OUTM,1)-1)%                            layers (Cycle)
            QP = OUTM(l,5);
            QS = OUTM(l,6);
            %%  CHECK QS
            if( QS < min_qs ); 
                OUTM(l,6) = min_qs; 
            end
            %%  CHECK QP/QS
            if( QP/QS < min_qp_qs_ratio ); 
                OUTM(l,5) = QS*min_qp_qs_ratio; 
            end
            if( QP/QS > max_qp_qs_ratio ); 
                OUTM(l,5) = QS*max_qp_qs_ratio; 
            end 
        end
      
    end
    function [MFit, curveterm, slopeterm, er] = get_single_model_misfit(survey_id, SYM)
        % MFit:     misfit, 
        % ctrm:     curve term, 
        % strm:     slope term,
        % er:        misfit divided by the sum of the weights 
        data_curve = FDAT{survey_id,2}(ixmin_id:ixmax_id);
        sint_curve = SYM(ixmin_id:ixmax_id,1);
        weights = (CW{1}).^2;%(CW{survey_id}).^2;
        weights(DISCARDS{survey_id},:) = 0;
        weights = weights(ixmin_id:ixmax_id);
        % figure; plot(main_scale, CW{survey_id},'.-b'); pause        
        %% curve term
        w2 = weights.^2;
        C2 = (sint_curve-data_curve).^2;
        curveterm = (w2')*(C2); %sum(w2.*C2);        
        %% slope term
        DsintDs = sint_curve(2:end)-sint_curve(1:end-1);
        DdataDs = data_curve(2:end)-data_curve(1:end-1);
        S2 = (DsintDs-DdataDs).^2;
        slopeterm = sum(w2(1:end-1).*S2);%% rescaled
        
        wctrm = (Misfit_curve_term_w*curveterm);%         weighted curve term
        wstrm = (Misfit_slope_term_w*slopeterm);%  weighted slope term [181118]
        MFit =  wctrm + wstrm;
        %fprintf('curve[%f]  slope[%f]\n',ctrm,strm)
        
        
        %MFit = slopeterm;
        sumweights = sum(weights);
        er = MFit/sumweights ;%% Er is the misfit divided by the sum of the weights
    end    
    function Store_Single_Result(Single_Misfit,MDL,ctrm,strm)
        the_worst_energy = max(BEST_SINGLE_MISFIT{P.isshown.id});
        the_best_energy  = min(BEST_SINGLE_MISFIT{P.isshown.id});
        
        if(Single_Misfit < the_worst_energy)
            idp = find( BEST_SINGLE_MISFIT{P.isshown.id} == the_worst_energy);%% id of location to replace 
            idp = idp(1);
            %fprintf('     >> kept.\n')
            BEST_SINGLE_MISFIT{P.isshown.id}(idp) = Single_Misfit;
            BEST_SINGLE_MODELS{idp,P.isshown.id}  = MDL;
            
            if(Single_Misfit < the_best_energy)
                %fprintf('     >> new best single-model found.\n')
                nsofar = size(STORED_RESULTS_1d_misfit{P.isshown.id}, 1);
                Misfit_vs_Iter{P.isshown.id} = [Misfit_vs_Iter{P.isshown.id}; [nsofar ,Single_Misfit,ctrm, strm] ]; 
                %%fprintf('it[%d]-->> %f\n',nsofar,Single_Misfit)
                %
                nc = length(last_single_FDAT);
                for j = 1:nc; best_FDAT{P.isshown.id,j} = last_single_FDAT{j}; end
                MDLS{P.isshown.id} = last_single_MDL;
                %
                if(get(h_realtime,  'Value')==0)% update if a new best model is found
                    Show_survey(0);
                    hold(hAx_1dprof,'off');
                    if(~isempty(vfst_MDLS))
                        draw_1d_profile(hAx_1dprof, vfst_MDLS{P.isshown.id},'b',1);
                        hold(hAx_1dprof,'on');
                    end
                    draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
                    hold(hAx_1dprof,'on');
                    %pause
                    draw_Misfit_vs_it(0);
                end
                %
            end
        end
        
        if(get(h_realtime,  'Value')==1)% turn on/off realtime visualization
            Show_survey(0);
            
            hold(hAx_1dprof,'off');
            if(~isempty(vfst_MDLS))
                draw_1d_profile(hAx_1dprof, vfst_MDLS{P.isshown.id},'b',1);
                hold(hAx_1dprof,'on');
            end
            
            %plot_1d_profile(hAx_1dprof);
            draw_1d_profile(hAx_1dprof, MDLS{P.isshown.id},'k',1);
            hold(hAx_1dprof,'on');
        end
    end
    %% Graphical
    function [boxx,boxy] = getsquare(xmin,xmax,ymin,ymax)
        % getsquare()
        % getsquare(xmin,xmax)
        % getsquare(xmin,xmax,ymin,ymax)
        
        k = waitforbuttonpress;
        if k == 0
            %disp('Button click')
            point1 = get(gca,'CurrentPoint');    % button down detected
            rbbox;                   % return figure units
            point2 = get(gca,'CurrentPoint');    % button up detected
            point1 = point1(1,1:2);              % extract x and y
            point2 = point2(1,1:2);
            p1 = min(point1,point2);             % calculate locations
            p2 = max(point1,point2);             % calculate locations
            
            
            if(nargin == 2)
                if( p1(1)<xmin || p1(1)>xmax ); p1(1) = xmin; end
                if( p2(1)<xmin || p2(1)>xmax ); p2(1) = xmax; end
            end
            if(nargin == 4)
                if( p1(2)<ymin || p1(2)>ymax ); p1(2) = ymin; end
                if( p2(2)<ymin || p2(2)>ymax ); p2(2) = ymax; end
            end

            offset = abs(p2-p1);         % and dimensions
            boxx = [p1(1) p1(1)+offset(1) p1(1)+offset(1) p1(1)           p1(1)];
            boxy = [p1(2) p1(2)           p1(2)+offset(2) p1(2)+offset(2) p1(2)];
            %
            %  box: 
            %  [4]--------------[3]
            %   |                |
            %   |                |
            %  [1/5]------------[2]
        end
        
    end
    function drawsquare(axis_handle,boxx,boxy)
        axis(axis_handle);
        hold on
        plot(axis_handle, boxx,boxy, 'r');
        hold off
    end
    function [points_id] = find_graph_encosed_points(xygraph, boxx,boxy)
%         xygraph
%         figure
%         loglog(xygraph(:,1),xygraph(:,2),'.-b')
        xmin = min(boxx);
        xmax = max(boxx);
        ymin = min(boxy);
        ymax = max(boxy);
        trues = (xmin < xygraph(:,1)).*(xygraph(:,1) < xmax).*(ymin < xygraph(:,2)).*(xygraph(:,2) < ymax);
        points_id = find(trues ==1);
    end
    function refresh_models_list2D()
        %% Translate to 2D profile
        %fprintf('2D Profile Updated.\n')
        dzmax = get_max_depth(); 
        nmodels = size(FDAT,1);
        %zlevels    = -weight_dpth(:,1);    %in inversion z-max can change so that weight_dpth should be updated or "extended"
        zlevels    = -linspace(0,dzmax,n_depth_levels);
        
        xpositions = zeros(nmodels,1);
        
        ZZList = zeros(length(zlevels), nmodels);
        for m = 1:nmodels
            ZZList(:,m) = zlevels + SURVEYS{m,1}(3);
        end
        
        VPList = ZZList;
        VSList = ZZList;
        ROList = ZZList;
        QPList = ZZList;
        QSList = ZZList;
        
        for m = 1:nmodels
            DL = modeldepths(m);
            nlay = size(  MDLS{m}(:,4) ,1);            
            xpositions(m) = SURVEYS{m,1}(1);
            
            temp = MDLS{m}; %  [MDLS{m}(1,:); MDLS{m}];% add the extra zero
            for l = 1:nlay%                                      Fill layer
                top = DL(l);
                btm = DL(l+1);
                
                Lvp = temp(l,1);
                Lvs = temp(l,2);
                Lro = temp(l,3);
                %% thickness here
                Lqp = temp(l,5);
                Lqs = temp(l,6);
                    
                %fprintf('M[%d] Lay %d  [%f]---[%f]\n',m,l,top,btm)
                for iz = 1:length(zlevels)
                    z = zlevels(iz);
                    
                    if (btm < z) && (z <= top)
                        VPList(iz,m) = Lvp;
                        VSList(iz,m) = Lvs;
                        ROList(iz,m) = Lro;
                        % 
                        if(l<nlay)
                            QPList(iz,m) = Lqp;
                            QSList(iz,m) = Lqs;
                        else
                            QPList(iz,m) = temp(l-1,5);
                            QSList(iz,m) = temp(l-1,5);
                        end
                        %fprintf('      [%d]  %f  >>> %f\n',iz,z,Lrho)
                    end
                    if(z<=btm)
                        if(l == nlay)
                            VPList(iz,m) = Lvp;
                            VSList(iz,m) = Lvs;
                            ROList(iz,m) = Lro; 
                            
                            QPList(iz,m) = temp(nlay-1,5);
                            QSList(iz,m) = temp(nlay-1,5);
                        else
                            break;
                        end
                        %fprintf('      reached %f   (break)\n',z)
                        %fprintf('\n')
                        %break;
                    end
                end
                %pause
            end
        end
        
        dim = [ min(receiver_locations(:,1)),max(receiver_locations(:,1)), ...
                min(receiver_locations(:,2)),max(receiver_locations(:,2)), ...
                min(min(ZZList)),max(max(ZZList)) ];
    end
    function draw_1d_profile(hhdl, TMDL,linecol,linew)
        if(~isempty(TMDL))
            switch(property_1d_to_show)
                case 1;  Pty = TMDL(:,1); str = 'Vp (m/s)';
                case 2;  Pty = TMDL(:,2); str = 'Vs (m/s)';  
                case 3;  Pty = TMDL(:,3); str = 'Ro';
                % -----------------------------------4   id thickness    
                case 4;  Pty = TMDL(:,5); str = 'Qp';
                case 5;  Pty = TMDL(:,6); str = 'Qs';
                %
                case 6 
                    vp = TMDL(:,1);
                    vs = TMDL(:,2);
                    Pty = 0.5*(vp.^2 - 2*vs.^2)./(vp.^2 - vs.^2);% Nu
                    str = 'Poisson Rat.';
                case 7; Pty = DW{P.isshown.id}; str = 'Depth Weigth';% Depth-Weights 
                otherwise
                    Pty = TMDL(:,2); str = 'Vs (m/s)'; 
            end
            DH = TMDL(:,4);
            
            %%

            nl = size(DH,1);
            DL = zeros(nl+1,1);
            for ll=1:nl-1
                DL(ll+1) = -sum(DH(1:ll)); 
            end
            DL(nl+1) = -(sum(DH(1:ll))+20); 
            
            if(hhdl==hAx_1dprof); set(H.gui,'CurrentAxes',hAx_1dprof); end
            for ll=1:nl
                plot(hhdl,   Pty(ll)*[1;1],  [DL(ll);DL(ll+1)], 'Color',linecol,'linewidth',linew);
                hold(hhdl,  'on')
                if(ll<nl)
                    plot(hhdl,  [Pty(ll);Pty(ll+1)],  DL(ll+1)*([1;1]), 'Color',linecol,'linewidth',linew);
                end
            end
            %% User-defined Reference model (as profile)
            if(~isempty(REFERENCE_MODEL_dH))
                DHref = REFERENCE_MODEL_dH(:,4);
                nlref = size(DHref,1);
                DLref = zeros(nlref+1,1);
                for ll=1:nlref-1
                    DLref(ll+1) = -sum(DHref(1:ll)); 
                end
                DLref(nlref+1) = -1.2*(sum(DHref(1:ll)));%(sum(DHref(1:ll))+20);
                switch(property_1d_to_show)
                    case 1;  Pref = REFERENCE_MODEL_dH(:,1);
                    case 2;  Pref = REFERENCE_MODEL_dH(:,2);  
                    case 3;  Pref = REFERENCE_MODEL_dH(:,3);
                    % -----------------------------------4   id thickness    
                    case 4;  Pref = REFERENCE_MODEL_dH(:,5);
                    case 5;  Pref = REFERENCE_MODEL_dH(:,6);
                    %
                    case 6; 
                        vpref = REFERENCE_MODEL_dH(:,1);
                        vsref = REFERENCE_MODEL_dH(:,2);
                        Pref = 0.5*(vpref.^2 - 2*vsref.^2)./(vpref.^2 - vsref.^2);% Nu
                    otherwise
                        Pref = REFERENCE_MODEL_dH(:,2); str = 'Vs (m/s)'; 
                end
                for ll=1:nlref
                    plot(hhdl,   Pref(ll)*[1;1],  [DLref(ll);DLref(ll+1)],'g','linewidth',linew);
                    hold(hhdl,  'on')
                    if(ll<nlref);
                        plot(hhdl,  [Pref(ll);Pref(ll+1)],  DLref(ll+1)*([1;1]), 'g','linewidth',linew);
                    end
                end
            end
            %% User-defined Reference model (as sparse points)
            if(~isempty(REFERENCE_MODEL_zpoints))
                Zref = REFERENCE_MODEL_zpoints(:,4);
                switch(property_1d_to_show)
                    case 1;  Pref = REFERENCE_MODEL_zpoints(:,1);
                    case 2;  Pref = REFERENCE_MODEL_zpoints(:,2);  
                    case 3;  Pref = REFERENCE_MODEL_zpoints(:,3);
                    % -----------------------------------4   id thickness    
                    case 4;  Pref = REFERENCE_MODEL_zpoints(:,5);
                    case 5;  Pref = REFERENCE_MODEL_zpoints(:,6);
                    %
                    case 6; 
                        vpref = REFERENCE_MODEL_zpoints(:,1);
                        vsref = REFERENCE_MODEL_zpoints(:,2);
                        Pref = 0.5*(vpref.^2 - 2*vsref.^2)./(vpref.^2 - vsref.^2);% Nu
                    otherwise
                        Pref = REFERENCE_MODEL_zpoints(:,2); str = 'Vs (m/s)'; 
                end
                
               plot(hhdl,  Pref, Zref, 'og','linewidth',linew); 
            end
            
            
            %%
            grid on
            xlabel(str);
            ylabel('z(m)');
        end
    end
    function draw_Misfit_vs_it(newfigure)
        if(newfigure)
            hgui = figure('name',strcat('Optimization evolution: Site',num2str(P.isshown.id)));
            h_ax = axes('Parent',hgui,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            hgui = H.gui;
            h_ax = hAx_MvsIT;
        end
		
        
        set(hgui,'CurrentAxes',h_ax);
        hold(h_ax,'off')      
        if(~isempty(Misfit_vs_Iter))
            if(~isempty(Misfit_vs_Iter{P.isshown.id}))
                %
                cgraph= Misfit_vs_Iter{P.isshown.id}(:,3)./max(Misfit_vs_Iter{P.isshown.id}(:,3));
                sgraph= Misfit_vs_Iter{P.isshown.id}(:,4)./max(Misfit_vs_Iter{P.isshown.id}(:,4));
                graph = Misfit_vs_Iter{P.isshown.id}(:,2)./max(Misfit_vs_Iter{P.isshown.id}(:,2));
                
                %cgraph= Misfit_curve_term_w * Misfit_vs_Iter{P.isshown.id}(:,3)/max(Misfit_vs_Iter{P.isshown.id}(:,3));
                %sgraph= Misfit_slope_term_w * Misfit_vs_Iter{P.isshown.id}(:,4)/max(Misfit_vs_Iter{P.isshown.id}(:,4));
                %
                xscal = Misfit_vs_Iter{P.isshown.id}(:,1);
                plot(h_ax, xscal, graph,'.-k','LineWidth',3,'MarkerSize',5);
                hold(h_ax,'on')
                plot(h_ax,  xscal, cgraph,'-r','LineWidth',3,'MarkerSize',1);
                plot(h_ax,  xscal, sgraph,'-g','LineWidth',3,'MarkerSize',1);
                
                grid on
                xlabel(h_ax,'it, [k]Misfit [r]Curve [g]slope');
                ylabel(h_ax,'100 M/M_0');
                
                ylim([0 1]);
            end
        end
    end
    function draw_Misfit_vs_it__MULTIPLE(newfigure)
        if(newfigure)
            hgui = figure('name','Optimization evolution (Laterally constrained)');
            h_ax(1) = axes('Parent',hgui,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.1 0.1   0.35 0.8]);
            h_ax(2) = axes('Parent',hgui,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.6 0.1   0.35 0.8]);
        else
            hgui = H.gui;
            h_ax(1) = hAx_MvsIT_full;
            h_ax(2) = hAx_MvsIT_full_local;
        end
		     
        if(~isempty(Misfit_vs_Iter_MULPTIPLE))
            %
            %% GLOBAL PLOT
            set(hgui,'CurrentAxes',h_ax(1));
            hold(h_ax(1),'off') 
            %
            % Misfit_vs_Iter_MULPTIPLE = [Misfit_vs_Iter_MULPTIPLE; [nsofar ,Energy, GlobalMisfit, RegularizerValue, Curv_term,Slop_term] ]; 
            cgraph= Misfit_vs_Iter_MULPTIPLE(:,5)./max(Misfit_vs_Iter_MULPTIPLE(:,5));
            sgraph= Misfit_vs_Iter_MULPTIPLE(:,6)./max(Misfit_vs_Iter_MULPTIPLE(:,6));
            graph = Misfit_vs_Iter_MULPTIPLE(:,2)./max(Misfit_vs_Iter_MULPTIPLE(:,2));
            REGgraph = Misfit_vs_Iter_MULPTIPLE(:,4)./max(Misfit_vs_Iter_MULPTIPLE(:,4));
            %cgraph= Misfit_curve_term_w * Misfit_vs_Iter{P.isshown.id}(:,3)/max(Misfit_vs_Iter{P.isshown.id}(:,3));
            %sgraph= Misfit_slope_term_w * Misfit_vs_Iter{P.isshown.id}(:,4)/max(Misfit_vs_Iter{P.isshown.id}(:,4));
            %
            xscal = Misfit_vs_Iter_MULPTIPLE(:,1);
            plot(h_ax(1),  xscal, REGgraph,'-y','LineWidth',3,'MarkerSize',1);
            hold(h_ax(1),'on')
            plot(h_ax(1),  xscal, cgraph,'-r','LineWidth',3,'MarkerSize',1);
            plot(h_ax(1),  xscal, sgraph,'-g','LineWidth',3,'MarkerSize',1);
            plot(h_ax(1),  xscal, graph,'.-k','LineWidth',3,'MarkerSize',5);
            grid on
            xlabel(h_ax(1),'it, [k]Misfit [r]Curve [g]slope [y]Regularizer');
            ylabel(h_ax(1),'100 M/M_0');

            ylim([0 1]);
            title('Global evolution')
            
            %
            %% Local PLOT
            set(hgui,'CurrentAxes',h_ax(2));
            hold(h_ax(2),'off') 
            normalized_local_misfits = Misfit_vs_Iter_MULPTIPLE_local(end,:)./ max(Misfit_vs_Iter_MULPTIPLE_local); 
            
            plot(h_ax(2),  normalized_local_misfits, '.-k','LineWidth',3,'MarkerSize',5);
            grid on
            xlabel(h_ax(2),'Location ID');
            ylabel(h_ax(2),'100 M(i)/M_0(i)');
            ylim([0 1]);
            title('Local evolution')
        end
    end
    
    function plot_2d_profile(newfigure, quantity)
        if(newfigure)
            figure_handle = figure('name','Model visualization');
            axes_handle = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            figure_handle = H.gui;
            axes_handle = hAx_2Dprof;
        end
        
        set(figure_handle,'CurrentAxes',axes_handle);
        hold(axes_handle,'off')
        %% Visibility OFF
        set(axes_handle, 'Visible','off');
        cla(axes_handle)
        %plot(0,0)
        
        if(isempty(P.profile_ids))
            Message = ['Profiles not yet defined.'];
            msgbox(Message,'CREDITS:')
            return;
        end
        if P.profile.id==0; P.profile.id=1; end
        Pid = P.profile.id;
        ids = P.profile_ids{Pid,1}(:,1);
        
        % prepare elevation points
        show_terrain = get(h_togg_terrain,'Value');
        terrain_elevation = 0*P.profile_ids{Pid,1}(:,1);
        bedrockline = (bedrock(3,ids))';
        if show_terrain==1
            for m = 1:size(P.profile_ids{Pid,1},1) 
                recID = P.profile_ids{Pid,1}(m,1);
                terrain_elevation(m) =  receiver_locations(recID,3);
                bedrockline(m) = bedrock(3,recID) + terrain_elevation(m); 
            end
        end
        
        % prepare profile        
        Pname = P.profile_name{Pid,1};
        if strcmp(Pname,'none'); Pname=strcat('profile-',num2str(Pid)); end

        %  quantity
        %  vp  vs  rho  xhx  Qp  Qs
        if (isempty(ROList) || isempty(VPList) || isempty(QPList) || isempty(VSList) || isempty(QSList)); refresh_models_list2D(); end       
        switch(quantity)
            case 1; tmp = VPList; str=strcat('Vp in: ',Pname);
            
            case 3; tmp = ROList; str=strcat('RO in: ',Pname);
            case 4; tmp = QPList; str=strcat('Qp in: ',Pname);
            case 5; tmp = QSList; str=strcat('Qs in: ',Pname);
            otherwise; tmp = VSList; str=strcat('Vs in: ',Pname); 
        end
%       
        
        tmp = tmp(:, ids);
        rr = P.profile_ids{Pid,1}(:,2);% profile_ids(:,2);
        [bottom_Z] = imagenorm(tmp,  rr, zlevels, nx_ticks,nz_ticks, smoothing_strategy,smoothing_radius,  show_terrain,terrain_elevation);
        set(axes_handle.Children, 'Visible','Off') 
		axis(axes_handle,'xy')
        hold(axes_handle,'on')
        set(axes_handle.Children, 'Visible','Off') 
        
        %% bedrock mask
        if get(T5_P1_HsMask,'Value')
            polygonx = [rr(1); rr; rr(end)];
            polygony = [bottom_Z; bedrockline; bottom_Z]-0.2*min( abs(bottom_Z - bedrockline) );
            hdl = fill(polygonx ,polygony, [0 0 0]);
            set(hdl, 'Visible','Off') 
        end
        %% layers boundaries
        if( get(h_togg_2D_layers_boundaries,'Value') )
            for m = 1:size(P.profile_ids{Pid,1},1) 
                idp = P.profile_ids{Pid,1}(m,1);%profile_ids(m,1);
                Z = modeldepths(idp);
                X =  rr(m) * ones(length(Z),1);

                hdl = plot(axes_handle,  X,Z,'ow','LineWidth',3,'MarkerSize',5);
                set(hdl, 'Visible','Off') 
            end
        end
        %% Bedrock line
        if( get(h_togg_2D_bedrock_line,'Value') )
            hdl = plot(axes_handle,  rr,bedrockline,'o-w','LineWidth',3,'MarkerSize',5);
            set(hdl, 'Visible','Off') 
        end
        %% measurement points
        if( get(h_togg_measpoints,'Value') ) 
            for m = 1:size(P.profile_ids{Pid,1},1) 
                recID = P.profile_ids{Pid,1}(m,1);
                hdl = plot(rr(m), terrain_elevation(m),'og','markersize',7,'markerfacecolor','g');
                set(hdl, 'Visible','Off') 
                
                hdl = text(rr(m), terrain_elevation(m), num2str(recID) );
                set(hdl, 'Visible','Off') 
            end
        end   
        title(str);
        %% Colormap
        if isempty(color_map); color_map = 'Jet'; end% fix colormap if not present
        colormap(axes_handle, color_map);
        %% Visibility ON
         set(axes_handle, 'Visible','on');
         set(axes_handle.Children, 'Visible','on');
	end
    function plot_3d(newfigure, quantity)
        if(newfigure)
            figure_handle = figure('name','Viewer 3D');
            axes_handle = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            figure_handle = H.gui;
            axes_handle = hAx_2Dprof;
        end
        
		if(property_23d_to_show == 0); return; end
        
        set(figure_handle,'CurrentAxes',axes_handle);
        hold(axes_handle,'off')
        %% Visibility OFF
        set(axes_handle, 'Visible','off');
        plot(0,0)
       
        %  quantity
        %  vp  vs  rho  xhx  Qp  Qs
        
        if (isempty(ROList) || isempty(VPList) || isempty(QPList) || isempty(VSList) || isempty(QSList)); refresh_models_list2D(); end       
        switch(quantity)
            case 1; prpperty = VPList;  Z = ZZList;  str='Vp';  nxx = nx_ticks; nyy = ny_ticks;
        
            case 3; prpperty = ROList;  Z = ZZList;  str='RO';  nxx = nx_ticks; nyy = ny_ticks; 
            case 4; prpperty = QPList;  Z = ZZList;  str='Qp';  nxx = nx_ticks; nyy = ny_ticks;
            case 5; prpperty = QSList;  Z = ZZList;  str='Qs';  nxx = nx_ticks; nyy = ny_ticks;
            case 6; prpperty = CYList;  Z = CXList;  str='Amplitude Profiler';
                 Np = size(FDAT,1); nxx = Np; nyy = Np;
                
            otherwise; prpperty = VSList; str='Vs'; Z = ZZList; nxx = nx_ticks; nyy = ny_ticks;
        end
        
        show_terrain = get(h_togg_terrain,'Value');
        SparseDtata_XYZD_to_3D(receiver_locations,Z,prpperty,nxx,nyy,cutplanes,show_terrain);
        
        view(viewerview); hold on
        title(str);
        
        if( get(h_togg_measpoints,'Value') )
            plot3(receiver_locations(:,1),receiver_locations(:,2),receiver_locations(:,3),'og','markersize',5,'markerfacecolor','g')
            hold on
            plot3(receiver_locations(:,1), receiver_locations(:,2), receiver_locations(:,3),'or');
        end
        
%MAYBE        for p=1:size(receiver_locations,1)
%MAYBE            text(receiver_locations(p,1), receiver_locations(p,2), receiver_locations(p,3)+2, num2str(p))
%MAYBE        end
        %% Colormap
        colormap(axes_handle, color_map);
        %% Visibility ON
         set(axes_handle, 'Visible','on');
    end
    function ViewerPostCallback(~,evd)%(obj,evd)
       viewerview= round(get(evd.Axes,'View'));
    end
        
    function [bottom_Z] = imagenorm( DATI, Xivec,Zjvec, nx,nz, smoothing_strategy,smoothing_radius,  show_terrain,terrain_elevation)% From 4.0.0
        % 
        % Xivec     x-location along the profile
        % Zjvec     layers, or Z ticks not accounting elevation. (max(Zjvec)  is always 0)
        %
        %DATI(DATI == 0) = NaN;
        currentaxes = gca;
        [XBef,ZBef] = meshgrid(Xivec,Zjvec);

        xmi = min(Xivec);
        xma = max(Xivec);
        zmi = min(Zjvec); min_z = zmi;
        zma = max(Zjvec);

        xi = linspace(xmi, xma, nx);%%  change resolution
        zi = fliplr(linspace(zmi, zma, nz));%%  change resolution
        [XAft,ZAft] = meshgrid(xi,zi);
        %save debug_imagenorm.mat
        DAft = interp2(XBef,ZBef,DATI,  XAft,ZAft);

        %% smoothing
        [DAft] = prfsmoothing(DAft, smoothing_strategy,smoothing_radius);
        %save('my_Vs_profile.txt','DAft','-ascii')% <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< ADD THIS !!!
        if show_terrain==0
            % OLD _____________________________________________________________________
            % image(xi,zi, DAft,'CDataMapping','scaled');
            % NEW______________________________________________________________________   
            lines1= linspace( min(min(DAft)), max(max(DAft)), 200 );
            hdl = contourf( xi, zi, DAft, lines1, 'EdgeColor','none'); 
            set(hdl, 'Visible','Off') 
            hold on
        end
        if show_terrain==1
            % create new matrix
            new_elevation = interp1(Xivec,terrain_elevation,  xi);
            elevation_min = min(terrain_elevation);
            elevation_max = max(terrain_elevation);
            %
            max_z = max(zi)+elevation_max;
            min_z = min(zi)+elevation_min;
            %dz = 0.5*( abs(zi(2)-zi(1)) );
            %newz = (min_z:dz:(max_z+dz))';
            newz = fliplr( linspace(min_z,max_z,nz) );
            
            
            newM = zeros( length(newz), size(DAft,2) ); 
            for cc = 1:size(DAft,2)
                oldz = zi + new_elevation(cc);
                newM(:,cc) = interp1(oldz,DAft(:,cc),  newz);
            end
            %% fill empty values
            for cc = 1:size(newM,2)
                for rw = 1:size(newM,1)
                    if ~isnan(newM(rw,cc))
                        newM(1:rw,cc) = newM(rw,cc);
                        break;
                    end
                end
                for rw = size(newM,1):-1:1
                    if ~isnan(newM(rw,cc))
                        newM(rw:end,cc) = newM(rw,cc);
                        break;
                    end
                end
            end
            
            %% plot image
            lines1= linspace( min(min(DAft)), max(max(DAft)), 200 );
            contourf( xi, newz, newM, lines1, 'EdgeColor','none');
            set(currentaxes.Children, 'Visible','Off') 
            hold on
            %% mask invalid sections
            %top
            polygonx = [Xivec(1); Xivec; Xivec(end)];
            polygony = [1.1*max_z; terrain_elevation; 1.1*max_z];
            hdl = fill(polygonx ,polygony, [1 1 1]);
            set(hdl, 'Visible','Off') 
            %bottom
            polygonx = [Xivec(1); Xivec; Xivec(end)];
            polygony = [(min_z-0.1); (terrain_elevation-range(Zjvec)); (min_z-0.1)];
            hdl = fill(polygonx ,polygony, [1 1 1]);
            set(hdl, 'Visible','Off') 
        end
        caxis([min(min(DATI)), max(max(DATI))])
        % 
        colorbar
        drawnow
        bottom_Z = (min_z-0.1);
    end% function
%%     function imagenorm( DATI, Xivec,Zjvec, nx,nz, smoothing_strategy,smoothing_radius)     NO ELEVATION V3.0.0
%         % 
%         % not accounts for elevation
%         %
%         %DATI(DATI == 0) = NaN;
% 
%         [XBef,ZBef] = meshgrid(Xivec,Zjvec);
% 
%         xmi = min(Xivec);
%         xma = max(Xivec);
%         zmi = min(Zjvec);
%         zma = max(Zjvec);
% 
%         xi = linspace(xmi, xma, nx);%%  change resolution
%         zi = fliplr(linspace(zmi, zma, nz));%%  change resolution
%         [XAft,ZAft] = meshgrid(xi,zi);
%         %save debug_imagenorm.mat
%         DAft = interp2(XBef,ZBef,DATI,  XAft,ZAft);
% 
%         %% smoothing
%         [DAft] = prfsmoothing(DAft, smoothing_strategy,smoothing_radius);
% 
%         
%         %
%         % OLD _____________________________________________________________________
%         % image(xi,zi, DAft,'CDataMapping','scaled');
%         % NEW______________________________________________________________________        
% 
%         lines1= linspace( min(min(DAft)), max(max(DAft)), 200 );
%         contourf( xi, zi, DAft, lines1, 'EdgeColor','none'); 
%         hold on
% 
%         vmax = max(max(DAft));
% 
%         % if( (vmax <= 1000) );                  lines = 100: 100 : 1000; end
%         % if( (1000 < vmax) && (vmax <= 1900) ); lines = 100: 150 : 1900; end
%         % if( (1900 < vmax) && (vmax <= 3100) ); lines = 100: 300 : 3100; end
%         % if( (vmax > 3000) );                   lines = 100: 500 : vmax; end
%         %lines = min(min(DAft)): 100 : max(max(DAft));
%         %[C,h] = contour( xi, zi, DAft, lines,'EdgeColor','k','Fill','off');
%         %clabel(C,h);
%         % _________________________________________________________________________
% 
% 
% 
%         caxis([min(min(DATI)), max(max(DATI))])
% 
%         % 
%         colorbar
%         drawnow
% 
%     end% function
%%
    function DL = modeldepths(m)
        DH = MDLS{1,m}(:,4);
        nlay = size(DH,1);
        DL = zeros(nlay+1,1);
        for ll=1:nlay-1
            DL(ll+1) = -sum(DH(1:ll)); 
        end
        DL(nlay+1) = zlevels(end);%-sum(DH(1:ll))-5;  
    end

    function get_curve_xindex_bounds(xmin,xmax)
        vec = abs(main_scale-xmin);
        ixmin_id = find( vec==min(vec) );
        ixmin_id = ixmin_id(1);
        %
        vec = abs(main_scale-xmax);
        ixmax_id = find( vec==min(vec) );
        ixmax_id = ixmax_id(1);
    end
    function [min_vs, min_vp_vs_ratio, max_vp_vs_ratio, ...
                min_ro,max_ro, ...
                min_H,max_H, ...
                min_qs,max_qs, ...
                min_qp_qs_ratio,max_qp_qs_ratio, ...
                HQMagnitude, ...
                HQEpicDistance, ...
                HQFocalDepth, ...
                HQRockRatio, ...
                sw_nmodes, ...
                sw_nsmooth, ...
                sensitivity_colormap, ...
                confidence_colormap] = load_defaults()
            %%
            min_vs                      = 80;

            min_vp_vs_ratio             = 1.73;
            max_vp_vs_ratio             = 4;

            min_ro                      = 1.7;
            max_ro                      = 2.5;

            min_H                       = 0.5;
            max_H                       = 9999;

            min_qs                      = 5;
            max_qs                      = 150;

            min_qp_qs_ratio             = 1.5;
            max_qp_qs_ratio             = 5;

            HQMagnitude                 = 6.0;
            HQEpicDistance              = 20;
            HQFocalDepth                = 10;
            HQRockRatio                 = 0.5;
            sw_nmodes                   =  15;
            sw_nsmooth                  =   5;
            %%
            load 'default_settings.mat';
            load 'sensitivity_colormap.mat';
            load 'confidence_colormap.mat';
    end
    
    function plot_extern(~,~,idx)
%         hxten = figure;
%         hAxs= axes('Parent',hxten,'Units', 'normalized','Units','normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position', [0.1 0.1 0.85 0.85]);
        switch(idx) 
            case 1% Curve-Weighting Function
                plot__curve_weights(1);
            case 2% Curve-Weighting Function
                plot__depth_weights(1);    
            case 3% survey locations
                Update_survey_locations();% no input = plot extern
            case 31% profile locations
                Update_profile_locations();% no input = plot extern    
            case 4% view data
                Show_survey(1)
            case 5% view model 1d
                Show_bestmodels_family(1);
            case 6% view model 2d
                if(property_23d_to_show>0)
                    %plot_2d_profile(hxten, hAxs, property_23d_to_show); 
                    % plot_3d(1, property_23d_to_show);
                    if(get(hwi23D,'Value') == 1)
                        plot_3d(1,property_23d_to_show);
                    end
                    if(get(hwi23D,'Value') == 2)
                        plot_2d_profile( 1,property_23d_to_show);
                    end
                end
            case 7% view confidence
                confidence_plot(1,  SS,poten, X1,X2, var1,var2, vala,valb, nlaya,nlayb)
            case 8% view sensitivity
                sensitivity_plot(1)
            case 9% view Misfit VS Iteration
                draw_Misfit_vs_it(1);
            case 10% view Misfit VS Iteration (for Multiple simultaneous evolution)
                draw_Misfit_vs_it__MULTIPLE(1);    
        end
    end
    function funct_saveimage(~,~,~)
        [file,thispath] =  uiputfile({'*.eps';'*.jpg';'*.fig'},'Save image as', strcat(working_folder,'image.eps'));
        fname = strcat(thispath,file);
        if( file ~= 0)
%             switch (idx)
%                 case 100; hh = hAx_1d_confidence;%  save confidence  
%                     
%             end
            
            saveas(H.gui, fname);% saveas(hh, fname);
            fprintf('Image saved.\n');
        end
    end
    %% Confidence
    function [SS,poten, X1,X2, var1,var2] = confidence_get_limits(vp,vs,ro,hh,qp,qs,daf, vala,valb, nlaya,nlayb)
        % 
        fprintf('>>>> confidence_get_limits()\n')
        
        if vala==1, var1=vp(:,nlaya); end
        if vala==2, var1=vs(:,nlaya); end
        if vala==3, var1=ro(:,nlaya); end
        if vala==4, var1=hh(:,nlaya); end
        if vala==5, var1=qp(:,nlaya); end
        if vala==6, var1=qs(:,nlaya); end
        if vala>=7, var1=daf; end

        if valb==1, var2=vp(:,nlayb); end
        if valb==2, var2=vs(:,nlayb); end
        if valb==3, var2=ro(:,nlayb); end
        if valb==4, var2=hh(:,nlayb); end
        if valb==5, var2=qp(:,nlayb); end
        if valb==6, var2=qs(:,nlayb); end
        if valb>=7, var2=daf; end

        %if valb==vala && nlayb==nlaya; nlaya=1; nalyb=2; end

        % lsmooth=str2num(get(hndl2.edit2,'string'));
        lsmooth = str2double(get(hconf_nsmooth,'string'));
        nlvl   =str2double(get(hconf_nlevels,'string'));

        
        lim11=min(var1); lim12=max(var1); 
        lim21=min(var2); lim22=max(var2); 
        
        if(lim11==lim12); tmp=lim11; lim11=tmp-0.00001; lim12=tmp+0.00001; end
        if(lim21==lim22); tmp=lim21; lim21=tmp-0.00001; lim22=tmp+0.00001; end
        
        step1=(lim12-lim11)/150;
        step2=(lim22-lim21)/150;
        
        X1=[lim11:step1:lim12];
        X2=[lim21:step2:lim22];

        fctr=4.;
        n1=length(X1); n2=length(X2);
%%SS        s=vs(:,end);%%SS               each row: [vs-lay1, vs-lay2, ... vs-hspace, er]
%%SS                           er is (weighted misfit)/(somma cumulativa pesi)
        s = misfit_over_sumweight;
        smax=max(s);
        SS = zeros(n2,n1);
        for i=1:n1
            for j=1:n2
                g=min(s(var1>X1(i)-step1*fctr & var1<X1(i)+step1*fctr & var2>X2(j)-step2*fctr & var2<X2(j)+step2*fctr));
                sizeg=size(g);
                if sizeg(1)*sizeg(2)>0
                    SS(j,i)=g;
                else
                    SS(j,i)=smax;
                end
            end
        end

        poten=1;
        %Plot_misfit;% ---->>> function confidence_plot()
    end
    function [SS,poten, X1,X2, var1,var2] = confidence_get_limits_x2(vpx,vsx,rox,hhx,qpx,qsx,dafx,  vpy,vsy,roy,hhy,qpy,qsy,dafy, vala,valb, nlaya,nlayb)
        % 
        
        fprintf('>>>> confidence_get_limits ()\n')
        if vala==1, var1=vpx(:,nlaya); end
        if vala==2, var1=vsx(:,nlaya); end
        if vala==3, var1=rox(:,nlaya); end
        if vala==4, var1=hhx(:,nlaya); end
        if vala==5, var1=qpx(:,nlaya); end
        if vala==6, var1=qsx(:,nlaya); end
        if vala>=7, var1=dafx; end
        
        if valb==1, var2=vpy(:,nlayb); end
        if valb==2, var2=vsy(:,nlayb); end
        if valb==3, var2=roy(:,nlayb); end
        if valb==4, var2=hhy(:,nlayb); end
        if valb==5, var2=qpy(:,nlayb); end
        if valb==6, var2=qsy(:,nlayb); end
        if valb>=7, var2=dafy; end

        if valb==vala && nlayb==nlaya; nlaya=1; nalyb=2; end

        % lsmooth=str2num(get(hndl2.edit2,'string'));
        lsmooth = str2double(get(hconf_nsmooth,'string'));
        
        %nlvl   =str2num(get(hndl2.edit3,'string'));
        nlvl   =str2double(get(hconf_nlevels,'string'));

        lim11=min(var1); lim12=max(var1);
        lim21=min(var2); lim22=max(var2);
        
        if(lim11==lim12); tmp=lim11; lim11=tmp-0.00001; lim12=tmp+0.00001; end
        if(lim21==lim22); tmp=lim21; lim21=tmp-0.00001; lim22=tmp+0.00001; end
        
        step1=(lim12-lim11)/150;
        step2=(lim22-lim21)/150;
        
        X1=[lim11:step1:lim12];
        X2=[lim21:step2:lim22];

        fctr=4.;
        n1=length(X1); n2=length(X2);
%%SS        s=vs(:,end);%%SS               each row: [vs-lay1, vs-lay2, ... vs-hspace, er]
%%SS                           er is (weighted misfit)/(somma cumulativa pesi)
        s = misfit_over_sumweight;
        smax=max(s);
        SS = zeros(n2,n1);
        for ii=1:n1
            for jj=1:n2
                g=min(s(var1>X1(ii)-step1*fctr & var1<X1(ii)+step1*fctr & var2>X2(jj)-step2*fctr & var2<X2(jj)+step2*fctr));
                sizeg=size(g);
                if sizeg(1)*sizeg(2)>0
                    SS(jj,ii)=g;
                else
                    SS(jj,ii)=smax;
                end
            end
        end

        poten=1;
        %Plot_misfit;% ---->>> function confidence_plot()
    end

    
    function confidence_plot(newfigure, SS,poten, X1,X2, var1,var2, vala,valb, nlaya,nlayb)
        if isempty(SS); return; end
        if(newfigure)
            hfig = figure('name','Confidence');
            hax = axes('Parent',hfig,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
        else
            hfig = H.gui;
            hax = hAx_1d_confidence;
        end
        %fprintf('>>>> confidence_plot()\n')
        SMa = nanmoving_average2(SS.^poten,lsmooth,lsmooth);
        
        SMa(SMa==0)=NaN;
        SMmin=min(min(SMa));
        SM=SMa./SMmin;
        SM=fcdf(SM,ndegfree,ndegfree);
        
        set(hfig,'CurrentAxes',hax);
        contourf(X1,X2,SM,nlvl); colorbar; shading flat; colormap(hax,confidence_colormap);
        
        hold on
        plot(var1(misfit_over_sumweight==min(misfit_over_sumweight)),var2(misfit_over_sumweight==min(misfit_over_sumweight)),'o','Markerfacecolor','w','Markeredgecolor','k'); hold off;
        grid on

        if vala==1,  xlabel(['Vp ' num2str(nlaya)]); end
        if vala==2,  xlabel(['Vs ' num2str(nlaya)]); end
        if vala==3,  xlabel(['Rho ' num2str(nlaya)]);end
        if vala==4,  xlabel(['H ' num2str(nlaya)]);  end
        if vala==5,  xlabel(['Qp ' num2str(nlaya)]); end
        if vala==6,  xlabel(['Qs ' num2str(nlaya)]); end
        if vala>=7,  xlabel('DAF');end

        if valb==1,  ylabel(['Vp ' num2str(nlayb)]); end
        if valb==2,  ylabel(['Vs ' num2str(nlayb)]); end
        if valb==3,  ylabel(['Rho ' num2str(nlayb)]);end
        if valb==4,  ylabel(['H ' num2str(nlayb)]);  end
        if valb==5,  ylabel(['Qp ' num2str(nlayb)]); end
        if valb==6,  ylabel(['Qs ' num2str(nlayb)]); end
        if valb>=7,  ylabel('DAF');end
    end
    function [ldof] = get_locked_dof_1d(id)
        ldof = 0;
        nlay = size(MDLS{id}, 1);
        ldof = ldof + sum(sum(not(logical(LKT(1:nlay,:))))) - 3;
    end
    function [ldof] = get_locked_dof_2d()
        ldof = 0;
        nmdls = size(MDLS, 1);
        
        for m = 1:nmdls
            nlay = size(MDLS{m}, 1);
            ldof = ldof + sum(sum(not(logical(LKT(1:nlay,:))))) - 3;
        end
    end
    function [DAF] = get_amplification_factor(x_vec,aswave)
        %FS=interp1(fFS,FSraw,main_scale,'linear','extrap')';
        FS=interp1(  HQfreq, QHspec,  x_vec,'linear','extrap')';
        FS(x_vec>25)=0; FS(x_vec<0.1)=0; % FS is defined only for 0.1<=f<=25 Hz
        aFS=FS.*(aswave.');
        rms_eqk=sqrt( mean( FS(FS>0).^2) );
        rms_amp=sqrt( mean(aFS(FS>0).^2) );
        DAF=rms_amp/rms_eqk;%SS -----------------------------------------------DAF 
        
        %figure; plot(x_vec,aswave,'k'); hold on; plot(x_vec,FS,'r')
    end
% _________________________________________________________________________
    %% Sensitivity
    function [vala, nlaya] = sensitivity_parameter_id()
        fprintf('>>>> sensitivity_parameter_id()\n')
        vala =get( hsns_xprop ,'value');%  parameter name 1
        nlaya=get( hsns_xlay ,'value');% id of layer under study
    end
    function sensitivity_plot(newfigure)
        if(isempty(SN_dtamsf)); return; end
            if(newfigure)
                figure_handle = figure('name','Sensitivity');
                axes_handle = axes('Parent',figure_handle,'Units', 'normalized','FontSize',USER_PREFERENCE_interface_objects_fontsize,'Position',[0.125 0.125 0.775 0.775]);
            else
                figure_handle = H.gui;
                axes_handle = hAx_sensitivity;
            end    
            nlv = str2double(get(hsns_nlevels,'String'));
            
            set(figure_handle,'CurrentAxes',axes_handle);%figure_handle
            hold(axes_handle,'off')
            %axis(axes_handle,'xy')
            %hold(axes_handle,'on')

            %SN_xscale, SN_parscale, SN_dtamsf, SN_parname

            lines1= linspace( min(min(SN_dtamsf)), max(max(SN_dtamsf)), nlv);
            contourf( SN_xscale, SN_parscale, SN_dtamsf, lines1, 'EdgeColor','none');
            hold on

            %-> lines1= [-0.2  0.2]; 
            %-> [C,h] = contourf( SN_xscale, SN_parscale, SN_dtamsf, lines1, 'EdgeColor','k','Fill','off');
            %-> clabel(C,h);
            plot(SN_xscale,SN_centralval,'--r','linewidth',2)


            colormap(axes_handle, sensitivity_colormap);
            colorbar;
            grid on;
            caxis([-1,1]);
            xlabel('Frequency')
            ylabel(SN_parname)

            set(axes_handle,'XScale','log')
        
    end

% _________________________________________________________________________
    %% MATLAB MACHINE
    function create_new_tab(tabname)
        P.tab_id=P.tab_id+1;
        switch Matlab_Release
            case '2010a'
                H.TABS(P.tab_id)  = uitab('v0','Parent',hTabGroup, 'Title',tabname);
            case '2015b'
                H.TABS(P.tab_id)  = uitab('Parent',hTabGroup, 'Title',tabname);
            case '2014a'
                H.TABS(P.tab_id)  = uitab('Parent',hTabGroup, 'Title',tabname);
            case '2017b'
                H.TABS(P.tab_id)  = uitab('Parent',hTabGroup, 'Title',tabname);    
            otherwise
                H.TABS(P.tab_id)  = uitab('Parent',hTabGroup, 'Title',tabname);
        end
    end
    function [height] = get_normalheight_on_panel(panel_handle,gui_height)
        %
        % translate normal height of with respect to full GUI
        % into a value valid for the specified panel
        %
        vecposition = get(panel_handle,'position');%,'linewidth',1);
        panel_points = G.main_h*vecposition(4);% panel height in points
        panel_over_main_ratio =  panel_points/G.main_h;%                  ratio referred to full interface
        height = gui_height/panel_over_main_ratio;%                   unitary height of objects in this pane
    end    
end% end gui






























%
