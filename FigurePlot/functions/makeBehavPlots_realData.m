function allstats = makeBehavPlots_realData(bout,plotOptions)


allstats = struct;  % return statistical tests done
subCount = length(bout.rt);
plot_psychometrics = 1;
plot_choiceDiff = 1;
plot_choiceBias = 1;

%% Basic psychometric curves
if plot_psychometrics==1
    fh = figure('units','normalized','outerposition',[0 0 1 0.6]);
    
    % Proportion chosen item 1 vs. value difference
    toplot = bout.item1chosen_valdiff_all;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;  % Remove columns where there are NaNs more than half of all data
    [this_mean,this_se] = getMeanAndSE(toplot);
    subplot(1,4,1); hold on;
    xticks(bout.valdiff(usebin_i)); 

    bar(bout.valdiff(usebin_i), this_mean, 0.4, 'FaceColor', [0.529, 0.808, 0.922], 'EdgeColor', 'none');
    errorbar(bout.valdiff(usebin_i), this_mean, this_se, 'k.', 'markersize', 10);
    
    xticklabels({'-2', '-1', '0', '1', '2'});
    xlabel('value difference'); ylabel('P(Lane Change)'); pbaspect([1,0.7,1]);

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
    subplot(1,4,2); hold on;
    [this_mean,this_se] = getMeanAndSE(bout.rt_valdiff_abs);
    bar(bout.valdiff_abs(usebin_i), this_mean, 0.4, 'FaceColor', [0.529, 0.808, 0.922], 'EdgeColor', 'none');
    errorbar(bout.valdiff_abs(usebin_i), this_mean, this_se, 'k.', 'markersize', 10);
    xticks(bout.valdiff_abs(usebin_i));
    xticklabels({'0', '1', '2'});

    xlabel('Abs(value difference)');
    % set(gca,'xlim',[bout.valdiff_abs(1)-1,bout.valdiff_abs(end)+1]);
    ylabel('RT (s)'); pbaspect([1,1,1]);

    % Stats
    b_all = nan(subCount,1); x = bout.rt_valdiff_abs(usebin_i);
    for s = 1:subCount
        b = regress(toplot(s,usebin_i)',[ones(length(x),1),x']);
        b_all(s) = b(2);
    end
    allstats.rt_absValDiff = ttest_full(b_all);
    
    % Switch count vs absolute value difference
    for use_switchrate = [0,1]
        % Use switchcountRT to show switch rate (#switches per time)
        if use_switchrate==1
            toplot = bout.switchcountRT_valdiff_abs;
        else
            toplot = bout.switchcount_valdiff_abs;
        end
        usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
        subplot(1,4,3+use_switchrate); hold on;
        [this_mean,this_se] = getMeanAndSE(toplot);
        
        bar(bout.valdiff_abs(usebin_i), this_mean, 0.4, 'FaceColor', [0.529, 0.808, 0.922], 'EdgeColor', 'none');
        errorbar(bout.valdiff_abs(usebin_i), this_mean, this_se, 'k.', 'markersize', 10);
        xticks(bout.valdiff_abs(usebin_i));

        xticklabels({'0', '1', '2'});
        xlabel('Abs(value difference)'); 

        if use_switchrate==1
            ylabel('Switch rate (s^{-1})');
        else
            ylabel('Number of switches');
            % Kruskal-Wallis
            % [p_value, ~, stats] = kruskalwallis(toplot, bout.valdiff_abs);
        end
        pbaspect([1,1,1]);
    end
    if plotOptions.saveFigures == 1
        print(fh,fullfile(plotOptions.figsavedir,sprintf('psychometric_curves%s.svg',plotOptions.saveStrAppend)),'-dsvg','-r200');
    end
    % Stats
    b_all = nan(subCount,1); x = bout.switchcount_valdiff_abs(usebin_i);
    for s = 1:subCount
        b = regress(toplot(s,usebin_i)',[ones(length(x),1),x']);
        b_all(s) = b(2);
    end
    allstats.SwitchCount_absValDiff = ttest_full(b_all);
    b_all = nan(subCount,1); x = bout.switchcountRT_valdiff_abs(usebin_i);
    for s = 1:subCount
        b = regress(toplot(s,usebin_i)',[ones(length(x),1),x']);
        b_all(s) = b(2);
    end
    allstats.switchCountRT_absValDiff = ttest_full(b_all);
    
