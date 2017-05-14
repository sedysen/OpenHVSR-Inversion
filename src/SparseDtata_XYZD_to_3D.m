function [XM,YM,ZM,VM xq,yq,zq] = SparseDtata_XYZD_to_3D(surface_locations,Z,D,nx,ny,cutplanes)
    %{XM,YM,ZM,VM xq,yq,zq] = SparseDtata_XYZD_to_3D(surface_locations,Z,D,dx,dy,dz, surface, handle)

   % Z = model levels + elevation: 

    %% define the grid
    terrain_dz = max(surface_locations(:,3))-min(surface_locations(:,3));
    
    xq = linspace(min(surface_locations(:,1)), max(surface_locations(:,1)), nx);
    yq = linspace(min(surface_locations(:,2)), max(surface_locations(:,2)), ny);
    [sfx,sfy,meshed_surface] = terrain();
    %min_dz_terrain
    delta = abs(meshed_surface - min(min(meshed_surface)));
    midz = max(max(delta));
    for ii = 1:size(delta,1)
        for jj = 1:size(delta,2)
            if delta(ii,jj)<midz  && delta(ii,jj)>0  
                midz = delta(ii,jj);
            end
        end
    end
    
    %zq_old = linspace( min(min(Z)), max(max(Z)), size(Z,1));
    zq = linspace( min(min(Z)), max(max(Z)), size(Z,1));
    if 1.5*midz<terrain_dz
        nz_terrain = 2*fix(terrain_dz/midz);
        zq_terrain = linspace( min(surface_locations(:,3)), max(surface_locations(:,3)), nz_terrain);
        zq_subsrf = linspace( min(min(Z)), min(surface_locations(:,3)), size(Z,1));
        zq = [ zq_subsrf(1:(end-1)), zq_terrain];
    end
   
    [XM,YM,ZM] = meshgrid(xq,yq,zq);

    %% order the sparse data values
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
    VM = smooth3(VM,'box',5);
    correct_for_surface(meshed_surface);
    trim_edges();
    %VM = trim_edges();
    
    
    
    
    %X(ym:yp, xm:xp, zm:zp);

    %% Plot volume
    smoothvolume3(XM,YM,ZM,VM, xq,yq,zq, cutplanes);
    % delete higher than meshed_surface 
    hold on;
    mesh(sfx,sfy,meshed_surface,'FaceColor','none');
    
%     for k = 1:size(VM,3)
%         if(VM(1,1,k)~=0)
%             %fprintf('%d %d %d\n',i,j,k)
%             plot3( XM(1,1,k),YM(1,1,k), ZM(1,1,k), '.k'); 
%         end
%     end
    
    %hold on;
    plot3(surface_locations(:,1), surface_locations(:,2), surface_locations(:,3),'or');
    xlim([min(surface_locations(:,1)), max(surface_locations(:,1))]); hold on
    ylim([min(surface_locations(:,2)), max(surface_locations(:,2))]); hold off
    %zlim([min(surface_locations(:,3)), max(surface_locations(:,3))]); hold on
    hold off
    fprintf('done')
   
    
    %% SUBFUNCTIONS
    function [sfx,sfy,meshed_surface] = terrain() 
        [sfx,sfy,meshed_surface] = points_to_surface_grid(xq,yq,surface_locations);
    end
    function correct_for_surface(meshed_surface) 
        % define meshed surface and correct
       %dzmez=0.5*abs(ZM(1,1,1)-ZM(1,1,2))
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
