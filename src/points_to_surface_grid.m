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
function [sfx,sfy,meshed_surface] = points_to_surface_grid(xx,yy,points)%,minz)
    [sfx,sfy] = meshgrid(xx,yy);

     % 4 more points to extend surface
    mn = min(points);
    mx = max(points);
    dlta = abs(mx-mn)/10;
    
    extrap = [ ...
            [ (mn(1)-dlta(1)) (mn(2)-dlta(2)) 0]; ...
            [ (mn(1)-dlta(1)) (mx(2)+dlta(2)) 0]; ...
            [ (mx(1)+dlta(1)) (mn(2)-dlta(2)) 0]; ...
            [ (mx(1)+dlta(1)) (mx(2)+dlta(2)) 0]; ...
            ];
    for p = 1:4
        dists = sqrt((points(:,1)-extrap(p,1)).^2 + (points(:,2)-extrap(p,2)).^2);
        for ii = 1:size(points,1)
            if dists(ii) == min(dists);
                extrap(p,3) = points(ii,3);
                break;
            end
        end
    end
    points2 = [extrap; points];

    
    newxx = linspace( min(points2(:,1)), max(points2(:,1)), 2*length(xx));
    newyy = linspace( min(points2(:,2)), max(points2(:,2)), 2*length(yy));
    
    F = TriScatteredInterp(points2(:,1), points2(:,2), points2(:,3),'linear');%'natural');
    
    [sfx2,sfy2] = meshgrid(newxx,newyy);
    meshed_surface2 = F(sfx2,sfy2);
    meshed_surface = interp2(sfx2,sfy2,meshed_surface2, sfx,sfy, 'linear');
end