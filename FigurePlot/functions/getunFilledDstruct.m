function dstruct = getunFilledDstruct(dstruct_real, numsubs, z_all)
%Get filled dstruct with specified number of subjects. 
% uses input of z pair values, and samples fixation behavior randomly from
% data

% Compile data into large array to easily sample randomly for each
% simulated trial
numtrials = size(z_all,1);

% Initialize empty struct
dstruct = struct;
dstruct_sub = struct;
for ff = fieldnames(dstruct_real)'
    if iscell(dstruct_real(1).(char(ff)))
        dstruct_sub.(char(ff)) = cell(numtrials, size(dstruct_real(1).(char(ff)), 2));
    elseif isnumeric(dstruct_real(1).(char(ff)))
        dstruct_sub.(char(ff)) = nan(numtrials, size(dstruct_real(1).(char(ff)), 2));
    end
end
for s = 1:numsubs
    if s == 1
        dstruct = dstruct_sub;
    else
        dstruct(s) = dstruct_sub;
    end
end

% Fill struct
for s = 1:numsubs
    dstruct(s).trialnum = [1:numtrials]';
    dstruct(s).itemval = z_all;
    dstruct(s).choice = nan(numtrials, 1);
    for ti = 1:size(z_all,1)
        dstruct(s).trialnum(ti) = ti;
        dstruct(s).fixdur{ti} = {};
        dstruct(s).fixitem{ti} = {};
        dstruct(s).rt(ti) = [];
        dstruct(s).tItem(ti,:) = [];
    end
end

end