function [choice,rt,fixitem,fixdur,tItem,yseq] = run_aDDM(z,dt,d,sig2,aGamma,yseq_toMaxTime)
%Compute the relative decision value
% Inputs:
% yseq = sequence of fixations (1,2) to the dec time limit. This will be
% trimmed in the output based on the response time
% Formulas:
% Viewing right: V_t = V_{t-1} + d*(r_left - θ*r_right) + e_t
% Viewing left: V_t = V_{t-1} + d*(-θ*r_left + r_right) + e_t
% e_t = N(0,σ^2)
% d = k*dt
% σ^2 = sig2*dt


rdv = 0;
decmade = false;
decbound =1;

for ni = 1:length(yseq_toMaxTime)
    y = yseq_toMaxTime(ni);

    % add noise to z(1)&z(2)
    sig_z = 0.025^2;
    z(1) = z(1) + randn * sqrt(sig_z);
    z(2) = z(2) + randn * sqrt(sig_z);

    rdv = rdv + d*( z(1)*(aGamma^(y-1)) - z(2)*(aGamma^(2-y)) ) + randn*sqrt(sig2);

    if abs(rdv) >= decbound

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

