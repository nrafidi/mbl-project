load ../../Data/hrf.mat
load ../../Data/labelsAndTimes_notEven.mat

[numTime, numOutputs] = size(labels);

laggedLabels = nan(numTime, numOutputs);
hrf = hrf(1:2:end);

for i = 1:numOutputs
    laggedLabels(:,i) = conv(labels(:,i), hrf, 'same');
end

save ../../Data/laggedLabelsAndTimes_notEven_fixed.mat laggedLabels label_times