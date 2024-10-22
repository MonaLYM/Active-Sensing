function fixdist = getEmpiricalFixationDist(dstruct)
%Get the empirical fixation distribution depending on the value difference
%(difficulty)

fixdist = struct;

% Get all possible value difference
allvals = [];
for s = 1:length(dstruct)
    allvals = cat(1,allvals,dstruct(s).itemval);
end
% valdiff = unique(abs(allvals(:,1)-allvals(:,2)));
valdiff = unique(allvals(:,1)-allvals(:,2));

% fixation distribution per subject
fixdist.sub_first = cell(length(dstruct),length(valdiff));
fixdist.sub_mid = cell(length(dstruct),length(valdiff));
fixdist.sub_last = cell(length(dstruct),length(valdiff));
% Aggregate fixation distribution
fixdist.all_first = cell(1,length(valdiff));
fixdist.all_mid = cell(1,length(valdiff));
fixdist.all_last = cell(1,length(valdiff));
for s = 1:length(dstruct)
    for vd = valdiff'
        i_vd = vd == valdiff;
        %thisvd_fixdur = dstruct(s).fixdur(abs(dstruct(s).itemval(:,1)-dstruct(s).itemval(:,2))==vd,:);
        thisvd_fixdur = dstruct(s).fixdur(dstruct(s).itemval(:,1)-dstruct(s).itemval(:,2)==vd,:);

        % Filter out fixdur < 0.1
        thisvd_fixdur_filtered = thisvd_fixdur(cellfun(@(x) x(1) >= 0.01, thisvd_fixdur));

        for t = 1:length(thisvd_fixdur_filtered)
            fixdur_first = thisvd_fixdur_filtered{t}(1);
            fixdist.sub_first{s, i_vd} = cat(1, fixdist.sub_first{s, i_vd}, fixdur_first);
            fixdist.all_first{i_vd} = cat(1, fixdist.all_first{i_vd}, fixdur_first);
            
            fixdur_last = thisvd_fixdur_filtered{t}(end);
            fixdist.sub_last{s, i_vd} = cat(1, fixdist.sub_last{s, i_vd}, fixdur_last);
            fixdist.all_last{i_vd} = cat(1, fixdist.all_last{i_vd}, fixdur_last);
            
            if length(thisvd_fixdur_filtered{t}) > 2
                fixdur_mid = thisvd_fixdur_filtered{t}(2:end-1)';
                fixdist.sub_mid{s, i_vd} = cat(1, fixdist.sub_mid{s, i_vd}, fixdur_mid);
                fixdist.all_mid{i_vd} = cat(1, fixdist.all_mid{i_vd}, fixdur_mid);

                % % 在这里使用 unique 函数删除重复的数值
                % fixdur_mid_unique = unique(fixdur_mid);
                % fixdist.sub_mid{s, i_vd} = cat(1, fixdist.sub_mid{s, i_vd}, fixdur_mid_unique);
                % % 累积到 all_mid 时也只保留不重复的数值
                % fixdist.all_mid{i_vd} = unique(cat(1, fixdist.all_mid{i_vd}, fixdur_mid_unique));

                %计算5%和95%的百分位数
                % lower_bound = prctile(fixdur_mid, 20);
                % upper_bound = prctile(fixdur_mid, 95);
                %仅保留在5%和95%百分位数之间的数值
                % fixdur_mid_filtered = fixdur_mid(fixdur_mid >= lower_bound);% & fixdur_mid <= upper_bound);

                % % 计算10%的百分位数
                % if abs(vd) == 1  % 当 valdiff 等于 1 或 -1 时
                %     lower_bound = prctile(fixdur_mid, 40);
                %     fixdur_mid_filtered = fixdur_mid(fixdur_mid >= lower_bound);
                % else
                %     fixdur_mid_filtered = fixdur_mid;  % 其他情况下保留所有值
                % end
                
                % 将过滤后的数据保存到结构体中
                % fixdist.sub_mid{s, i_vd} = cat(1, fixdist.sub_mid{s, i_vd}, fixdur_mid_filtered);
                % fixdist.all_mid{i_vd} = cat(1, fixdist.all_mid{i_vd}, fixdur_mid_filtered);
            end
        end

        % for t = 1:length(thisvd_fixdur)
        %     fixdur_first = thisvd_fixdur{t}(1);
        %     fixdist.sub_first{s,i_vd} = cat(1,fixdist.sub_first{s,i_vd},fixdur_first);
        %     fixdist.all_first{i_vd} = cat(1,fixdist.all_first{i_vd},fixdur_first);
        % 
        %     fixdur_last = thisvd_fixdur{t}(end);
        %     fixdist.sub_last{s,i_vd} = cat(1,fixdist.sub_last{s,i_vd},fixdur_last);
        %     fixdist.all_last{i_vd} = cat(1,fixdist.all_last{i_vd},fixdur_last);
        % 
        %     if length(thisvd_fixdur{t}) > 2
        %         fixdur_mid = thisvd_fixdur{t}(2:end-1)';
        %         fixdist.sub_mid{s,i_vd} = cat(1,fixdist.sub_mid{s,i_vd},fixdur_mid);
        %         fixdist.all_mid{i_vd} = cat(1,fixdist.all_mid{i_vd},fixdur_mid);
        %     end
        % end
    end
