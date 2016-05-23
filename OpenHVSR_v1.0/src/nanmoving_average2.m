function Y = nanmoving_average2(X,varargin)
% Y = NANMOVING_AVERAGE2(X) Suaviza la matriz X usando el promedio en 
%   movimiento de la pequeña matriz de 3x3 elementos alrededor de cada 
%   elemento de X, sin considerar los elementos NaN's.
%
% Y = NANMOVING_AVERAGE2(X,m) Suaviza la matriz X usando el promedio en 
%   movimiento de la pequeña matriz de (2*m+1)x(2*m+1) elementos alrededor 
%   de cada elemento de X, sin considerar los elementos NaN's.
%
% Y = NANMOVING_AVERAGE2(X,m,n) Suaviza la matriz X usando el promedio en 
%   movimiento de la pequeña matriz de (2*m+1)x(2*n+1) elementos alrededor 
%   de cada elemento de X, sin considerar los elementos NaN's. (Default 
%   m=n=1). 
%
% Y = NANMOVING_AVERAGE2(X,...,'interpNaN') Suaviza la matriz X e inluso
%   algunos elementos NaN's (aquellos que al menos uno de los 2(2mn+m+n)
%   elementos a su alrededor no es NaN).
%
% NOTA: [(2*m+1),(2*n+1)] < size(X).
%
% EJEMPLO:
%  [X,Y] = meshgrid(-2:.2:2,3:-.2:-2);
%  Zi = 5*X.*exp(-X.^2-Y.^2);
%  Zr = Zi + rand(size(Zi)); Zr([8 46 398 400]) = NaN;
%  Zs = nanmoving_average2(Zr,2,3);
%  subplot(131), surf(X,Y,Zi), view(2), shading interp, xlabel('Real')
%  subplot(132), surf(X,Y,Zr), view(2), shading interp, xlabel('Real + ruido')
%  subplot(133), surf(X,Y,Zs), view(2), shading interp, xlabel('Suavización')
%
% Utiliza MOVING_AVERAGE.M, NANMOVING_AVERAGE.M
%
% Ver también MOVING_AVERAGE2.M
%
% Programa creado por
% M. en C. Carlos Adrián Vargas Aguilera
% Doctorado en Oceanografía Física
% CICESE 
% México, octubre 2006
%
% nubeobscura@hotmail.com

% ¿Es matriz?:
if ndims(X) ~= 2
 disp('ERROR: the entry is not a matrix!')
 return
end
[M,N] = size(X);
Y = zeros(M,N);
suavenans = 0;

% Checa los argumentos:
[m,n,suavenans] = checa_arg(varargin,nargin,suavenans);

% Matriz de unos, excepto ceros donde hay NaN's en X:
A = double(~isnan(X));

% 1. Sumas por columnas:
for j = 1:N
 Y(:,j) = nanmoving_average(X(:,j),n,'interpNaN');
 B(:,j) = moving_average(A(:,j),n); % # de elementos
end
Y = Y.*B;   % Solo sumas, no promedios.

% 2. Suavizado por las filas sumadas:
for i = 1:M
 Y(i,:) = nanmoving_average(Y(i,:),m,'interpNaN');
 B(i,:) = moving_average(B(i,:),m);
 C(i,:) = moving_average(A(i,:),m);
end
Y = Y.*C;          % Solo sumas, no promedios.
B(find(B==0)) = 1; % NaN's sigue siendo NaN
Y = Y./B;          % Promedios

% No suavizar los NaN's?
if ~suavenans
 Y(isnan(X)) = NaN;
end


function [m,n,suavenans] = checa_arg(entradas,Nentr,suavenans);
% Checa los argumentos

if Nentr == 1
 m = 1; n = m; return
end

m = -1; n = -1;
for i = 1:Nentr-1
 if ischar(entradas{i}) & strcmpi(entradas{i}(1),'i')
  suavenans = 1;
 elseif m<0
  m = entradas{i}; 
 elseif n<0
  n = entradas{i};
 end
end
if m<0, m = 1; end
if n<0, n = m; end


% Carlos Adrián. nubeobscura@hotmail.com