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
whichExperiment = 0;

if whichExperiment == 0  % lane-changing
    % DEAM
    d = 0.003;
    sig2 = 0.03;
    decbound = 2.8;
    decay_rate = 0.35; 
    m = 0.18; n = 1.25;

    %% aDDM
    %aGamma=0.3;
    sig2_Model = sig2^2;
    maxdectime = 10;

    % Load behavioral data
    load(fullfile(data_dir,sprintf('datastruct_lanechange05206.mat')));
    % Plot options
    plotOptions.Experiment = 0;

elseif whichExperiment == 1  % car-following 
    % the adopted parameters for car-following
    % DEAM
    d = 0.0008;  sig2 = 0.01; decay_rate = 0.15; decbound = 1.5;
    m = 0.1; n = 1.5; 
    sig2_Model = sig2^2;
    maxdectime = 18;

    % Load behavioral data
    load(fullfile(data_dir,sprintf('datastruct_highway40.mat')));
    % Plot options
    plotOptions.Experiment = 1;  

end

%% Behavioral plots for human behavior & model simulations

% Generate behavior using model
numsubs = length(dstruct_real);

% Plot behavioral plots
bout_sim_data = getbehavoutput(dstruct_real);
stats_behav_data = makeBehavPlots_realData(bout_sim_data,plotOptions);
actual_data_p = bout_sim_data.item1chosen_valdiff_all;
actual_data_rt = bout_sim_data.rt_valdiff_abs;
actual_data_sw = bout_sim_data.switchcount_valdiff_abs;

 
% Get empty datastruct for models
if whichExperiment == 0
    z_reps = 20;  % Number of iteration
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
        fixdist_first = fixdist.all_first{fixdist.valdiff==round(thisvaldiff)};
                  
        if whichExperiment == 1 
            % fixdist_mid = fixdist.all_mid{fixdist.valdiff==round(thisvaldiff)};
            random_factor = 0.85 + rand; % fix modification factor
            fixdist_mid = fixdist.all_mid{fixdist.valdiff==round(thisvaldiff)}*random_factor;
            % if rand <= 0.5, y = 1; else, y=2; end
            y = 2;
        elseif whichExperiment == 0
            random_factor = 1 + rand;
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
        % [dstruct(s).choice(ti),dstruct(s).rt(ti),dstruct(s).fixitem{ti},dstruct(s).fixdur{ti},dstruct(s).tItem(ti,:),~] =  ...
        % run_aDDM(dstruct(s).itemval(ti,:),dt,d,sig2_Model,aGamma,yseq_toMaxTime); 
    end

end
        
bout_sim = getbehavoutput(dstruct);
stats_behav = makeBehavPlots_model(bout_sim,plotOptions);
stimulus_data_p = bout_sim.item1chosen_valdiff_all;
stimulus_data_rt = bout_sim.rt_valdiff_abs;
stimulus_data_sw = bout_sim.switchcount_valdiff_abs;


% Calculate MSE between simulated and real data
mse_p = mse(stimulus_data_p - actual_data_p);
mse_rt = mse(stimulus_data_rt - actual_data_rt);
mse_switchcount = mse(stimulus_data_sw - actual_data_sw);
disp(['MSE of p(Lane-changing) between simulated and real data: ', num2str(mse_p)]);
disp(['MSE of RT between simulated and real data: ', num2str(mse_rt)]);
disp(['MSE of SwitchCount between simulated and real data: ', num2str(mse_switchcount)]);