end
fixdist.valdiff = valdiff;



%% OLD CODE

% % Get empirical distribution of fixation behavior for each difficulty level
% allvals = [];
% allfixitem = [];
% allfixdur = [];
% allsubno = [];
% for s = 1:length(dstruct)
%     allvals = cat(1,allvals,dstruct(s).itemval);
%     allfixitem = cat(1,allfixitem,dstruct(s).fixitem);
%     allfixdur = cat(1,allfixdur,dstruct(s).fixdur);
%     allsubno = cat(1,allsubno,repmat(s,[length(dstruct(s).trialnum),1]));
% end
% valdiff = unique(abs(allvals(:,1)-allvals(:,2)));
% 
% % Get distribution of fixation times for each item, per difficulty
% fixdist_peritem = {};
% fixdist_mid_all = {};
% fixdist_first_all = {};
% fixdist_last_all = {};
% for vd = valdiff'
%     thisvd_fixitem = allfixitem(abs(allvals(:,1)-allvals(:,2))==vd);
%     thisvd_fixdur = allfixdur(abs(allvals(:,1)-allvals(:,2))==vd);
%     thisvd_subno = allsubno(abs(allvals(:,1)-allvals(:,2))==vd);
%     thisvd_fixdist_peritem = {};
%     thisvd_fixdist_first = [];
%     thisvd_fixdist_mid = [];
%     thisvd_fixdist_last = [];
%     % Fixation dist per item
%     for item = 1:2
%         thisvd_fixdist_peritem{item} = [];
%         for j = 1:length(thisvd_fixitem)
%             thisvd_fixdist_peritem{item} = cat(1,thisvd_fixdist_peritem{item},thisvd_fixdur{j}(thisvd_fixitem{j}==item)');
%         end
%     end
%     % Fixation dist all items
%     for j = 1:length(thisvd_fixitem)
%         fix_first = thisvd_fixdur{j}(1);
%         fix_last = thisvd_fixdur{j}(end);
%         if length(thisvd_fixdur{j}) > 2
%             fix_mid = thisvd_fixdur{j}(2:end-1);
%         end
%         thisvd_fixdist_first = cat(1,thisvd_fixdist_first,fix_first);
%         thisvd_fixdist_mid = cat(1,thisvd_fixdist_mid,fix_mid');
%         thisvd_fixdist_last = cat(1,thisvd_fixdist_last,fix_last);
%     end
%     fixdist_peritem = cat(1,fixdist_peritem,thisvd_fixdist_peritem);
%     fixdist_first_all = cat(1,fixdist_first_all,thisvd_fixdist_first);
%     fixdist_mid_all = cat(1,fixdist_mid_all,thisvd_fixdist_mid);
%     fixdist_last_all = cat(1,fixdist_last_all,thisvd_fixdist_last);
% end
% 
% fixdist.first = fixdist_first_all;
% fixdist.mid = fixdist_mid_all;
% fixdist.last = fixdist_last_all;
% fixdist.peritem = fixdist_peritem;
% fixdist.valdiff = valdiff;

end

