%%     Panels definition (sizes)
%      Pnl            >> Panel
%      Lay?           >> Layout ?
%      A,B,C,D ...    different panels
%      .P?  panel kind
%%         layout 0:
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
Pnl.Lay0.A = [0.00  0.00,  0.25 1.00];%[0.00 0.00,  0.325 1.00];% Panel_Layout_0__pos_panel_A 
Pnl.Lay0.B = [0.25  0.00,  0.75 1.00];%[0.325 0,  (1-0.325) 1];%  Panel_Layout_0__pos_panel_B
%%         layout 1:
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][BBB][BBB]
%   [AA][CCC][CCC]
Pnl.Lay1.A = [0.00  0.00,  0.25 1.00];%[0.00 0.00,  0.325 1.00]; Panel_Layout_1__pos_panel_A
Pnl.Lay1.B = [0.25  0.20,  0.75 0.80];%[0.325 0,  (1-0.325) 1]; Panel_Layout_1__pos_panel_B
Pnl.Lay1.C = [0.25  0.00,  0.75 0.20];%[0.325 0,  (1-0.325) 1]; Panel_Layout_1__pos_panel_C
%%         layout 2:
%   [BB][CCC][CCC]
%   [BB][CCC][CCC]
%   [AA][CCC][CCC]
%   [AA][DDD][DDD]
Pnl.Lay2.A = [0.00   0.00   0.25  0.50];%[0 0.0 0.325, 0.5]; Panel_Layout_2__pos_panel_A
Pnl.Lay2.B = [0.00   0.50   0.25  0.50];%[0 0.5 0.325, 0.5]; Panel_Layout_2__pos_panel_B
Pnl.Lay2.C = [0.25   0.20   0.75, 0.80];%[0.325 0.2    0.675, 0.8];%[0.4 0    0.3, 1]; Panel_Layout_2__pos_panel_C
Pnl.Lay2.D = [0.25   0.00   0.75, 0.20];%[0.325  0    0.675, 0.2]; Panel_Layout_2__pos_panel_D
%%         layout 3:
%   [BB][CCC][DDD]
%   [BB][CCC][DDD]
%   [AA][CCC][EEE]
%   [AA][CCC][EEE]
Pnl.Lay3.A = [0.00    0.00   0.25   0.50];
Pnl.Lay3.B = [0.00    0.50   0.25   0.50];
Pnl.Lay3.C = [0.25    0.00   0.375, 1.00];
Pnl.Lay3.D = [0.625   0.50   0.375, 0.50];
Pnl.Lay3.E = [0.625   0.00   0.375, 0.50];
%%         layout 4:
%   [CC][CCC]
%   [BB][CCC]
%   [AA][CCC]
Pnl.Lay4.A = [0.00    0.00   0.25   0.34];
Pnl.Lay4.B = [0.00    0.34   0.25   0.33];
Pnl.Lay4.C = [0.00    0.67   0.25   0.33];
Pnl.Lay4.D = [0.25    0.00   0.75,  1.00];
%
%
%
%%