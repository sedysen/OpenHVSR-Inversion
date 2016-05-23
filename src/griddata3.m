function w = griddata3(x,y,z,v,xi,yi,zi,method,options)
%GRIDDATA3 Data gridding and hyper-surface fitting for 3-dimensional data.
%
%   GRIDDATA3 will be removed in a future release. Use TriScatteredInterp instead.
%
%   W = GRIDDATA3(X,Y,Z,V,XI,YI,ZI) fits a hyper-surface of the form
%   W = F(X,Y,Z) to the data in the (usually) nonuniformly-spaced vectors
%   (X,Y,Z,V).  GRIDDATA3 interpolates this hyper-surface at the points
%   specified by (XI,YI,ZI) to produce W.
%
%   (XI,YI,ZI) is usually a uniform grid (as produced by MESHGRID) and is
%   where GRIDDATA3 gets its name. 
%
%   [...] = GRIDDATA3(X,Y,Z,V,XI,YI,ZI,METHOD) where METHOD is one of
%       'linear'    - Tessellation-based linear interpolation (default)
%       'nearest'   - Nearest neighbor interpolation
%
%   defines the type of surface fit to the data. 
%   All the methods are based on a Delaunay triangulation of the data.
%   If METHOD is [], then the default 'linear' method will be used.
%
%   [...] = GRIDDATA3(X,Y,Z,V,XI,YI,ZI,METHOD,OPTIONS) specifies a cell 
%   array of strings OPTIONS that were previously used by Qhull. 
%   Qhull-specific OPTIONS are no longer required and are currently ignored.
%
%   Example:
%      x = 2*rand(5000,1)-1; y = 2*rand(5000,1)-1; z = 2*rand(5000,1)-1;
%      v = x.^2 + y.^2 + z.^2;
%      d = -0.8:0.05:0.8;
%      [xi,yi,zi] = meshgrid(d,d,d);
%      w = griddata3(x,y,z,v,xi,yi,zi);
%   Since it is difficult to visualize 4D data sets, use isosurface at 0.8:
%      p = patch(isosurface(xi,yi,zi,w,0.8));
%      isonormals(xi,yi,zi,w,p);
%      set(p,'FaceColor','blue','EdgeColor','none');
%      view(3), axis equal, axis off, camlight, lighting phong
%
%   Class support for inputs X,Y,Z,V,XI,YI,ZI: double
%
%   See also TriScatteredInterp, DelaunayTri, GRIDDATAN, DELAUNAYN, MESHGRID.

%   Copyright 1984-2009 The MathWorks, Inc.
%   $Revision: 1.11.4.11 $  $Date: 2009/09/03 05:25:18 $

if nargin < 7
  error('MATLAB:griddata3:NotEnoughInputs', 'Needs at least 7 inputs.');
end
if ( nargin == 7 || isempty(method) )
	method = 'linear';
elseif ~strncmpi(method,'l',1) && ~strncmpi(method,'n',1)
  error('MATLAB:griddata3:InvalidMethod',...
        'METHOD must be one of ''linear'', or ''nearest''.');
end
if nargin == 9
    if ~iscellstr(options)
        error('MATLAB:griddata3:OptsNotStringCell',...
              'OPTIONS should be cell array of strings.');           
    end
    opt = options;
else
    opt = [];
end

if ndims(x) > 3 || ndims(y) > 3 || ndims(z) > 3 || ndims(xi) > 3 || ndims(yi) > 3 || ndims(zi) > 3
    error('MATLAB:griddata3:HigherDimArray',...
          'X,Y,Z and XI,YI,ZI cannot be arrays of dimension greater than three.');
end

x = x(:); y=y(:); z=z(:); v = v(:);
m = length(x);
if m < 3, error('MATLAB:griddata3:NotEnoughPts','Not enough unique sample points specified.'); end
if m ~= length(y) || m ~= length(z) || m ~= length(v)
  error('MATLAB:griddata3:InputSizeMismatch',...
        'X,Y,Z,V must all have the same size.');
end

X = [x y z];

% Sort (x,y,z) so duplicate points can be averaged before passing to delaunay

[X, ind] = sortrows(X);
v = v(ind);
ind = all(diff(X)'==0);
if any(ind)
  warning('MATLAB:griddata3:DuplicateDataPoints',['Duplicate x data points ' ...
            'detected: using average of the v values.']);
  ind = [0 ind];
  ind1 = diff(ind);
  fs = find(ind1==1);
  fe = find(ind1==-1);
  if fs(end) == length(ind1) % add an extra term if the last one start at end
     fe = [fe fs(end)+1];
  end
  
  for i = 1 : length(fs)
    % averaging v values
    v(fe(i)) = mean(v(fs(i):fe(i)));
  end
  X = X(~ind(2:end),:);
  v = v(~ind(2:end));
end

if size(X,1) < 3
  error('MATLAB:griddata3:NotEnoughSamplePts',...
        'Not enough unique sample points specified.');
end

warning('MATLAB:griddata3:DeprecatedFunction',...
        'GRIDDATA3 will be removed in a future release. Use TriScatteredInterp instead.');
    
switch lower(method(1)),
  case 'l'
    w = linear(X,v,[xi(:) yi(:) zi(:)]);
  case 'n'
    w = nearest(X,v,[xi(:) yi(:) zi(:)]);
  otherwise
    error('MATLAB:griddata3:UnknownMethod', 'Unknown method.');
end
w = reshape(w,size(xi));



%------------------------------------------------------------
function vi = linear(x,v,xi)
%LINEAR Triangle-based linear interpolation

%   Reference: David F. Watson, "Contouring: A guide
%   to the analysis and display of spacial data", Pergamon, 1994.

dt = DelaunayTri(x);
scopedWarnOff = warning('off', 'MATLAB:TriRep:EmptyTri3DWarnId');
restoreWarnOff = onCleanup(@()warning(scopedWarnOff));
dtt = dt.Triangulation;
if isempty(dtt)
  error('MATLAB:griddata3:EmptyTriangulation','Error computing Delaunay triangulation. The sample datapoints may be coplanar or collinear.');
end


if(isreal(v))
    F = TriScatteredInterp(dt,v);
    vi = F(xi);
else
    vre = real(v);
    vim = imag(v);
    F = TriScatteredInterp(dt,vre);
    vire = F(xi);
    F.V = vim;
    viim = F(xi);
    vi = complex(vire,viim);
end

%------------------------------------------------------------
function vi = nearest(x,v,xi)
%NEAREST Triangle-based nearest neightbor interpolation

%   Reference: David F. Watson, "Contouring: A guide
%   to the analysis and display of spacial data", Pergamon, 1994.

dt = DelaunayTri(x);
scopedWarnOff = warning('off', 'MATLAB:TriRep:EmptyTri3DWarnId');
restoreWarnOff = onCleanup(@()warning(scopedWarnOff));
dtt = dt.Triangulation;
if isempty(dtt)
  error('MATLAB:griddata3:EmptyTriangulation','Error computing Delaunay triangulation. The sample datapoints may be coplanar or collinear.');
end
k = dt.nearestNeighbor(xi);
vi = k;
d = find(isfinite(k));
vi(d) = v(k(d));
