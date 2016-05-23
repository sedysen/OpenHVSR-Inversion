% Computation of empirical horizontal bedrock Fourier spectrum for the target earthquake
function [f0,s0]=FourierSpectrum(m,R,H,r)

    load trifunac_2.coeff %Report No. CE 95-03, FREQUENCY DEPENDENT ATTENUATION FUNCTION, AND FOURIER AMPLITUDE SPECTRA
    %OF STRONG EARTHQUAKE GROUND MOTION IN CALIFORNIA, Vincent W. Lee and Mihailo D. Trifunac
    %April, 1995 (Table 3.13a)
    c=trifunac_2;         % Ovdje je tablica koeficijenata
    T=c(:,1);
    b0=c(:,2);
    b1=c(:,3);
    b2=c(:,4);
    b3=c(:,5);
    b4=c(:,6);
    b5=c(:,7);
    b70=c(:,8);
    b71=c(:,9);
    per0=T;
    load trifunac_2x.coeff
    c=trifunac_2x;
    mm=c(1,2:end);
    c=trifunac_2x(2:end,2:end); %To je sada samo matrica koeficijenata za Rmax (bez prvog retka i stupca)

    %=-=-=-=-=-= ULAZNI PODACI =-=-=-=-=-=
    %m=7.5;                   % magnituda (m)
    %H=10;                    % dubina
    %R=20;                    % epicentralna udaljenost,
    beta=3.0;                % brzina S-vala
    v=0;                     % horizontalna komp. (v=0), vertikalna komp (v=1)
    %r=0.9;                   % postotak rock path
    s=2; sgl=s;              %(geological site parameters: 0 - sediments, 1 - intermediate, 2 - bedrock)
                             % s definira gdje se racuna spektar (ako se kasnije mnozi s AMP onda obicno s=2)
    %tlo=2;                   % tlo=0,1,2 odgovara mekom, srednjem i tvrdom tlu na povrsini lokacije.
                             % Ovaj parametar ce definirati trajanje akcelerograma!
    %maxT=20;                 % Maksimalni period (teorijski se ekstrapolira od Tmax (=najveci razlucivi period prema regresiji, vidi dolje) do maxT)

    if (m>=3) & (m<7.25), S=-25.34+8.51*m; end
    if m<3, S=0.2; end
    if m>=7.25, S=-25.34+8.51*7.25; end
    S0=beta*T./2;
    dlt=S.*(log((R.*R+H.*H+S.*S)./(R.*R+H.*H+S0.*S0))).^(-0.5);
    L=0.01*10.^(0.5*m);      %To je procjena duljine rasjeda

    if m>3.5
        W=0.1*10^(0.25*m);   %Sirina rasjeda
    else
        W=L;
    end

    SS=L;
    if L>30, SS=30; end  %SS ne moze biti vece od debljine kore
    S1=R;
    if H>=SS, S1=sqrt(R*R+(H-SS)^2); end

    if m>=3.5 & m<=6.5
        Tmax=interp1([3.5 6.5],[1.2 8],m); %Ovo je otprilike interpolacija za najveci razlucivi period, prema slikama u Lee& Trifunac, 1995
    end
    if m>6.5, Tmax=8.; end
    if m<3.5, Tmax=1.; end
    Fmin=1./Tmax;

    f0=1./per0;

    Rmax = interp2(mm,1./T,c,m,f0);  %Ovo su Rmax za pojedine frekvencije
    dltmax=S.*(log((Rmax.*Rmax+H.*H+S.*S)./(Rmax.*Rmax+H.*H+S0.*S0))).^(-0.5);

    % spektar za frekvencije vece od Nyquistove (fny) ili za f>25 Hz je nula
    % (sto je prije...)
    fny=25;
    for ij=1:length(f0)
        if f0(ij)<=fny
            if R<Rmax(ij)
                logfs0=m + b0(ij).*log10(dlt(ij)./L)    + b1(ij).*m + b2(ij).*s + b3(ij).*v + b4(ij) + b5(ij).*m.*m + (b70(ij).*r+b71(ij).*(1-r)).*R./100;
                s0(ij)=10.^logfs0;
            else
                logfs1=m + b0(ij).*log10(dltmax(ij)./L) + b1(ij).*m + b2(ij).*s + b3(ij).*v + b4(ij) + b5(ij).*m.*m + (b70(ij).*r+b71(ij).*(1-r)).*Rmax(ij)./100-(R-Rmax(ij))./200;
                s0(ij)=10.^logfs1;
            end
        else
            s0(ij)=0;
        end
    end

    %f=(0.05:0.01:100);
    %fs=interp1(f0,s0,f,'linear','extrap');

    %loglog(f0,s0);

end% function
