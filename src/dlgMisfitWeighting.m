% Author: Samuel Bignardi Ph.D.
% Date:   August 2, 2023
%
%
% [Output] = new values for weights: [CurveWeight,SlopeWeight]
%
function  [Output] = dlgMisfitWeighting(CurveWeight,SlopeWeight,FontSizePoints)
    %close all; clear; clc
    %CurveWeight=0.9; SlopeWeight=0.1;
    % FontSizePoints = USER_PREFERENCE_interface_objects_fontsize = 12;% size of font inpoints
 
    % Create the main figure
    DSP = get(0,'ScreenSize');% Screen size
    main_l = 0.2 * DSP(3);
    main_b = 0.2 * DSP(4);
    main_w = 0.3 * DSP(3);
    main_h = 0.1 * DSP(4);
    
    %% HANDLE FONT SIZE
    % Get the screen resolution in pixels per inch
    ScreenResolution = get(0, 'ScreenPixelsPerInch');
    % Convert points to pixels
    FontSizePixels = FontSizePoints * ScreenResolution / 72;
    RelativeUnitsFontSize = FontSizePixels/main_h;

    %% GENERATE GUI
    fig = figure('Name','Chose the weights for the Curve and the Slope terms of the Misfit function', ...
        'Visible','on','OuterPosition',[main_l, main_b, main_w, main_h],'NumberTitle','off');
    set(fig, 'MenuBar', 'none');
    set(fig, 'ToolBar', 'none');
    %fig = uifigure('Name', 'Chose the weights for the Curve and the Slope terms of the misfit function','Units','normalized','Position', [0.2, 0.2, 0.5, 0.2]);
    fig.Resize = 'on'; % Disable resizing of the GUI

    % Create UI components
    
    labelWidth = 0.8;
    ValueWidth = 1-labelWidth;
    objHeight = 1.5*RelativeUnitsFontSize;
    xpos=[0,labelWidth];
    
    HeightAvailable = 1 - 3*objHeight;
    HeightOffset    = HeightAvailable/2;
    ypos = (HeightOffset+objHeight) * [0, 1, 2];
    
    values = 100*[CurveWeight, SlopeWeight];
    uicontrol('Parent',fig,'Style','text', ...
        'Units','normalized','Position',[xpos(1), ypos(3),  labelWidth, objHeight], ...
        'String','Curve mismatch weight (%)',...
        'FontSize',FontSizePoints);
    editField0 = uicontrol('parent',fig,'Style','edit', ...
        'Units','normalized','Position',[xpos(2), ypos(3),  ValueWidth, objHeight], ...
        'FontSize',FontSizePoints, ...
        'String',values(1), ...
        'Callback',@CheckValue);
    %
    uicontrol('Parent',fig,'Style','text', ...
        'Units','normalized','Position',[xpos(1), ypos(2),  labelWidth, objHeight], ...
        'String','Slope mismatch weight (%)',...
        'FontSize',FontSizePoints);
    editField1 = uicontrol('parent',fig,'Style','edit', ...
        'Units','normalized','Position',[xpos(2), ypos(2), ValueWidth, objHeight], ...
        'FontSize',FontSizePoints, ...
        'String',values(2),'Enable','off');
    
    button = uicontrol('parent',fig,'Style','pushbutton', ...
        'Units','normalized','Position',[xpos(1), ypos(1), labelWidth, objHeight], ...
        'String','Ok', ...
        'Enable','on', ... 
        'FontSize',FontSizePoints, ...
        'Callback',@SubmitCallback);


    
%     button = uibutton(fig, 'Text', 'Submit', 'Position', [130, 60, 100, 30]);
%     button.ButtonPushedFcn = @submitCallback;
% 
    % Callback function for the button
    function SubmitCallback(src, event)
        %name = editField0.Value; % Get the entered name
        %msgbox(['Hello, ' name '!']); % Show a message box with the greeting
        Output = values/100;
        close(fig)
    end
    function CheckValue(src, event)
        val = str2double(editField0.String);
        if(val<0 || 100<val )
            msgbox('A value between 0 and 100 is required.'); % Show a message box with the greeting
            set(button,'Enable','off')
        end
        values=[val, 100-val];
        set(editField1,'String',num2str(values(2)))
        set(button,'Enable','on')
    end
    
    
    waitfor(fig)
end