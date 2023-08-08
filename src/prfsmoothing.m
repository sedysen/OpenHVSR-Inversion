function [OUT] = prfsmoothing(IN, smoothing_strategy,smoothing_radius)
    % Author: Samuel Bignardi Ph.D.
    

    %% Smoothing ===========================================================
    nex = size(IN,2);
    nez = size(IN,1);
    r = smoothing_radius;
    SMOOTHMX = 0*IN;
    switch smoothing_strategy
        case 1
            %fprintf('Smoothing -1- layerwise\n');
            for k = 1:nez
                for i = 1:nex
                    imin = (i-r); if(imin <   1); imin =   1; end
                    imax = (i+r); if(imax > nex); imax = nex; end

                    is = imin:imax;
                    vals = IN(k,is);
                    SMOOTHMX(k,i) = sum( vals )/sum( vals>0 );
                end
            end
        case 2
            %fprintf('Smoothing -2- broad layer\n');
            for k = 1:nez
                for i = 1:nex
                    imin = (i-r); if(imin <   1); imin =   1; end
                    imax = (i+r); if(imax > nex); imax = nex; end

                    kmin = (k-1); if(kmin <   1); kmin =   1; end
                    kmax = (k+1); if(kmax > nez); kmax = nez; end

                    is = imin:imax;
                    ks = kmin:kmax;
                    vals = IN(ks,is); 
                    SMOOTHMX(k,i) = sum( vals )/sum( vals>0 );
                end
            end            
        case 3
            %fprintf('Smoothing -3- bubble\n');
            for k = 1:nez
                for i = 1:nex
                    imin = (i-r); if(imin <   1); imin =   1; end
                    imax = (i+r); if(imax > nex); imax = nex; end

                    kmin = (k-r); if(kmin <   1); kmin =   1; end
                    kmax = (k+r); if(kmax > nez); kmax = nez; end

                    is = imin:imax;
                    ks = kmin:kmax;
                    vals = IN(ks,is); 
                    SMOOTHMX(k,i) = sum( vals )/sum( vals>0 );
                end
            end
       otherwise
            SMOOTHMX = IN;
            %fprintf('Smoothing -0- NOT PERFORMED\n');
    end
    OUT = SMOOTHMX;
    %fname = strcat(colorkind,'_dir',dir,'_shot',sh,'.mat');
    %save(fname);
end


