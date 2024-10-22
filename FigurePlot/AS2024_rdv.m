clear;

rootdir = 'C:/Users/A/Documents/MATLAB/driving_model/ActiveSensing';
addpath(genpath(rootdir));
data_dir = fullfile(rootdir,'data');
set(0,'defaultAxesFontSize',10);

% Set parameters
dt = 0.001;
d = 0.001;
sig2_origModel = 0.02^2;
aGamma_k = 0.4;


% Plotting options
plotOptions = struct;
plotOptions.saveFigures = 0;


%% Behavioral plots for human behavior & model simulations
load(fullfile(data_dir,sprintf('datastruct_lanechange05206.mat')));

% Generate behavior using model
numsubs = length(dstruct_real);
dstruct = dstruct_real;
count = 0;
% Simulate behavior
for s = 1:numsubs
    % Get empirical distribution of fixation behavior for each difficulty level
    fixdist = getEmpiricalFixationDist(dstruct_real);
    maxdectime = 10;
    numtrials = length(dstruct(s).trialnum);
    for ti = 1:numtrials
        thisvaldiff = abs(dstruct(s).itemval(ti,1)-dstruct(s).itemval(ti,2));
        if thisvaldiff > 2, thisvaldiff = 2; end
        fixdist_first = fixdist.all_first{fixdist.valdiff==round(thisvaldiff)};
        fixdist_mid = fixdist.all_mid{fixdist.valdiff==round(thisvaldiff)};
        % if rand <= 0.5, 
        y = 1;
        % else, y=2;
        % end
        % sequence of fixations            
        yseq_toMaxTime = nan(1,maxdectime/dt);
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
        % Re-write choice
        [boundlist,RDVlist, dstruct(s).choice(ti),dstruct(s).rt(ti),dstruct(s).fixitem{ti},dstruct(s).fixdur{ti},dstruct(s).tItem(ti,:),~] = plot_rdv(dstruct(s).itemval(ti,:),aGamma_k,dt,d,sig2_origModel,yseq_toMaxTime);
        
        if length(dstruct(s).fixdur{ti}) == 1

            figure; hold on;
            x_intervals = [dstruct(s).fixdur{ti}];
            y = [-1, -1, 1, 1]; 
            start_x = 0;                    
            for i = 1:length(x_intervals)                        
                end_x = start_x + x_intervals(i); 
                % x = [start_x/dt, end_x/dt, end_x/dt, start_x/dt];  
                start_index = round(start_x/dt) + 1; 
                end_index = round(end_x/dt); 
                selected_data = RDVlist(start_index:end_index);

                if mod(i, 2) == 1 
                    rdvcolor = [0.72,0.27,1.00];
                    %fill(x, y, [0.74, 0.92, 0.99], 'FaceAlpha', 0.3, 'EdgeColor','none');  %Draw blue shading in odd intervals
                    plot(start_index:end_index, selected_data, 'LineWidth', 2, 'Color', [0.72,0.27,1.00]);
                else
                    %fill(x, y, [1.00,0.77,0.91], 'FaceAlpha', 0.3, 'EdgeColor','none');
                    rdvcolor = [0.93,0.69,0.13];
                    plot(start_index:end_index, selected_data, 'LineWidth', 2, 'Color',[0.93,0.69,0.13]);
                end                        
                start_x = end_x;
            end
            % boundlist
            plot(1:length(boundlist), boundlist, 'LineWidth', 2, 'Color', [0.85, 0.33, 0.10], 'LineStyle', '--'); 
            % -boundlist
            plot(1:length(boundlist), -boundlist, 'LineWidth', 2, 'Color', [0.85, 0.33, 0.10], 'LineStyle', '--');
            xlabel('Time (ms)');
            ylabel('Value');
            title(sprintf('Choice = %d', dstruct(s).choice(ti))); 
            legend('RDV', 'Decision Boundary'); 
            count = count + 1;
            xlim([0,  sum(x_intervals)/dt]);  
            ylim([-1.5, 1.5]); 
            text(1000, 1, sprintf('RV scenario value = %d; FV scenario value = %d', dstruct(s).itemval(ti,1), dstruct(s).itemval(ti,2)));
        end
        if count > 3 %three drawings of the immediate situation
            break;
        end
    end
end

%% Show momentary evidence across time
z = [3,2];  % Item values
sig_z = 1; %scene perceputual noise
aGamma = 0.4; 
dt = 0.001;  % Time step
t = 3.89;  % Length of time to show
ts = 1:1:3890; 
% ts = 1:1:2400; 
N = t/dt;
% colors_item = [0.47,0.67,0.19; 0.00,0.45,0.74];%ch=2
colors_item = [0.72,0.27,1.00; 0.93,0.69,0.13];%ch=1


fixseq = [2*ones(1,round(999)),ones(1,round(2440)),2*ones(1,round(240))];
fixseq = [fixseq,ones(1,N-length(fixseq))];
switchpts = ts([0,diff(fixseq)~=0]==1);

% Plot evidence distribution across time 
dx = nan(N,2);   % Evidence accumulation
tItem = [0,0];   % Time points each item was attended to
for n = 1:N
    y = fixseq(n);  % Currently attended item
    tItem(y) = tItem(y)+dt;  % Time advances
    % Evidence accumulation
    dx_RV = (aGamma^(y-1))* (z(1) + randn*sqrt(sig_z))*dt; %RV & Front
    dx_FV = (aGamma^(2-y))* (z(2) + randn*sqrt(sig_z))*dt; %FV & surround
    dx(n,:) = [dx_RV,dx_FV];
end
% Plot
figure; hold on;
for i = 1:2
    if i==1, plots(i) = plot(ts,dx(:,i),'o','Color',colors_item(i,:),'markersize',3);
    else, plots(i) = plot(ts,dx(:,i),'.','Color',colors_item(i,:),'markersize',6);
    end
    plot(get(gca,'xlim'),[z(i)*dt,z(i)*dt],'--','Color',colors_item(i,:));
end
% set(gca,'ylim',[-0.002,0.008]);
for sw = 1:length(switchpts), plot([switchpts(sw),switchpts(sw)],get(gca,'ylim'),'k--'); end
xlabel('Time(ms)');
ylabel('Momentary evidence');
legend(plots,{'RV','FV'});
% legend(plots,{'FV','Surrounding'});