end

 %% RT & Sitchcount vs. choice
 if plot_choiceDiff==1
 figure;
    toplot = bout.rt_choice1_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    subplot(1,2,1); hold on;
    [this_mean,this_se] = getMeanAndSE(bout.rt_choice1_valdiff_abs);
    bp1 = boxplot(toplot, 'positions', bout.valdiff_abs(usebin_i) - 0.1, 'widths', 0.15, 'colors', [0.13,0.56,0.20], 'symbol', '');
    set(bp1, 'LineWidth', 1.5); 
    hold on;
    plot( bout.valdiff_abs(usebin_i) - 0.1, this_mean(usebin_i), 'r*', 'MarkerSize', 10); hold on;
    % Plot scatter plot
    scatter(bout.valdiff_abs(usebin_i)-0.1, toplot, 12, 'MarkerFaceColor',[0.55,0.85,0.49], 'MarkerFaceAlpha',0.9,'MarkerEdgeColor', 'none' );
    hold on;
    rate = 0.35;

   for i = 1:length(bout.valdiff_abs)
        tX = toplot(:, i); 
        tX = tX(~isnan(tX)); 
        [F, Xi] = ksdensity(tX); 
        x_position = i - 1.1; 
        plot1 = fill(x_position + [0, F, 0] .* rate, [Xi(1), Xi, Xi(end)], [0.306, 0.541, 0.318], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'LineWidth', 1.2);
    end

    toplot = bout.rt_choice2_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    hold on;
    [this_mean,this_se] = getMeanAndSE(bout.rt_choice2_valdiff_abs);
    bp2 = boxplot(toplot, 'positions', bout.valdiff_abs(usebin_i) + 0.1, 'widths', 0.15, 'colors', [0.00,0.45,0.74], 'symbol', '');
    set(bp2, 'LineWidth', 1.5); 
    hold on;
    plot( bout.valdiff_abs(usebin_i) + 0.1, this_mean(usebin_i), 'r*', 'MarkerSize', 10); hold on;
    % Plot scatter plot
    scatter(bout.valdiff_abs(usebin_i) + 0.1, toplot, 12, 'MarkerFaceColor',[0.529, 0.808, 0.922], 'MarkerFaceAlpha',0.9,'MarkerEdgeColor', 'none' );
    hold on;
    % rate = 0.35;

   for i = 1:length(bout.valdiff_abs)
        tX = toplot(:, i); 
        tX = tX(~isnan(tX)); 
        [F, Xi] = ksdensity(tX); 
        x_position = i - 0.9; 
        plot2 = fill(x_position + [0, F, 0] .* rate, [Xi(1), Xi, Xi(end)], [0.00,0.45,0.74], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'LineWidth', 1.2);
   end
   xticks(bout.valdiff_abs(usebin_i)); xticklabels({'0', '1', '2'});
    xlabel('Abs(value difference)');
    ylabel('RT (s)'); 
    if plotOptions.Experiment == 0
        ylim([0, 8]); 
    elseif plotOptions.Experiment == 1
        ylim([4, 14]); 
    end
    pbaspect([0.75,1,1]);
    legend([plot1,plot2],{'Choice = Lane-changing','Choice = Lane-keeping'});

