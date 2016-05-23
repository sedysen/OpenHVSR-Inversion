function Y = moving_average(X,F)
% Y = MOVING_AVERAGE(X,F) Suaviza r�pidamente el vector X usando el 
%   promedio en movimiento de los 2F+1 elementos alrededor de cada elemento 
%   de X.
%
% Ver tambi�n MOVING_AVERAGE2.M, NANMOVING_AVERAGE.M, NANMOVING_AVERAGE2.M
%
% Programa creado por
% Lic. en F�sica Carlos Adri�n Vargas Aguilera
% Maestr�a en Hidrometeorolog�a
% Universidad de Guadalajara
% M�xico, marzo 2006
%
% nubeobscura@hotmail.com

% Suavizado por moving average, mas no los extremos:
Y = Q_rectangulo(X,F);

% Suavizado de los extremos:
ancho = 2*F+1;
N = length(X);
% Extremo inicial:          
Yini = cumsum(X(1:ancho-2));     
Yini = Yini(:).';
Yini = Yini(1:2:end)./(1:2:ancho-2);            
Y(1:F) = Yini;
% Extremo final:
Yfin = cumsum(X(N:-1:N-ancho+3));
Yfin = Yfin(:).';
Yfin = Yfin(end:-2:1)./(ancho-2:-2:1);
Y(N-F+1:N) = Yfin;


function Y = Q_rectangulo(X,F)
% Ventana rect�ngulo, de ancho: 2*F+1 aplicada a la serie de datos X, via
% promedio en movimiento recursivo (muy r�pido)
%
% nubeobscura@hotmail.com


if F == 0
 Y = X;
 return
end

N = length(X);
ancho = 2*F + 1;             % ancho del filtro
Y = zeros(size(X));          % limpia la variable
Y(F+1) = sum(X(1:ancho));    % inicio de la recursi�n
for n = F+2:N-F
 Y(n) = Y(n-1) + X(n+F) - X(n-F-1);   % moving average recursivo
end
Y = Y/ancho;


% Carlos Adri�n. nubeobscura@hotmail.com