function allstats = makeBehavStat(bout,plotOptions)
%Make plots for behavioral data similar to Krajbich et al., 2010

allstats = struct;  % return statistical tests done
subCount = length(bout.rt);

        
% Proportion chosen item 1 vs. value difference
toplot = bout.item1chosen_valdiff_all;
usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;  % Remove columns where there are NaNs more than half of all data

% Stats
b_all = nan(subCount,1); x = bout.valdiff(usebin_i);
for s = 1:subCount
b = regress(toplot(s,usebin_i)',[ones(length(x),1),x']);
b_all(s) = b(2);
end
allstats.prop1_valDiff = ttest_full(b_all);

% RT vs. absolute value difference
toplot = bout.rt_valdiff_abs;
usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;

% Stats
b_all = nan(subCount,1); x = bout.rt_valdiff_abs(usebin_i);
for s = 1:subCount
    b = regress(toplot(s,usebin_i)',[ones(length(x),1),x']);
    b_all(s) = b(2);
end
allstats.rt_absValDiff = ttest_full(b_all);


% Switch count vs absolute value difference

toplot = bout.switchcount_valdiff_abs;
usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    
% Stats
b_all = nan(subCount,1); x = bout.switchcount_valdiff_abs(usebin_i);
for s = 1:subCount
    b = regress(toplot(s,usebin_i)',[ones(length(x),1),x']);
    b_all(s) = b(2);
end
allstats.SwitchCount_absValDiff = ttest_full(b_all);




end
