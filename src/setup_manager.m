function [min_vs, ...
          min_vp_vs_ratio,max_vp_vs_ratio, ...
          min_ro,max_ro, ...
          min_H ,max_H, ...
          min_qs,max_qs, ...
          min_qp_qs_ratio,max_qp_qs_ratio, ...
          HQMagnitude, ...
          HQEpicDistance, ...
          HQFocalDepth, ...
          HQRockRatio, ...
          sw_nmodes, ...
          sw_nsmooth] = setup_manager( ...
          inmin_vs, ...
          inmin_vp_vs_ratio, inmax_vp_vs_ratio, ...
          inmin_ro,inmax_ro, ...
          inmin_H ,inmax_H, ...
          inmin_qs,inmax_qs, ...
          inmin_qp_qs_ratio,inmax_qp_qs_ratio, ...
          inHQMagnitude, ...
          inHQEpicDistance, ...
          inHQFocalDepth, ...
          inHQRockRatio, ...
          insw_nmodes, ...
          insw_nsmooth)


% % function aa()
% % close all; clear; clc
% % load 'default_settings.mat'
% % inmin_vs = min_vs;
% % inmin_vp_vs_ratio =min_vp_vs_ratio; 
% % inmax_vp_vs_ratio =max_vp_vs_ratio;
% % inmin_ro = min_ro;
% % inmax_ro = max_ro;
% % inmin_H = min_H;
% % inmax_H = max_H;
% % inmin_qs = min_qs;
% % inmax_qs = max_qs;
% % inmin_qp_qs_ratio =min_qp_qs_ratio;
% % inmax_qp_qs_ratio=max_qp_qs_ratio;
% % 
% % inHQMagnitude   =HQMagnitude;
% % inHQEpicDistance=HQEpicDistance;
% % inHQFocalDepth  =HQFocalDepth;
% % inHQRockRatio   =HQRockRatio;
%     
    %% init values
    min_vs = inmin_vs; 
    
    min_vp_vs_ratio = inmin_vp_vs_ratio;
    max_vp_vs_ratio = inmax_vp_vs_ratio;
    
    min_ro = inmin_ro;
    max_ro = inmax_ro;
          
    min_H = inmin_H;
    max_H = inmax_H;
          
    min_qs = inmin_qs;
    max_qs = inmax_qs;
          
    min_qp_qs_ratio = inmin_qp_qs_ratio;
    max_qp_qs_ratio = inmax_qp_qs_ratio;
    
    
    sw_nmodes   = insw_nmodes;
    sw_nsmooth  = insw_nsmooth;
    
          
    HQMagnitude   = inHQMagnitude;
    HQEpicDistance= inHQEpicDistance;
    HQFocalDepth  = inHQFocalDepth;
    HQRockRatio   = inHQRockRatio;
    %% 
    DSP = get(0,'ScreenSize');% [left, bottom, width, height]
    main_l = 0.1 * DSP(3);
    main_b = 0.1 * DSP(4);
    main_w = 0.45* DSP(3);
    main_h = 0.7 * DSP(4);
    
    hdiag = figure('name','Setup Manager','Visible','off','OuterPosition',[main_l, main_b, main_w, main_h],'NumberTitle','off','MenuBar','none');
    P0 = uipanel(hdiag,'FontSize',12,'Units','normalized','Position',[ 0.0,  0.6,  1.0,  0.4 ],'title','Subsurface Constrains'); 
    P1 = uipanel(hdiag,'FontSize',12,'Units','normalized','Position',[ 0.0,  0.2,  1.0,  0.4 ],'title','Target Earthquake');
    P2 = uipanel(hdiag,'FontSize',12,'Units','normalized','Position',[ 0.0,  0.0,  1.0,  0.2],'title','Surface Waves');
      
    
    %% Setup
    baserow = 1;
    Nrow = 8;
    dw = 0.01;
    dh = 0.00;
    objh = 0.9*(1-dh)/Nrow; % object sizes
    objy = dh + ( (Nrow-1):-1:0 )*(1/Nrow);
    
    %[objx(2), objy(row), objw(2), objh]
    objw = [0.2, 0.2, 0.3, 0.2];
    gap  = 1-sum(objw)-2*dw;
    objx = dw + [0, objw(1), (sum(objw(1:2))+gap), (sum(objw(1:3))+gap)];
    %%    min Vs
    row = baserow + 1;
    uicontrol('Style','text','parent',P0,'String','Min. allowed Vs', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh], 'Enable','on');
    h_min_vs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %%    min,max Vp/Vs
    row = row + 1;
    uicontrol('Style','text','parent',P0,'String','Min. allowed Vp/Vs', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_min_vpvs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    uicontrol('Style','text','parent',P0,'String','Max. allowed Vp/Vs', ...
        'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
    h_max_vpvs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(4), objy(row), objw(4), objh]);
    %%    min,max Rho
    row = row + 1;
    uicontrol('Style','text','parent',P0,'String','Min. allowed Rho', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_min_ro = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    uicontrol('Style','text','parent',P0,'String','Max. allowed Rho', ...
        'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
    h_max_ro = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(4), objy(row), objw(4), objh]);
    %%    min,max Thickness
    row = row + 1;
    uicontrol('Style','text','parent',P0,'String','Min. allowed thickness', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_min_H = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    uicontrol('Style','text','parent',P0,'String','Max. allowed thickness', ...
        'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
    h_max_H = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(4), objy(row), objw(4), objh]);
    %%    min/max Qs
    row = row + 1;
    uicontrol('Style','text','parent',P0,'String','Min. allowed Qs', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_min_qs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    uicontrol('Style','text','parent',P0,'String','Max. allowed Qs', ...
        'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
    h_max_qs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(4), objy(row), objw(4), objh]);
    %%    min/max Qp/Qs
    row = row + 1;
    uicontrol('Style','text','parent',P0,'String','Min. allowed Qp/Qs', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_min_qpqs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    uicontrol('Style','text','parent',P0,'String','Max. allowed Qp/Qs', ...
        'Units','normalized','Position',[objx(3), objy(row), objw(3), objh]);
    h_max_qpqs = uicontrol('Style','edit','parent',P0, ...
        'Units','normalized','Position',[objx(4), objy(row), objw(4), objh]);
    %% Target HQ
    baserow = 1;
    row = baserow + 1;
    objw = [0.35, 0.2];
    objx = dw + [0, objw(1)];
    uicontrol('Style','text','parent',P1,'String','Magnitude (3.5 - 8)', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_magnitude = uicontrol('Style','edit','parent',P1, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    row = row + 1;
    uicontrol('Style','text','parent',P1,'String','Epicentral distance (Km)', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_distance = uicontrol('Style','edit','parent',P1, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    row = row + 1;
    uicontrol('Style','text','parent',P1,'String','Focal Depth (Km)', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_focal_depth = uicontrol('Style','edit','parent',P1, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    row = row + 1;
    uicontrol('Style','text','parent',P1,'String','Fraction of rock along the path (0-1)', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_rockrat = uicontrol('Style','edit','parent',P1, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %% Surface Waves
    Nrow = 4;
    dw = 0.01;
    dh = 0.00;
    objh = 0.9*(1-dh)/Nrow; % object sizes
    objy = dh + ( (Nrow-1):-1:0 )*(1/Nrow);
    
    baserow = 1;
    row = baserow;
    objw = [0.35, 0.2];
    objx = dw + [0, objw(1)];
    uicontrol('Style','text','parent',P2,'String','N. of modes', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_sw_nmodes = uicontrol('Style','edit','parent',P2, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
    %
    row = row + 1;
    uicontrol('Style','text','parent',P2,'String','Smoothing', ...
        'Units','normalized','Position',[objx(1), objy(row), objw(1), objh]);
    h_sw_nsmooth = uicontrol('Style','edit','parent',P2, ...
        'Units','normalized','Position',[objx(2), objy(row), objw(2), objh]);
        
    %% INIT manager interface ---------------------------------------------
    set(h_min_vs,     'String', num2str(  inmin_vs  ));
    set(h_min_vpvs,   'String', num2str(  inmin_vp_vs_ratio  ));
    set(h_max_vpvs,   'String', num2str(  inmax_vp_vs_ratio  ));
    set(h_min_ro,     'String', num2str(  inmin_ro  ));
    set(h_max_ro,     'String', num2str(  inmax_ro  ));
    set(h_min_H,      'String', num2str(  inmin_H  ));
    set(h_max_H,      'String', num2str(  inmax_H  ));
    set(h_min_qs,     'String', num2str(  inmin_qs  ));
    set(h_max_qs,     'String', num2str(  inmax_qs  ));
    set(h_min_qpqs,   'String', num2str(  inmin_qp_qs_ratio  ));
    set(h_max_qpqs,   'String', num2str(  inmax_qp_qs_ratio  ));
    
    set(h_magnitude,  'String', num2str(  inHQMagnitude  ));
    set(h_distance,   'String', num2str(  inHQEpicDistance  ));
    set(h_focal_depth,'String', num2str(  inHQFocalDepth  ));
    set(h_rockrat,    'String', num2str(  inHQRockRatio  ));
    
    set(h_sw_nmodes,  'String', num2str(  insw_nmodes  ));
    set(h_sw_nsmooth, 'String', num2str(  insw_nsmooth  ));
    %% --------------------------------------------------------------------

    
    %% Buttons
    uicontrol('Parent',P1,'Style','pushbutton','Units','normalized','String','Save as default', ...
        'Units','normalized','Position',[0.795, 0.7, 0.2, 0.1], ...
        'Callback',{@save_as_default});
    uicontrol('Parent',P1,'Style','pushbutton','Units','normalized','String','Reset to factory', ...
        'Units','normalized','Position',[0.795, 0.6, 0.2, 0.1], ...
        'Callback',{@reset_to_factory});
    
    uicontrol('Parent',P1,'Style','pushbutton','Units','normalized','String','Quit', ...
        'Units','normalized','Position',[0.795, 0.2, 0.2, 0.1], ...
        'Callback',{@discard_and_quit});
    
    uicontrol('Parent',P1,'Style','pushbutton','Units','normalized','String','Save and exit', ...
        'Units','normalized','Position',[0.795, 0.1, 0.2, 0.1], ...
        'Callback',{@save_and_exit});
    %% 
    set(hdiag,'Visible','on');    
    
    
    
    %% functions
    function discard_and_quit(~,~,~); close(hdiag); end% quit without changes

    function save_and_exit(~,~,~)% exit with status 
        min_vs          =  str2double( get(h_min_vs,'String') );
        min_vp_vs_ratio =  str2double( get(h_min_vpvs,'String') );
        max_vp_vs_ratio =  str2double( get(h_max_vpvs,'String') );
        min_ro          =  str2double( get(h_min_ro,'String') );
        max_ro          =  str2double( get(h_max_ro,'String') );
        
        min_H           =  str2double( get(h_min_H,'String') );
        max_H           =  str2double( get(h_max_H,'String') );
        
        min_qs          =  str2double( get(h_min_qs,'String') );
        max_qs          =  str2double( get(h_max_qs,'String') );
        min_qp_qs_ratio =  str2double( get(h_min_qpqs,'String') );
        max_qp_qs_ratio =  str2double( get(h_max_qpqs,'String') );
        %
        %
        HQMagnitude     =  str2double( get(h_magnitude,  'String') );
        HQEpicDistance  =  str2double( get(h_distance,   'String') );
        HQFocalDepth    =  str2double( get(h_focal_depth,'String') );
        HQRockRatio     =  str2double( get(h_rockrat,    'String') );
        %
        sw_nmodes       =  str2double( get(h_sw_nmodes, 'String') );
        sw_nsmooth      =  str2double( get(h_sw_nsmooth,'String') );
        
        close(hdiag)        
    end
    
    function save_as_default(~,~,~)% exit with status 
        min_vs          =  str2double( get(h_min_vs,'String') );
        min_vp_vs_ratio =  str2double( get(h_min_vpvs,'String') );
        max_vp_vs_ratio =  str2double( get(h_max_vpvs,'String') );
        min_ro          =  str2double( get(h_min_ro,'String') );
        max_ro          =  str2double( get(h_max_ro,'String') );
        
        min_H           =  str2double( get(h_min_H,'String') );
        max_H           =  str2double( get(h_max_H,'String') );
        
        min_qs          =  str2double( get(h_min_qs,'String') );
        max_qs          =  str2double( get(h_max_qs,'String') );
        min_qp_qs_ratio =  str2double( get(h_min_qpqs,'String') );
        max_qp_qs_ratio =  str2double( get(h_max_qpqs,'String') );
        %
        %
        HQMagnitude     =  str2double( get(h_magnitude,  'String') );
        HQEpicDistance  =  str2double( get(h_distance,   'String') );
        HQFocalDepth    =  str2double( get(h_focal_depth,'String') );
        HQRockRatio     =  str2double( get(h_rockrat,    'String') );
        %
        sw_nmodes       =  str2double( get(h_sw_nmodes, 'String') );
        sw_nsmooth      =  str2double( get(h_sw_nsmooth,'String') );
        
        save 'default_settings.mat' 'min_vs' 'min_vp_vs_ratio' 'max_vp_vs_ratio' 'min_ro' 'max_ro' 'min_H' 'max_H' 'min_qs' 'max_qs' 'min_qp_qs_ratio' 'max_qp_qs_ratio' 'HQMagnitude' 'HQEpicDistance' 'HQFocalDepth' 'HQRockRatio' 'sw_nmodes' 'sw_nsmooth'
    end
    function reset_to_factory(~,~,~) 
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
        
        sw_nmodes       =  str2double( get(h_sw_nmodes, 'String') );
        sw_nsmooth      =  str2double( get(h_sw_nsmooth,'String') );
        save 'default_settings.mat' 'min_vs' 'min_vp_vs_ratio' 'max_vp_vs_ratio' 'min_ro' 'max_ro' 'min_H' 'max_H' 'min_qs' 'max_qs' 'min_qp_qs_ratio' 'max_qp_qs_ratio' 'HQMagnitude' 'HQEpicDistance' 'HQFocalDepth' 'HQRockRatio' 'sw_nmodes' 'sw_nsmooth'
    
        set(h_min_vs,     'String', num2str(  min_vs  ));
        set(h_min_vpvs,   'String', num2str(  min_vp_vs_ratio  ));
        set(h_max_vpvs,   'String', num2str(  max_vp_vs_ratio  ));
        set(h_min_ro,     'String', num2str(  min_ro  ));
        set(h_max_ro,     'String', num2str(  max_ro  ));
        set(h_min_H,      'String', num2str(  min_H  ));
        set(h_max_H,      'String', num2str(  max_H  ));
        set(h_min_qs,     'String', num2str(  min_qs  ));
        set(h_max_qs,     'String', num2str(  max_qs  ));
        set(h_min_qpqs,   'String', num2str(  min_qp_qs_ratio  ));
        set(h_max_qpqs,   'String', num2str(  max_qp_qs_ratio  ));
        %
        set(h_magnitude,  'String', num2str(  HQMagnitude  ));
        set(h_distance,   'String', num2str(  HQEpicDistance  ));
        set(h_focal_depth,'String', num2str(  HQFocalDepth  ));
        set(h_rockrat,    'String', num2str(  HQRockRatio  ));
        %
        set(h_sw_nmodes,  'String', num2str(  sw_nmodes  ));
        set(h_sw_nsmooth, 'String', num2str(  sw_nsmooth  ));
    end
    waitfor(hdiag)
end

