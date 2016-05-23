function [out] = as_Samuel(c,ro,h,q,ex,fref,f)%       subroutine as(dc,dro,dh,dq,dex,dfrref,dfrkv,ns,nf,amp)
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