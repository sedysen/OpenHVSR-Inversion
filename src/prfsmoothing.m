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
function [OUT] = prfsmoothing(IN, smoothing_strategy,smoothing_radius)

    nex = size(IN,2);
    nez = size(IN,1);
    r = smoothing_radius;
    SMOOTH = 0*IN;
    switch smoothing_strategy
        case 1
            for k = 1:nez
                for i = 1:nex
                    imin = (i-r); if(imin <   1); imin =   1; end
                    imax = (i+r); if(imax > nex); imax = nex; end

                    is = imin:imax;
                    vals = IN(k,is);
                    SMOOTH(k,i) = sum( vals )/sum( vals>0 );
                end
            end
        case 2
            for k = 1:nez
                for i = 1:nex
                    imin = (i-r); if(imin <   1); imin =   1; end
                    imax = (i+r); if(imax > nex); imax = nex; end

                    kmin = (k-1); if(kmin <   1); kmin =   1; end
                    kmax = (k+1); if(kmax > nez); kmax = nez; end

                    is = imin:imax;
                    ks = kmin:kmax;
                    vals = IN(ks,is); 
                    SMOOTH(k,i) = sum( vals )/sum( vals>0 );
                end
            end            
        case 3
            for k = 1:nez
                for i = 1:nex
                    imin = (i-r); if(imin <   1); imin =   1; end
                    imax = (i+r); if(imax > nex); imax = nex; end

                    kmin = (k-r); if(kmin <   1); kmin =   1; end
                    kmax = (k+r); if(kmax > nez); kmax = nez; end

                    is = imin:imax;
                    ks = kmin:kmax;
                    vals = IN(ks,is); 
                    SMOOTH(k,i) = sum( vals )/sum( vals>0 );
                end
            end
       otherwise
            SMOOTH = IN;
    end
    OUT = SMOOTH;
end


