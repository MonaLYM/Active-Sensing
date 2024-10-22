clear;

rootdir = 'C:/Users/A/Documents/MATLAB/driving_model/ActiveSensing';
addpath(genpath(rootdir));
data_dir = fullfile(rootdir,'data');
set(0,'defaultAxesFontSize',10);

% Plotting options
plotOptions = struct;
plotOptions.saveFigures = 0;

% Set model parameters
%the adopted parameters for origin are d=0.002, σ=0.02, and θ=0.3
dt = 0.01;
Zmax = 3; 
whichExperiment = 1;

if whichExperiment == 0  % lane-changing
    % the adopted parameters
    d = 0.003;
    sig2 = 0.03;
    decbound = 2.8; 
    decay_rate = 0.35; 
    m = 0.18; n = 1.25;

    sig2_Model = sig2^2;
    maxdectime = 10;

    % Load behavioral data
    load(fullfile(data_dir,sprintf('datastruct_lanechange05206.mat')));
    % Plot options
    plotOptions.Experiment = 0;

elseif whichExperiment == 1  % car-following 
    % the adopted parameters for car-following
    d = 0.0008;  sig2 = 0.01; decay_rate = 0.15; decbound = 1.5;
    m = 0.1; n = 1.9;
    sig2_Model = sig2^2;
    maxdectime = 18;
 
    % Load behavioral data
    load(fullfile(data_dir,sprintf('datastruct_highway40.mat')));
    % Plot options
    plotOptions.Experiment = 1;  

end

%% Behavioral plots for human behavior & aDDM simulations

% Generate behavior using model
numsubs = length(dstruct_real);

% Get empty datastruct for models
if whichExperiment == 0
    z_reps = 30;  % Number of iteration
    z_all = repmat(permn(1:3,2),z_reps,1); %Generate all possible binary groups from 1 to 3
    dstruct = getFilledDstruct(dstruct_real,numsubs,z_all);
elseif whichExperiment == 1
    iter = 20;  % To increase trials, repeat the human trials X times
    dstruct = getEmptyDstruct_realData(dstruct_real,iter);
end

% Simulate behavior
for s = 1:numsubs
    % Get empirical distribution of fixation behavior for each difficulty level
    fixdist = getEmpiricalFixationDist(dstruct_real);
    numtrials = length(dstruct(s).trialnum);
    for ti = 1:numtrials
        thisvaldiff = abs(dstruct(s).itemval(ti,1)-dstruct(s).itemval(ti,2));
        % thisvaldiff = dstruct(s).itemval(ti,1)-dstruct(s).itemval(ti,2);
        fixdist_first = fixdist.all_first{fixdist.valdiff==round(thisvaldiff)};
                  
        if whichExperiment == 1 
            random_factor = 0.8 + rand; % fix modification factor
            fixdist_mid = fixdist.all_mid{fixdist.valdiff==round(thisvaldiff)}*random_factor;
            y = 2;
        elseif whichExperiment == 0
            random_factor = 1;
            fixdist_mid = fixdist.all_mid{fixdist.valdiff==round(thisvaldiff)}*random_factor;
            y = 2; %first fix front
            
        end
        % sequence of fixations            
        yseq_toMaxTime = nan(1,ceil(maxdectime/dt));
        ni = 1;
        while sum(~isnan(yseq_toMaxTime)) < maxdectime/dt
            if ni==1, itemfixdur = fixdist_first(randperm(length(fixdist_first),1));
            else
                itemfixdur = fixdist_mid(randperm(length(fixdist_mid),1));
            end
            itemfixN = round(itemfixdur/dt);
            yseq_toMaxTime(ni:ni+itemfixN-1) = y;
            ni = ni+itemfixN;
            y = 3-y;
        end
        yseq_toMaxTime = yseq_toMaxTime(1:maxdectime/dt);

        % generate simulated data
        [dstruct(s).choice(ti),dstruct(s).rt(ti),dstruct(s).fixitem{ti},dstruct(s).fixdur{ti},dstruct(s).tItem(ti,:),~] =  ...
                run_Model(dstruct(s).itemval(ti,:),m,n,dt,d,sig2_Model,decbound,decay_rate,yseq_toMaxTime);          
    end
