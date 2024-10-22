function [boundlist,RDVlist,choice,rt,fixitem,fixdur,tItem,yseq] = plot_rdv(z,aGamma,dt,d,sig2,yseq_toMaxTime)

exp_decay = @(x, rate) exp(-rate * x);

th = 1.5; 
decay_rate = 0.25; 

rdv = 0;
decmade = false;
RDVlist = [];
boundlist = [];
for ni = 1:length(yseq_toMaxTime)
    y = yseq_toMaxTime(ni);   
    sig_z = 0.01^2;
    z(1) = z(1) + randn * sqrt(sig_z);
    z(2) = z(2) + randn * sqrt(sig_z);
    rdv = rdv + d*( z(1)*(aGamma^(y-1)) - z(2)*(aGamma^(2-y)) ) + randn*sqrt(sig2);
    b = exp_decay(ni * dt, decay_rate) * th;

    
    RDVlist = [RDVlist, rdv];
    boundlist = [boundlist,b];

    % if abs(rdv) >= decbound
    if abs(rdv) >= b  
        decmade = true;
        break;
    end
end
yseq = yseq_toMaxTime(1:ni);

% get behavior
if decmade, choice = double(rdv<0) + 1;
else, choice = nan;
end
rt = ni*dt;
fixitem = yseq([1,diff(yseq)]~=0);
fixdur = diff([find([1,diff(yseq)]~=0),ni+1])*dt;
tItem = [sum(fixdur(fixitem==1)),sum(fixdur(fixitem==2))];
RDVlist = RDVlist;
boundlist = boundlist;

if any(isnan(fixitem)), keyboard; end


end
