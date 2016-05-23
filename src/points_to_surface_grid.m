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
                %p
                %ii
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
    
    % correct NaN's
    %      for i = 1:size(qz,1)
    %         for j = 1:size(qz,2)
    %           if( isnan(qz(i,j)) )
    %                 qz(i,j) = minz;
    %           end
    %         end
    %     end




%     figure
%     % mesh(sfx2,sfy2,meshed_surface2); hold on
%     mesh(sfx,sfy,meshed_surface);hold on;
%     %plot3(points2(:,1), points2(:,2), points2(:,3),'ok');
%     plot3(points(:,1),  points(:,2),  points(:,3),'or');

end