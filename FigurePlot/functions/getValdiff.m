function valdiff = getValdiff(dstruct)
%Given data structure, return the abs(itemval 1 - itemval 2)
valdiff = [];
for s = 1:length(dstruct)
    valdiff = cat(1,valdiff,abs(dstruct(s).itemval(:,1)-dstruct(s).itemval(:,2)));
end
end

