function [XM,YM,ZM,VM xq,yq,zq] = SparseDtata_XYZD_to_3D(surface_locations,Z,D,nx,ny,cutplanes)
    %{XM,YM,ZM,VM xq,yq,zq] = SparseDtata_XYZD_to_3D(surface_locations,Z,D,dx,dy,dz, surface, handle)

   

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
    %VM = trim_edges();
    
    VM = smooth3(VM,'box',5);
    
    
    %X(ym:yp, xm:xp, zm:zp);

    % Plot volume
    smoothvolume3(XM,YM,ZM,VM, xq,yq,zq, cutplanes);
    % delete higher than meshed_surface 
    %hold on;
    %mesh(sfx,sfy,meshed_surface);
    %hold on;
    %plot3(surface_locations(:,1), surface_locations(:,2), surface_locations(:,3),'or');
    
    fprintf('done')
   
    
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
                %fprintf('%d %d\n',iv,jv)
                for is = 1:size(meshed_surface,1)
                    for js = 1:size(meshed_surface,2)
                         %fprintf('%d %d\n',is,js)
                        
                        
                        if( (abs(XM(jv,iv,1)-sfx(is,js))<0.001) && (abs(YM(jv,iv,1)-sfy(is,js))<0.001) )
                            if(isnan(meshed_surface(is,js)))
                            
                                fprintf('(%f %f) (%f %f)\n',  XM(jv,iv,1),YM(jv,iv,1),  sfx(is,js),sfy(is,js))
                                % tVM(jv,iv,:) = VM(jv,iv,:);
                                VM(jv,iv,:) = 0;
                            end
                        %else
                        %    continue;
                        end
                        %pause; clc
                    end
                end
                
            end
        end
    end
%%


% X = X(ym:yp, xm:xp, zm:zp);









%
end % function
