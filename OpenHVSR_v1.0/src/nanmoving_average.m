function Y = nanmoving_average(X,F,varargin)
% Y = NANMOVING_AVERAGE(X,F) Suaviza el vector X usando el promedio en 
%   movimiento de los 2F+1 elementos alrededor de cada elemento de X, sin 
%   considerar los elementos NaN's.
%
% Y = NANMOVING_AVERAGE(X,F,'interpNaN') Suaviza el vector X usando el 
%   promedio en movimiento de los 2F+1 elementos alrededor de cada elemento 
%   de X, incluso suaviza algunos elementos NaN's (aquellos que al menos un 
%   elemento de los 2F a su alrededor no son NaN's).
%
% Ver tambi�n MOVING_AVERAGE.M, MOVING_AVERAGE2.M, NANMOVING_AVERAGE2.M
%
% Programa creado por
% M. en C. Carlos Adri�n Vargas Aguilera
% Doctorado en Oceanograf�a F�sica
% CICESE
% M�xico, octubre 2006
%
% nubeobscura@hotmail.com

suavenans = 0;
if (nargin == 3) && strcmpi(varargin{1}(1),'i')
 suavenans = 1;
end

% Suavizado por moving average, mas no los extremos:
Y = nanQ_rectangulo(X,F);

% Suavizado de los extremos inicial y final:
ancho = 2*F+1;
N = length(X);
Yini = nancummean(X(1:ancho-2));  
Y(1:F) = Yini(1:2:end);
Yfin = nancummean(X(N:-1:N-ancho+3));
Y(N-F+1:N) = Yfin(end:-2:1);

% No suavizar los NaN's?
if ~suavenans
 Y(isnan(X)) = NaN;
end


function Y = nancummean(X)
% Calcula el promedio acumulativo sin considerar elementos NaN's del vector
% X
%
% nubeobscura@hotmail.com

Y = X;
for n = 1:length(X)
 Y(n) = nanmean( X(n:-1:1) );    % Promedio acumulativo sin NaN's
end


function Y = nanQ_rectangulo(X,F)
% Ventana rect�ngulo, de ancho: 2*F+1 aplicada a la serie de datos X, via
% promedio en movimiento 
%
% nubeobscura@hotmail.com

Y = X;
if F == 0, return, end
N = length(X);
for n = F+1:N-F
 Y(n) = nanmean( X(n-F:n+F) );   % Moving averange sin NaN's
end


% Carlos Adri�n. nubeobscura@hotmail.com