%%
    toplot = bout.switchcount_choice1_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    subplot(1,2,2); hold on;
    [this_mean,this_se] = getMeanAndSE(bout.switchcount_choice1_valdiff_abs);
    bp1 = boxplot(toplot, 'positions', bout.valdiff_abs(usebin_i) - 0.1, 'widths', 0.15, 'colors', [0.13,0.56,0.20], 'symbol', '');
    set(bp1, 'LineWidth', 1.5); 
    hold on;
    plot( bout.valdiff_abs(usebin_i) - 0.1, this_mean(usebin_i), 'r*', 'MarkerSize', 10); hold on;

    % Plot scatter plot
    scatter(bout.valdiff_abs(usebin_i)-0.1, toplot, 12, 'MarkerFaceColor',[0.55,0.85,0.49], 'MarkerFaceAlpha',0.9,'MarkerEdgeColor', 'none' );
    hold on;
    rate = 0.35;

   for i = 1:length(bout.valdiff_abs)
        tX = toplot(:, i); 
        tX = tX(~isnan(tX)); 
        [F, Xi] = ksdensity(tX); 
        x_position = i - 1.1; 
        plot1 = fill(x_position + [0, F, 0] .* rate, [Xi(1), Xi, Xi(end)], [0.306, 0.541, 0.318], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'LineWidth', 1.2);
    end

    toplot = bout.switchcount_choice2_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    % subplot(1,4,4); 
    hold on;
    [this_mean,this_se] = getMeanAndSE(bout.switchcount_choice2_valdiff_abs);
    % errorbar(bout.valdiff_abs(usebin_i)+0.1,this_mean(usebin_i),this_se(usebin_i),'.k','markersize',30);hold on;
    bp2 = boxplot(toplot, 'positions', bout.valdiff_abs(usebin_i) + 0.1, 'widths', 0.15, 'colors', [0.00,0.45,0.74], 'symbol', '');
    set(bp2, 'LineWidth', 1.5); 
    hold on;
    plot( bout.valdiff_abs(usebin_i) + 0.1, this_mean(usebin_i), 'r*', 'MarkerSize', 10); hold on;
    scatter(bout.valdiff_abs(usebin_i) + 0.1, toplot, 12, 'MarkerFaceColor',[0.529, 0.808, 0.922], 'MarkerFaceAlpha',0.9,'MarkerEdgeColor', 'none' );
    hold on;
    % rate = 0.35;

   for i = 1:length(bout.valdiff_abs)
        tX = toplot(:, i); 
        tX = tX(~isnan(tX)); 
        [F, Xi] = ksdensity(tX); 
        x_position = i - 0.9; 
        plot2 = fill(x_position + [0, F, 0] .* rate, [Xi(1), Xi, Xi(end)], [0.00,0.45,0.74], 'EdgeColor', 'none', 'FaceAlpha', 0.4, 'LineWidth', 1.2);
   end

       xticks(bout.valdiff_abs(usebin_i)); xticklabels({'0', '1', '2'});
    xlabel('Abs(value difference)');
    ylabel('Number of switches'); 
    if plotOptions.Experiment == 0
        ylim([0, 8]); 
    elseif plotOptions.Experiment == 1
        ylim([2, 20]); 
    end 
    pbaspect([0.75,1,1]);
    legend([plot1,plot2],{'Choice = Lane-changing','Choice = Lane-keeping'});

    %%
    figure;
    subplot(1,4,1); hold on;
    toplot = bout.rt_choice1_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    subplot(1,4,1); hold on;
    [this_mean,this_se] = getMeanAndSE(toplot);
    errorbar(bout.valdiff_abs(usebin_i) - 0.1, this_mean(usebin_i), this_se(usebin_i), 'Color', [0.00, 0.45, 0.74], 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 2, 'Marker','.','MarkerSize', 30);
    xticks(bout.valdiff_abs(usebin_i)); xticklabels({'0', '1', '2'});
    xlabel('Abs(value difference)');   ylabel('RT (s)'); 
    if plotOptions.Experiment == 0
        ylim([2, 6]); 
    elseif plotOptions.Experiment == 1
        ylim([4, 14]); 
    end
    pbaspect([0.7,1,1]);

    subplot(1,4,2); hold on;
    toplot = bout.rt_choice2_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    [this_mean,this_se] = getMeanAndSE(toplot);
    errorbar(bout.valdiff_abs(usebin_i) - 0.1, this_mean(usebin_i), this_se(usebin_i), 'Color', [0.00, 0.45, 0.74], 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 2, 'Marker','.','MarkerSize', 30);
    xticks(bout.valdiff_abs(usebin_i)); xticklabels({'0', '1', '2'});
    xlabel('Abs(value difference)');    ylabel('RT (s)'); 
    if plotOptions.Experiment == 0
        ylim([2, 6]); 
    elseif plotOptions.Experiment == 1
        ylim([4, 14]); 
    end
    pbaspect([0.7,1,1]);

    subplot(1,4,3); hold on;
    toplot = bout.switchcount_choice1_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    [this_mean,this_se] = getMeanAndSE(toplot);
    errorbar(bout.valdiff_abs(usebin_i) - 0.1, this_mean(usebin_i), this_se(usebin_i), 'Color', [0.00, 0.45, 0.74], 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 2, 'Marker','.','MarkerSize', 30);
    xticks(bout.valdiff_abs(usebin_i)); xticklabels({'0', '1', '2'});
    xlabel('Abs(value difference)');
    ylabel('Number of switches'); 
    if plotOptions.Experiment == 0
        ylim([2, 5]); 
    elseif plotOptions.Experiment == 1
        ylim([2, 20]); 
    end 
    pbaspect([0.7,1,1]);

    subplot(1,4,4); hold on;
    toplot = bout.switchcount_choice2_valdiff_abs;
    usebin_i = sum(~isnan(toplot),1)>=size(toplot,1)/2;
    [this_mean,this_se] = getMeanAndSE(toplot);
    errorbar(bout.valdiff_abs(usebin_i) - 0.1, this_mean(usebin_i), this_se(usebin_i), 'Color', [0.00, 0.45, 0.74], 'LineStyle', 'none', 'LineWidth', 2, 'CapSize', 2, 'Marker','.','MarkerSize', 30);
    xticks(bout.valdiff_abs(usebin_i)); xticklabels({'0', '1', '2'});
    xlabel('Abs(value difference)');
    ylabel('Number of switches'); 
    if plotOptions.Experiment == 0
        ylim([2, 5]); 
    elseif plotOptions.Experiment == 1
        ylim([2, 20]); 
    end 
    pbaspect([0.7,1,1]);

 end


