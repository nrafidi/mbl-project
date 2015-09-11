numSamp = 2835;
divLabels = labels(1:numSamp,:);
numFeat = size(labels, 2);
groupSizes = [1 5 15 45 135];

for g = groupSizes
    numGroups = numSamp/g;
    groupImage = nan(numGroups, numFeat);
    for gg = 1:numGroups
        startInd = (gg-1)*g + 1;
        endInd = gg*g;
        groupImage(gg,:) = mean(divLabels(startInd:endInd,:), 1);
    end
    distBtw = pdist(groupImage);
    disp(mean(distBtw(1:numGroups)));
%     figure
%     imagesc(groupImage);
%     title(num2str(g));
end