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
%% ------------------------------
% This function computes the amplification factors of a layered subsurface
% It is a porting to Matlab of 
function [out] = as_Samuel(c,ro,h,q,ex,fref,f)
    %     dc       = vv;
    %     dro      = ro;
    %     dh       = h;
    %     dq       = qq;
    %     dex      = ex;
    %     dfrref   = fref;
    %     dfrkv    = f;
    % ---
    ns = length(c);
    nf = length(f);

    frref = fref;
    frkv  = f;
    qf = zeros(ns,nf);
    for j=1:ns
        for i=1:nf
            qf(j,i)=q(j)*frkv(i)^ex;
        end
    end
    idisp=0;
    if(frref > 0) idisp=1; end

    for I =1:(ns-1)
        TR(I)=h(I)/c(I);
        AR(I)=ro(I)*c(I)/ro(I+1)/c(I+1);
    end

    NSL=ns-1;
    TOTT=0;

    for I=1:NSL
        TOTT=TOTT+TR(I);
    end

    X(1) = 1;
    Z(1) = 1;
    II = 1i;

    korak = 1;
    if(idisp == 0)
        FJM1 = 1;
        FJ   = 1;
    end


    for J=1:NSL
        for ii=1:nf
            FAC(J,ii) = 2 / (1+sqrt(1+qf(J,ii)^(-2)))*(1-1i/qf(J,ii));
            FAC(J,ii)  = sqrt(FAC(J,ii));
        end
    end


    FAC(NSL+1,1:nf) = 1;
    qf(NSL+1,1:nf)=999999;

    jpi = 1/3.14159;

    for k = 1:korak:nf
        ALGF = log(frkv(k)/frref);

        for J= 2:(NSL+1)
            if(idisp ~= 0)
                FJM1 = 1 + jpi/qf(J-1,k)*ALGF;
                FJ  = 1 + jpi/qf(J,k)  *ALGF;
            end
            T(J-1) = TR(J-1)*FAC(J-1,k)/FJM1;
            A(J-1) = AR(J-1)*FAC(J,k)/FAC(J-1,k)*FJM1/FJ;
            FI(J-1)= 6.283186*frkv(k)*T(J-1);
            ARG = 1i *FI(J-1);

            CFI1 = exp( ARG);
            CFI2 = exp(-ARG);

            Z(J) = (1+A(J-1))*CFI1*Z(J-1)+(1-A(J-1))*CFI2*X(J-1);
            Z(J)=Z(J)*0.5;

            X(J)=(1.-A(J-1))*CFI1*Z(J-1)+(1.+A(J-1))*CFI2*X(J-1);
            X(J)=X(J)*0.5;
        end


        AMP(k) = 1/abs(Z(NSL+1));
    end

    out = AMP;
end % end function

    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
%