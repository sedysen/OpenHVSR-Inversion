%% if isfield(BIN,'');  = BIN.; end
if isfield(BIN,'file'); file = BIN.file; end
if isfield(BIN,'thispath'); thispath = BIN.thispath; end
if isfield(BIN,'ui_dist'); ui_dist = BIN.ui_dist; end
if isfield(BIN,'ui_ex'); ui_ex = BIN.ui_ex; end                
if isfield(BIN,'ui_fref'); ui_fref = BIN.ui_fref; end 
if isfield(BIN,'ui_frnge_1'); ui_frnge_1 = BIN.ui_frnge_1; end
if isfield(BIN,'ui_frnge_2'); ui_frnge_2 = BIN.ui_frnge_2; end
if isfield(BIN,'ui_frnge_d'); ui_frnge_d = BIN.ui_frnge_d; end
if isfield(BIN,'ui_hh_pc'); ui_hh_pc = BIN.ui_hh_pc; end                  
if isfield(BIN,'ui_qp_pc'); ui_qp_pc = BIN.ui_qp_pc; end                        
if isfield(BIN,'ui_qp_ww'); ui_qp_ww = BIN.ui_qp_ww; end                       
if isfield(BIN,'ui_qs_pc'); ui_qs_pc = BIN.ui_qs_pc; end
if isfield(BIN,'ui_qs_ww'); ui_qs_ww = BIN.ui_qs_ww; end
if isfield(BIN,'ui_ro_pc'); ui_ro_pc = BIN.ui_ro_pc; end
if isfield(BIN,'ui_ro_ww'); ui_ro_ww = BIN.ui_ro_ww; end
if isfield(BIN,'ui_vp_pc'); ui_vp_pc = BIN.ui_vp_pc; end 
if isfield(BIN,'ui_vp_ww'); ui_vp_ww = BIN.ui_vp_ww; end
if isfield(BIN,'ui_vs_pc'); ui_vs_pc = BIN.ui_vs_pc; end
if isfield(BIN,'ui_vs_ww'); ui_vs_ww = BIN.ui_vs_ww; end
%   ---- gui_2D ----------------------------------------------------------------------------
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
if isfield(BIN,'Nrowa'); Nrowa = BIN.Nrowa; end
if isfield(BIN,'QHspec'); QHspec = BIN.QHspec; end
if isfield(BIN,'QPprofile'); QPprofile = BIN.QPprofile; end
if isfield(BIN,'QSprofile'); QSprofile = BIN.QSprofile; end
if isfield(BIN,'RCT'); RCT = BIN.RCT; end
if isfield(BIN,'REFERENCE_MODEL_dH'); REFERENCE_MODEL_dH = BIN.REFERENCE_MODEL_dH; end
if isfield(BIN,'REFERENCE_MODEL_zpoints'); REFERENCE_MODEL_zpoints = BIN.REFERENCE_MODEL_zpoints; end
if isfield(BIN,'ROprofile'); ROprofile = BIN.ROprofile; end
if isfield(BIN,'S'); S = BIN.S; end
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
% (3D)
% (3D)
% (3D)
% (3D)
% (3D)
% (3D)
if isfield(BIN,'T2_P1_global_it_count'); T2_P1_global_it_count = BIN.T2_P1_global_it_count; end
if isfield(BIN,'T2_P1_max_it'); T2_P1_max_it = BIN.T2_P1_max_it; end
if isfield(BIN,'T3_P1_inv'); T3_P1_inv = BIN.T3_P1_inv; end
if isfield(BIN,'T3_P1_invSW'); T3_P1_invSW = BIN.T3_P1_invSW; end
if isfield(BIN,'T3_P1_it_count'); T3_P1_it_count = BIN.T3_P1_it_count; end
if isfield(BIN,'T3_P1_max_it'); T3_P1_max_it = BIN.T3_P1_max_it; end
if isfield(BIN,'T3_P1_txt'); T3_P1_txt = BIN.T3_P1_txt; end
if isfield(BIN,'T3_p1_revert'); T3_p1_revert = BIN.T3_p1_revert; end
if isfield(BIN,'T5_P1_HsMask'); T5_P1_HsMask = BIN.T5_P1_HsMask; end
if isfield(BIN,'T5_P1_txtx'); T5_P1_txtx = BIN.T5_P1_txtx; end
if isfield(BIN,'T5_P1_txty'); T5_P1_txty = BIN.T5_P1_txty; end
if isfield(BIN,'T6_P1_txtx'); T6_P1_txtx = BIN.T6_P1_txtx; end
if isfield(BIN,'TO_INVERT'); TO_INVERT = BIN.TO_INVERT; end
if isfield(BIN,'VPprofile'); VPprofile = BIN.VPprofile; end
if isfield(BIN,'VSprofile'); VSprofile = BIN.VSprofile; end
if isfield(BIN,'X1'); X1 = BIN.X1; end
if isfield(BIN,'X2'); X2 = BIN.X2; end
if isfield(BIN,'Zprofile'); Zprofile = BIN.Zprofile; end
if isfield(BIN,'ans'); ans = BIN.ans; end
if isfield(BIN,'appname'); appname = BIN.appname; end
if isfield(BIN,'basevalue'); basevalue = BIN.basevalue; end
if isfield(BIN,'basevaluew'); basevaluew = BIN.basevaluew; end
if isfield(BIN,'bedrock'); bedrock = BIN.bedrock; end
if isfield(BIN,'best_FDAT'); best_FDAT = BIN.best_FDAT; end
if isfield(BIN,'beta_stuff_enable_status'); beta_stuff_enable_status = BIN.beta_stuff_enable_status; end
if isfield(BIN,'color_limits'); color_limits = BIN.color_limits; end
if isfield(BIN,'conf_1d_to_show_x'); conf_1d_to_show_x = BIN.conf_1d_to_show_x; end
if isfield(BIN,'conf_1d_to_show_y'); conf_1d_to_show_y = BIN.conf_1d_to_show_y; end
if isfield(BIN,'confidence_colormap'); confidence_colormap = BIN.confidence_colormap; end
if isfield(BIN,'curve_plotmode'); curve_plotmode = BIN.curve_plotmode; end
if isfield(BIN,'curve_weights_plotmode'); curve_weights_plotmode = BIN.curve_weights_plotmode; end
if isfield(BIN,'data_1d_to_show'); data_1d_to_show = BIN.data_1d_to_show; end
% (3D)
if isfield(BIN,'datafile_columns'); datafile_columns = BIN.datafile_columns; end
if isfield(BIN,'datafile_separator'); datafile_separator = BIN.datafile_separator; end
if isfield(BIN,'default_colormap'); default_colormap = BIN.default_colormap; end
if isfield(BIN,'depth_weights_plotmode'); depth_weights_plotmode = BIN.depth_weights_plotmode; end
if isfield(BIN,'dh'); dh = BIN.dh; end
% (3D)
if isfield(BIN,'dw'); dw = BIN.dw; end
if isfield(BIN,'dx'); dx = BIN.dx; end
% NO  if isfield(BIN,'eh52'); eh52 = BIN.eh52; end
% NO  if isfield(BIN,'eh52_childs'); eh52_childs = BIN.eh52_childs; end
if isfield(BIN,'enable_menu'); enable_menu = BIN.enable_menu; end
if isfield(BIN,'fontsizeis'); fontsizeis = BIN.fontsizeis; end
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
% %   hT2_P1                                                     
% %   hT2_P2                                                     
% %   hT2_P3                                                     
% %   hT3_P1                                                     
% %   hT3_P2                                                     
% %   hT3_P3                                                     
% %   hT3_P4                                                     
% %   hT4_P1                                                     
% %   hT4_P2                                                     
% %   hT5_PA                                                     
% %   hT5_PB                                                     
% %   hT5_PC                                                     
% %   hT5_PD                                                     
% %   hT6_PA                                                     
% %   hT6_PC                                                     
% %   hTabGroup                                                  
% %   hTab_1d_viewer                                             
% %   hTab_2d_viewer                                             
% %   hTab_Confidenc                                             
% %   hTab_Inversion                                             
% %   hTab_Sensitivt                                             
% %   hTab_mod                                                   
% %   hTab_mod_cnames                                    
% %   hTab_mod_hcmenu                                            
% %   h_1d_next                                                  
% %   h_1d_prev                                                  
% %   h_dscale                                                   
% %   h_ex_val                                                   
% %   h_fref_val                                                 
% %   h_fwd_sw                                                   
% %   h_gui                                                      
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
if isfield(BIN,'main_b'); main_b = BIN.main_b; end
if isfield(BIN,'main_h'); main_h = BIN.main_h; end
if isfield(BIN,'main_l'); main_l = BIN.main_l; end
if isfield(BIN,'main_scale'); main_scale = BIN.main_scale; end
if isfield(BIN,'main_w'); main_w = BIN.main_w; end
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
if isfield(BIN,'min_ro'); min_r = BIN.min_ro; end
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
%  (3D)
if isfield(BIN,'nz_ticks'); nz_ticks = BIN.nz_ticks; end
if isfield(BIN,'objh'); objh = BIN.objh; end
if isfield(BIN,'objn'); objn = BIN.objn; end
if isfield(BIN,'objw'); objw = BIN.objw; end
if isfield(BIN,'objx'); objx = BIN.objx; end
if isfield(BIN,'objy'); objy = BIN.objy; end
if isfield(BIN,'pos_axes'); pos_axes = BIN.pos_axes; end
if isfield(BIN,'pos_axes2'); pos_axes2 = BIN.pos_axes2; end
if isfield(BIN,'pos_axis'); pos_axis = BIN.pos_axis; end
if isfield(BIN,'pos_panel'); pos_panel = BIN.pos_panel; end
if isfield(BIN,'pos_table'); pos_table = BIN.pos_table; end
if isfield(BIN,'poten'); poten = BIN.poten; end
if isfield(BIN,'prev_BEST_SINGLE_MISFIT'); prev_BEST_SINGLE_MISFIT = BIN.prev_BEST_SINGLE_MISFIT; end
if isfield(BIN,'prev_BEST_SINGLE_MODELS'); prev_BEST_SINGLE_MODELS = BIN.prev_BEST_SINGLE_MODELS; end
if isfield(BIN,'prev_MDLS'); prev_MDLS = BIN.prev_MDLS; end
if isfield(BIN,'prev_best_FDAT'); prev_best_FDAT = BIN.prev_best_FDAT; end
if isfield(BIN,'prev_single_it'); prev_single_it = BIN.prev_single_it; end
%  (3D)
%  (3D)
if isfield(BIN,'property_1d_to_show'); property_1d_to_show = BIN.property_1d_to_show; end
if isfield(BIN,'property_2d_to_show'); property_2d_to_show = BIN.property_2d_to_show; end
% (3D)
% (3D)
% (3D)
if isfield(BIN,'row'); row = BIN.row; end
if isfield(BIN,'sensitivity_colormap'); sensitivity_colormap = BIN.sensitivity_colormap; end
if isfield(BIN,'smoothing_radius'); smoothing_radius = BIN.smoothing_radius; end
if isfield(BIN,'smoothing_strategy'); smoothing_strategy = BIN.smoothing_strategy; end
if isfield(BIN,'sns_1d_to_show'); sns_1d_to_show = BIN.sns_1d_to_show; end
if isfield(BIN,'str'); str = BIN.str; end
if isfield(BIN,'sw_nmodes'); sw_nmodes = BIN.sw_nmodes; end
if isfield(BIN,'sw_nsmooth'); sw_nsmooth = BIN.sw_nsmooth; end
if isfield(BIN,'vala'); vala = BIN.vala; end
if isfield(BIN,'valb'); valb = BIN.valb; end
if isfield(BIN,'var1'); var1 = BIN.var1; end
if isfield(BIN,'var2'); var2 = BIN.var2; end
if isfield(BIN,'version'); version = BIN.version; end
if isfield(BIN,'vfst_MDLS'); vfst_MDLS = BIN.vfst_MDLS; end
if isfield(BIN,'view_max_scale'); view_max_scale = BIN.view_max_scale; end
if isfield(BIN,'view_min_scale'); view_min_scale = BIN.view_min_scale; end
%  (3D)
if isfield(BIN,'weight_curv'); weight_curv = BIN.weight_curv; end
if isfield(BIN,'weight_dpth'); weight_dpth = BIN.weight_dpth; end
if isfield(BIN,'working_folder'); working_folder = BIN.working_folder; end
if isfield(BIN,'x'); x = BIN.x; end
if isfield(BIN,'xpositions'); xpositions = BIN.xpositions; end
if isfield(BIN,'zlevels'); zlevels = BIN.zlevels; end