end
        


%% plot switching probability
allDstructs = {dstruct_real,dstruct};% Combine all datastructs to plot them efficiently
titles_dstruct = {'Data','DEAM'};
colors_dstruct = {[0.00,0.45,0.74],[0.72,0.27,1.00]};
marksize = 10;
% Initialize variables
excludeLastFix = 1;   % exclude last fixation duration, since it's cut short by choosing
useBinnedX = 1;   % Create time bins for switch prob data for smoother results
useBonferroni = 0;  
% Load params

if whichExperiment == 0 
    params.dt = 0.06;
    RTcutoff = 6;  % Cutoff of RT for trials
elseif whichExperiment == 1 
    params.dt = 0.05;
    RTcutoff = 10;  % Cutoff of RT for trials
end

switchBinaryMat = struct;  % binary matrix with 1's at time point when switch ocurred
switchBinaryMat.all = zeros(numsubs,RTcutoff/params.dt,length(allDstructs));
switchBinaryMat.valdiff_low = zeros(numsubs,RTcutoff/params.dt,length(allDstructs));
switchBinaryMat.valdiff_hi = zeros(numsubs,RTcutoff/params.dt,length(allDstructs));
switchBinaryMat.logreg = zeros(numsubs,RTcutoff/params.dt,length(allDstructs));
% Fixation duration - store the fixation duration, stored at fixation onset
% time
fixdurMat = zeros(numsubs,RTcutoff/params.dt,length(allDstructs));
fixdur_all = {};  % Accumulate all middle fixation durations
% Switch number (normalized) for valdiff 
switchnum_valdiff = {}; 
% Switch rate (#switches/rt) for valdiff 
switchrate_valdiff = {}; 
% x-axis
xaxis_orig = 0:params.dt:RTcutoff-params.dt;

% Get switch probability and fixation duration across time
for d = 1:length(allDstructs) 
    dstruct = allDstructs{d};
    fixdur_all{d} = [];
    % Switch proportion for value diff & value sum
    itemval_all = [];
    for s = 1:length(dstruct)
        itemval_all = cat(1,itemval_all,dstruct(s).itemval);
    end
    valdiff_unique = unique(abs(itemval_all(:,1)-itemval_all(:,2)))';
    switchnum_valdiff_d = nan(length(dstruct),length(valdiff_unique));
    switchrate_valdiff_d = nan(length(dstruct),length(valdiff_unique));
    for s = 1:length(dstruct)
        % All trials
        numtrials = length(dstruct(s).fixdur);
        switchBinaryMat_sub = zeros(numtrials,RTcutoff/params.dt);
        fixdurMat_sub = nan(numtrials,RTcutoff/params.dt);
        for t = 1:length(dstruct(s).fixdur)
            fixdur_trial = dstruct(s).fixdur{t};
            % Switch probability
            switchTimeIndex = round(round(cumsum(fixdur_trial),2)/params.dt) + 1;  % +1 to include RT of 0
            switchTimeIndex(switchTimeIndex>RTcutoff/params.dt) = [];  % remove any time points greater than maxdectime
            if excludeLastFix == 1 && ~isempty(switchTimeIndex)
                switchTimeIndex(end) = [];
                fixdur_trial(end) = [];
            end
            if ~isempty(switchTimeIndex)
                switchBinaryMat_sub(t,switchTimeIndex) = 1;
            end
            
            % Fixation duration
            fixonsetTimeIndex = [1,switchTimeIndex(1:end-1)];
            if length(fixonsetTimeIndex) > 1
                fixdur_this = fixdur_trial(1:length(switchTimeIndex));
                fixdur_this(1) = [];  % remove first fixation, just look at middle fixations
                fixonsetTimeIndex(1) = [];
                fixdurMat_sub(t,fixonsetTimeIndex) = fixdur_this;
            end
        end
        switchBinaryMat.all(s,:,d) = mean(switchBinaryMat_sub,1);
        % Split trials by upper third and lower third in terms of valdiff
        valdiff_abs = abs(dstruct(s).itemval(:,1)-dstruct(s).itemval(:,2));
        valdiff = dstruct(s).itemval(:,1)-dstruct(s).itemval(:,2);
        if whichExperiment == 0 
            i_lower = valdiff_abs == 0;
            i_middle = valdiff_abs == 1;
            i_upper = valdiff_abs == 2;
            switchBinaryMat.valdiff_low(s,:,d) = mean(switchBinaryMat_sub(i_lower,:),1);
            switchBinaryMat.valdiff_mid(s,:,d) = mean(switchBinaryMat_sub(i_middle,:),1);
            switchBinaryMat.valdiff_hi(s,:,d) = mean(switchBinaryMat_sub(i_upper,:),1);

        elseif whichExperiment == 1
            i_lower = valdiff_abs == 0;
            i_upper = valdiff_abs == 1;
            switchBinaryMat.valdiff_low(s,:,d) = mean(switchBinaryMat_sub(i_lower,:),1);
            switchBinaryMat.valdiff_hi(s,:,d) = mean(switchBinaryMat_sub(i_upper,:),1);

            i_1st = valdiff == -1;
            i_2nd = valdiff == 0;
            i_3rd = valdiff == 1;
            switchBinaryMat.valdiff_1st(s,:,d) = mean(switchBinaryMat_sub(i_1st,:),1);
            switchBinaryMat.valdiff_2nd(s,:,d) = mean(switchBinaryMat_sub(i_2nd,:),1);
            switchBinaryMat.valdiff_3rd(s,:,d) = mean(switchBinaryMat_sub(i_3rd,:),1);
        end

        % Fixation duration
        fixdurMat(s,:,d) = nanmean(fixdurMat_sub,1);
        fixdur_all{d} = cat(1,fixdur_all{d},fixdurMat_sub(~isnan(fixdurMat_sub)));
        
        % 2. Switch proportion vs valdiff
        % Switch rate: #switches / RT
        switchnum = cellfun('length',dstruct(s).fixdur) - 1;
        valdiff_sub = abs(dstruct(s).itemval(:,1)-dstruct(s).itemval(:,2));
        for vd = valdiff_unique
            i_vd = valdiff_sub==vd;
            switchnum_valdiff_d(s,vd == valdiff_unique) = nanmean(switchnum(i_vd)) / mean(switchnum);  % Normalize by mean number of all switches for subject
            rt_without_lastfix = dstruct(s).rt(i_vd) - cellfun(@(v) v(end), dstruct(s).fixdur(i_vd));
            switchrate_valdiff_d(s,vd == valdiff_unique) = nanmean(switchnum(i_vd)./rt_without_lastfix);
        end
        
    end
    switchnum_valdiff{d} = switchnum_valdiff_d;
    switchrate_valdiff{d} = switchrate_valdiff_d;
end

% Create time bins for switch prob data for smoother results
if useBinnedX == 1
    switchBinaryMat_orig = switchBinaryMat;
    if whichExperiment == 0 
        binSize = 5;
    elseif whichExperiment == 1 
        binSize = 10;
    end
    i_bin = discretize(xaxis_orig,length(xaxis_orig)/binSize);
    % Get new x-axis, using bin mean
    xaxis_binned = nan(1,length(unique(i_bin)));
    for b = 1:max(i_bin)
        xaxis_binned(b) = mean(xaxis_orig(b==i_bin));
    end
    % Bin data
    for ff = fieldnames(switchBinaryMat)'
        tempMat = nan(size(switchBinaryMat.(char(ff))(:,:,d),1),max(i_bin),size(switchBinaryMat.(char(ff)),3));
        for d = 1:length(allDstructs)
            for b = 1:max(i_bin)
                tempMat(:,b,d) = mean(switchBinaryMat.(char(ff))(:,b==i_bin,d),2);
            end
        end
        switchBinaryMat.(char(ff)) = tempMat;
    end
    xaxis = xaxis_binned;
else
    xaxis = xaxis_orig;
end

% Plot results
% Switch probability
if whichExperiment == 0
    ylimit_switchprob = [0,0.25]; 
elseif whichExperiment == 1
    ylimit_switchprob = [0,0.15]; 
end

xlimit_switchprob = [0,RTcutoff];
for d = 1:length(allDstructs) %d=1,data;d=2,model
    fh = figure('units','normalized','outerposition',[0,0,1,0.4]);
    % All trials
    subplot(1,4,1); pbaspect([1,1,1]); hold on;
    [data_mean,data_se] = getMeanAndSE(switchBinaryMat.all(:,:,d));
    errorbar(xaxis,data_mean,data_se,'Color',colors_dstruct{d},'LineStyle', 'none', 'LineWidth', 2);
    shadedErrorBars(xaxis,data_mean,data_se, colors_dstruct{d}, 2, '-');
   
    set(gca,'ylim',ylimit_switchprob,'xlim',xlimit_switchprob);
    xlabel('Time (s)'); ylabel('Switch probability');
    title(titles_dstruct{d});

    subplot(1,4,2); pbaspect([1,1,1]); hold on;
    smooths = spcrv([[xaxis(1) xaxis xaxis(end)];[data_mean(1) data_mean data_mean(end)]],3);
    hold on;
    YLim=[min(smooths(2,:)),max(smooths(2,:))];
    [XMesh,YMesh]=meshgrid(smooths(1,:),linspace(YLim(1),YLim(2),1000));
    YMeshA=repmat(smooths(2,:),[1000,1]);
    CMesh=nan.*XMesh;
    CMesh(YMesh>=YLim(1)&YMesh<=YMeshA)=YMesh(YMesh>=YLim(1)&YMesh<=YMeshA);
    surf(XMesh,YMesh,XMesh.*0,'EdgeColor','none','CData',CMesh,'FaceColor','flat','FaceAlpha',.8)
    if d == 1
        colormap("Winter");colorbar;
    elseif d == 2
        colormap("Spring");colorbar;
    end
    
    set(gca,'ylim',ylimit_switchprob,'xlim',xlimit_switchprob);
    xlabel('Time (s)'); ylabel('Switch probability');
    title(titles_dstruct{d});
        
    % Split by valdiff
    subplot(1,4,3); pbaspect([1,1,1]); hold on;
    [mean_low,se_low] = getMeanAndSE(switchBinaryMat.valdiff_low(:,:,d));
    ax_low = errorbar(xaxis,mean_low,se_low,'g');
    [mean_hi,se_hi] = getMeanAndSE(switchBinaryMat.valdiff_hi(:,:,d));
    ax_hi = errorbar(xaxis,mean_hi,se_hi,'r');
    if whichExperiment == 0 
        [mean_mid,se_mid] = getMeanAndSE(switchBinaryMat.valdiff_mid(:,:,d));
        ax_mid = errorbar(xaxis,mean_mid,se_mid,'b');
    end

    set(gca,'ylim',ylimit_switchprob,'xlim',xlimit_switchprob);
    xlabel('Time (s)'); ylabel('Switch probability');
    title('Split by ease level');
    if whichExperiment == 0
        legend([ax_low,ax_mid,ax_hi],{'Desicion Ease Level = 0','Desicion Ease Level = 1','Desicion Ease Level = 2'});
    elseif whichExperiment == 1
        legend([ax_low,ax_hi],{'Desicion Ease Level = 0','Desicion Ease Level = 1'});
    end

    [mean_low,se_low] = getMeanAndSE(switchBinaryMat.valdiff_low(:,:,d));
    [mean_hi,se_hi] = getMeanAndSE(switchBinaryMat.valdiff_hi(:,:,d));
    if whichExperiment == 0 
        [mean_mid,se_mid] = getMeanAndSE(switchBinaryMat.valdiff_mid(:,:,d));
    end

    subplot(1,4,4); pbaspect([1,1,1]); hold on;
    smooths_low = spcrv([[xaxis(1) xaxis xaxis(end)];[mean_low(1) mean_low mean_low(end)]],3);
    smooths_hi = spcrv([[xaxis(1) xaxis xaxis(end)];[mean_hi(1) mean_hi mean_hi(end)]],3);
    if d == 2
        ax_low = plot(smooths_low(1,:),smooths_low(2,:),'-.', 'Color', [1.00,0.41,0.16], 'LineWidth', 2);
        hold on;
        ax_hi = plot(smooths_hi(1,:),smooths_hi(2,:),'-.', 'Color', [0.72,0.27,1.00], 'LineWidth', 2);
        hold on;
        % fill([xaxis, fliplr(xaxis)],[mean_low,zeros(size(mean_low))], [1.00,0.53,0.00], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        areah(xaxis, mean_low, 'Color', [1.00,0.41,0.16],'LineWidth', 2);
        hold on;
        % fill([xaxis, fliplr(xaxis)],[mean_hi,zeros(size(mean_hi))], [0.72,0.27,1.00], 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        areah(xaxis, mean_hi, 'Color', [0.72,0.27,1.00],'LineWidth', 2);
    elseif d == 1
        ax_low = plot(smooths_low(1,:),smooths_low(2,:),'-.', 'Color', [0.07,0.71,0.26], 'LineWidth', 2);
        hold on;
        ax_hi = plot(smooths_hi(1,:),smooths_hi(2,:),'-.', 'Color', [0.00,0.50,1.00], 'LineWidth', 2);
        hold on;
        areah(xaxis, mean_low, 'Color', [0.07,0.71,0.26],'LineWidth', 2);
        hold on;
        areah(xaxis, mean_hi, 'Color', [0.00,0.50,1.00],'LineWidth', 2);
    end

    set(gca,'ylim',ylimit_switchprob,'xlim',xlimit_switchprob);
    xlabel('Time (s)'); ylabel('Switch probability');
    title('Split by ease level');

    if whichExperiment == 0
        legend([ax_low,ax_hi],{'Evidence Clarity = 0','Evidence Clarity = 2'});
    elseif whichExperiment == 1
        legend([ax_low,ax_hi],{'Evidence Clarity = 0','Evidence Clarity = 1'});
    end
    % Stats
    % [~,pvals] = ttest(switchBinaryMat.valdiff_low(:,:,d),switchBinaryMat.valdiff_hi(:,:,d));
    % if useBonferroni==1
    %     i_sig = pvals < 0.05/size(switchBinaryMat.all,1);
    % else
    %     [h, crit_p, adj_ci_cvrg, adj_p]=fdr_bh(pvals);  % FDR-corrected for multiple comparisons
    %     i_sig = adj_p < 0.05;
    % end
    % y_asterisk = 0.14;  % Where to show stars for significance
    % plot(xaxis(i_sig),repmat(y_asterisk,1,sum(i_sig)),'k*');
    

    % 3D Switch probability
    if whichExperiment == 0 
        smooths_mid = spcrv([[xaxis(1) xaxis xaxis(end)];[mean_mid(1) mean_mid mean_mid(end)]],3);
        [X, Y] = meshgrid(smooths_low(1,:), [0 1 2]);
        C = [smooths_low(2,:); smooths_mid(2,:); smooths_hi(2,:)];
        figure;
        surf(X, Y, C,'FaceAlpha',0.6,'EdgeColor', 'none');

        colorbar;view(7,11);
        xlabel('Time (s)');
        ylabel('Desicion Ease Level');
        zlabel('Switch probability');
        title('3D Surface Plot');
    
        % z=-0.1 projection
        hold on;
        zproj = -0.02 * ones(size(X));
        surf(X, Y, zproj, C, 'FaceAlpha',0.2,'EdgeColor', 'none');

    elseif whichExperiment == 1
        [X, Y] = meshgrid(smooths_low(1,:), [0 1]);
        figure;
        C = [smooths_low(2,:); smooths_hi(2,:)];
        surf(X, Y, C,'FaceAlpha',0.6,'EdgeColor', 'none');
        colorbar;view(7,11);
        xlabel('Time (s)');
        ylabel('Desicion Ease');
        zlabel('Switch probability');
        title('3D Surface Plot');

        hold on;
        zproj = -0.02 * ones(size(X));
        surf(X, Y, zproj, C, 'FaceAlpha',0.2,'EdgeColor', 'none');
    end
         
end

 