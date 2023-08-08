
%% INFO
P.appname_3D = 'OpenHVSR-3D Inversion  (BETA)';%% Note: the "3D" in P.appname is used to recognize dimensionality
P.appversion_3D = '4.0.2';

%% Data shown
P.isshown.id                    = 0;%  Id of dataset shown in inversion
% P.isshown.accepted_windows      = [];% is accepted windows are changed it will be recorded here

%% Inversion shown
%P.invshown.id                    = 0;% NOT USED YET Id of inversion parameters shown in inversion

%% Profiles
% P.profile.id                    = 0;%  actually considered 2D profile
% P.profile.smoothing_strategy    = 3;
% P.profile.smoothing_radius      = 3;
% P.profile.normalization_strategy= 1;
% P.profile.N_X_points            = 50;
% P.profile.color_limits          = [0 10];
% P.profile_ids     = {};% FIX SAVE                          % (3D) [id's; x-position, distances from rect] to create a 2D profile
% P.profile_line    = {};% FIX SAVE                          % (3D)
% P.profile_onoff   = {};% FIX SAVE
%
%% Graphics
% NO P.cutplanes       = [0,1, 0,1, 0,1];             % (3D) sliders for slicing
% P.viewerview = [ -37.5, 30.0];
% P.colormapis = 'jet';
% %
% P.data_aspectis_main      = [1 1 1];
% P.data_aspectis_aerialmap = [1 1 1];
% P.data_aspectis_profile   = [1 0.5 1];
% P.data_aspectis_IVSeW     = [1 1 1];
% %
% P.current_axis_handles = [];
% %     Curves in "computations" tab
% P.hvsr__curve_thickness =1.5;% 0.8;
% P.error_curve_thickness = 1;%0.5; <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
% P.info__curve_thickness = 1;%0.5;% indicating where main peak occurs <<<<<<<<<<<<<<<<<<<
% %
% P.regression_computed          = [];
% P.regression_Ibs_von_Seht_1999 = [  96,    -1.388];% Ibs-von Seht and Wohlenberg 1999
% P.regression_Parolai_2002      = [ 108,    -1.551];% Parolai et al. (2002)	108.0	?1.551
% P.regression_Hinzen_2004       = [ 137,    -1.190];% Hinzen et al. (2004)	137.0	?1.190
%%     3D-View
% P.property_23d_to_show = 0;
% P.Reference_Freq_scale= [];%  was P.View3D_reference_Freq_scale= [];
% % 
% % 
%% GUI
%%    Tabs handles
H.TABS = [];% Handels of tabs
P.tab_id    = 0;
%%    Menu handles
H.menu.settings.log = 0;% explicitly declared for compatibility with the new menu handles organization (ferom V 4.0.0)
%%    Main window sizing and creation
P.DSP = get(0,'ScreenSize');% [left, bottom, width, height]
G.main_l = 0.1 * P.DSP(3);
G.main_b = 0.1 * P.DSP(4);
G.main_w = 0.8 * P.DSP(3);
G.main_h = 0.8 * P.DSP(4);%  (size on my pc: 614.8 )
H.gui = figure('Visible','off','OuterPosition',[G.main_l, G.main_b, G.main_w, G.main_h],'NumberTitle','off');
H.view_rotation = rotate3d;
set(H.view_rotation ,'ActionPostCallback',@ViewerPostCallback);
%%    Objects Sizing
G.Full_height_divided_by = 30;% n of rows on the interface
G.main_dw = 0.01;
%G.main_objh = 0.9/G.Full_height_divided_by; % object size (normalized) referred to full height of interface
G.main_objh = 1/G.Full_height_divided_by; % object size (normalized) referred to full height of interface
G.main_object_levels = ((G.Full_height_divided_by-1):-1:0)./G.Full_height_divided_by;
% % % %%    TAB: Windowing
% % % %%        horizontal axis
% % % P.TAB_Windowing.hori_axis_limits__time = [];% Tab windows, horizontal axis limits
% % % %%    TAB: Computations
% % % %%        custom color axis     
% % % P.TAB_Computations.custom_caxis_spectrum     = [];
% % % P.TAB_Computations.custom_caxis_hvsr_windows = [];
% % % P.TAB_Computations.custom_caxis_hvsr         = [];
% % % P.TAB_Computations.custom_caxis_directional  = [];
% % % %
% % % %%        horizontal axis
% % % P.TAB_Computations.hori_axis_limits__windows   = [];% Tab computations, horizontal axis limits
% % % P.TAB_Computations.hori_axis_limits__frequence = [];
% % % P.TAB_Computations.hori_axis_limits__angles    = [];
% % % P.TAB_Computations.hori_axis_limits__angleshv  = [];
% % % %%        vertical axis
% % % P.TAB_Computations.vert_axis_limits__windows   = [];% Tab computations, horizontal axis limits
% % % P.TAB_Computations.vert_axis_limits__frequence = [];
% % % P.TAB_Computations.vert_axis_limits__angles    = [];
% % % P.TAB_Computations.vert_axis_limits__angleshv  = [];
% % % %%    TAB: 3D view
% % % P.TAB_view3d_Discretization = [50, 50];
% % % %%    TAB: IVS&W
% % % P.TAB_IBSeW_Discretization = [50, 50];
%
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 

%%