%% Choice biases
if plot_choiceBias==1
    vdshow_i = abs(bout.valdiff) <= 2;
    plots = [];
    fh = figure('units','normalized','outerposition',[0 0 1 0.6]);
    subplot(1,2,1); hold on;
    [out_mean,out_se] = getMeanAndSE(bout.item1chosen_valdiff_all);
    plots(1) = shadedErrorBars(bout.valdiff(vdshow_i),out_mean(vdshow_i),out_se(vdshow_i), [0.015, 0.282, 0.420], 3, '-');
    [out_mean,out_se] = getMeanAndSE(bout.item1chosen_valdiff_lastRV);
    plots(2) = shadedErrorBars(bout.valdiff(vdshow_i),out_mean(vdshow_i),out_se(vdshow_i), [0.529, 0.808, 0.922], 3, '-');
    [out_mean,out_se] = getMeanAndSE(bout.item1chosen_valdiff_lastFV);
    plots(3) = shadedErrorBars(bout.valdiff(vdshow_i),out_mean(vdshow_i),out_se(vdshow_i), [0.306, 0.541, 0.318], 3, '-');
    set(gca,'ylim',[0,1]);
    legend(plots,{'All','Last fixated 1','Last fixated 2'},'location','northwest');
    xlabel('value difference'); ylabel('p(Lane Change)');
    pbaspect([1,1,1]);
    
   
end
end