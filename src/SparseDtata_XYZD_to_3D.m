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
function [XM,YM,ZM,VM xq,yq,zq] = SparseDtata_XYZD_to_3D(surface_locations,Z,D,nx,ny,cutplanes)
    
    % define the grid
    xq = linspace(min(surface_locations(:,1)), max(surface_locations(:,1)), nx);
    yq = linspace(min(surface_locations(:,2)), max(surface_locations(:,2)), ny);
    zq = linspace( min(min(Z)), max(max(Z)), size(Z,1));
    [XM,YM,ZM] = meshgrid(xq,yq,zq);

    % order the sparse data values
    N = size(D,2);
    L = size(D,1)*size(D,2);
    X = 0*D;
    Y = 0*D;
    for m = 1:N
        X(:,m) = surface_locations(m,1);
        Y(:,m) = surface_locations(m,2);
    end
    X = reshape( X, L,1);
    Y = reshape( Y, L,1);
    Z = reshape( Z, L,1);
    D = reshape( D, L,1);

    VM = griddata3( X, Y, Z, D, XM,YM,ZM, 'nearest');
    
    [sfx,sfy,meshed_surface] = correct_for_surface();
    trim_edges();
    
    
    VM = smooth3(VM,'box',5);
    
    
    
    
    % Plot volume
    smoothvolume3(XM,YM,ZM,VM, xq,yq,zq, cutplanes);
    
    
    %% SUBFUNCTIONS
    function [sfx,sfy,meshed_surface] = correct_for_surface() 
        % define meshed surface and correct
        [sfx,sfy,meshed_surface] = points_to_surface_grid(xq,yq,surface_locations);

        for j = 1:size(meshed_surface,1)
            for i = 1:size(meshed_surface,2)
                for k = 1:size(VM,3)
                    if(ZM(j,i,k) > meshed_surface(j,i))
                        %fprintf('%d %d %d\n',i,j,k)
                        VM(j,i,k) = 0;
                    end
                end
            end
        end
    end
    function trim_edges()
        for iv = 1:size(VM,2) %              grid: along x
            for jv = 1:size(VM,1) %                along y
                for is = 1:size(meshed_surface,1)
                    for js = 1:size(meshed_surface,2)
                        if( (abs(XM(jv,iv,1)-sfx(is,js))<0.001) && (abs(YM(jv,iv,1)-sfy(is,js))<0.001) )
                            if(isnan(meshed_surface(is,js)))
                            
                                fprintf('(%f %f) (%f %f)\n',  XM(jv,iv,1),YM(jv,iv,1),  sfx(is,js),sfy(is,js))
                                VM(jv,iv,:) = 0;
                            end
                        end
                    end
                end
                
            end
        end
    end
end % function
