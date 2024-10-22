function [choice,rt,fixitem,fixdur,tItem,yseq] = run_Model(z,m,n,dt,d,sig2,decbound,decay_rate,yseq_toMaxTime)
% Compute the relative decision value

exp_decay = @(x, rate) exp(-rate * x);

aGamma = 1/(m * abs(z(1) - z(2)) + n) ;
rdv = 0;
decmade = false;
for ni = 1:length(yseq_toMaxTime)
    y = yseq_toMaxTime(ni);

    % add noise to z(1)&z(2)
    sig_z = 0.025^2;
    z(1) = z(1) + randn * sqrt(sig_z);
    z(2) = z(2) + randn * sqrt(sig_z);
    rdv = rdv + d*( z(1)*(aGamma^(y-1)) - z(2)*(aGamma^(2-y)) ) + randn*sqrt(sig2);
    b = exp_decay(ni * dt, decay_rate) * decbound;

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



% if any(isnan(fixitem)), keyboard; end

end

