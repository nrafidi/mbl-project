% Align labels to TRs

load ../../Data/hemiData_1_run1.mat
load ../../Data/labelsAndTimes.mat
load ../../Data/laggedLabelsAndTimes.mat
%%
labelIndsToUse = (label_times ~= 0);
label_times = label_times(labelIndsToUse);
labels = labels(labelIndsToUse, :);
laggedLabels = laggedLabels(labelIndsToUse, :);

labelStartTime = min(label_times);
movieIndsToUse = movie_times >= labelStartTime;
movie_times = movie_times(movieIndsToUse);
unrolledData = unrolledData(movieIndsToUse, :);
%%
indsToFix = [];
for i = 2:length(movie_times)
    if movie_times(i) - movie_times(i-1) > 2
        indsToFix = cat(1, indsToFix, i);
    end
end

diffToAdjustBy = 0;
for i = 1:length(indsToFix)
    
    newDiff = ...
        movie_times(indsToFix(i)) - (movie_times(indsToFix(i) - 1) + 2);
    diffToAdjustBy = diffToAdjustBy + newDiff;
    disp(diffToAdjustBy);
    if i < length(indsToFix)
        movie_times(indsToFix(i):indsToFix(i+1)) = ...
            movie_times(indsToFix(i):indsToFix(i+1)) - diffToAdjustBy;
        if i > 1
            movie_times(indsToFix(i)) = movie_times(indsToFix(i)) + ...
                oldDiffToAdjustBy;
        end
    else
        movie_times(indsToFix(i):end) = ...
            movie_times(indsToFix(i):end) - diffToAdjustBy;
        movie_times(indsToFix(i)) = movie_times(indsToFix(i)) + ...
                oldDiffToAdjustBy;
    end
    oldDiffToAdjustBy = diffToAdjustBy;
end

% plot(movie_times);
%%
indsToFix = [];
for i = 2:length(label_times)
    if label_times(i) - label_times(i-1) > 2 || label_times(i) - label_times(i-1) < 0
        indsToFix = cat(1, indsToFix, i);
    end
end

diffToAdjustBy = 0;
for i = 1:length(indsToFix)
    
    newDiff = ...
        label_times(indsToFix(i)) - (label_times(indsToFix(i) - 1) + 2);
    diffToAdjustBy = diffToAdjustBy + newDiff;
%     disp(diffToAdjustBy);
    if i < length(indsToFix)
        label_times(indsToFix(i):indsToFix(i+1)) = ...
            label_times(indsToFix(i):indsToFix(i+1)) - diffToAdjustBy;
        if i > 1
            label_times(indsToFix(i)) = label_times(indsToFix(i)) + ...
                oldDiffToAdjustBy;
        end
    else
        label_times(indsToFix(i):end) = ...
            label_times(indsToFix(i):end) - diffToAdjustBy;
        label_times(indsToFix(i)) = label_times(indsToFix(i)) + ...
                oldDiffToAdjustBy;
    end
    oldDiffToAdjustBy = diffToAdjustBy;
end
% label_times(969:end) = label_times(969:end) + 102;
% label_times(231:end) = label_times(231:end) + 14;
plot(label_times);
%%
trEndTime = max(movie_times);

labelIndsToUse = (label_times <= trEndTime);
label_times = label_times(labelIndsToUse);
labels = labels(labelIndsToUse, :);
laggedLabels = laggedLabels(labelIndsToUse, :);

%%
indsToRemove = [];
for i = 1:length(label_times)
    
    if ~any(movie_times == label_times(i))
        disp(i);
        indsToRemove = cat(1, indsToRemove, i);
    end
end

label_times(indsToRemove) = [];
labels(indsToRemove,:) = [];
laggedLabels(indsToRemove,:) = [];

figure
plot(label_times)
hold on
plot(movie_times, 'r--');

%%
save ../../Data/fullData_1_run1_aligned.mat labels label_times laggedLabels unrolledData