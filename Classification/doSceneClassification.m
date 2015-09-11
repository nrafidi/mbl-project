function [errs] = doSceneClassification(dataMatrix, labelMatrix, ...
    movie_times, label_times)

samplesToUse = size(dataMatrix, 1);

groupSize = 13;
numGroups = samplesToUse/groupSize;
X = cell(numGroups, 1);
Y = cell(numGroups, 1);
timeMatrix = cell(numGroups, 1);
for gg = 1:numGroups
    startInd = (gg-1)*groupSize + 1;
    endInd = gg*groupSize;
    timesToUse = movie_times(startInd:endInd);
    labelIndsToUse = nan(groupSize, 1);
    for tt = 1:groupSize
        labelInd = label_times == timesToUse(tt);
        timeAdded = 1;
        while ~any(labelInd)
            labelInd = (label_times <= (timesToUse(tt)+timeAdded)) & ...
                (label_times > timesToUse(tt));
            timeAdded = timeAdded+1;
        end
        labelIndsToUse(tt) = find(labelInd);
    end
    
    X{gg} = dataMatrix(startInd:endInd, :);
%     X{gg} = rand(groupSize, size(dataMatrix, 2));
    Y{gg} = labelMatrix(labelIndsToUse, :);
    timeMatrix{gg} = label_times(labelIndsToUse);
end
% keyboard;
if size(dataMatrix, 2) > samplesToUse
    alg = 0;
else
    alg = 3;
end

[errs, ~] = ...
    do2v2CrossValWinZ_cellX(X, Y, '', ...
    false, alg, 0, true, false, 'cosine');
end