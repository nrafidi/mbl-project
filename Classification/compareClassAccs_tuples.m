% Compare ICs, PCs, and raw voxel decoding
addpath ../MatrixFactor/


hemiToUse = 1;
ROI = 'hemiData_1';

fileStub = '../../Data/segment_';
fileStub = [fileStub ROI];

load([ fileStub '_run3.mat']);
run1Data = unrolledData;
voxelsToUse = size(unrolledData, 2);
load([ fileStub '_run5.mat']);
run1Data = (run1Data +  unrolledData)/2;
samplesToUse = size(run1Data, 1);
load ../../Data/labelsAndTimes_notEven.mat
laggedLabels = circshift(labels, 6);
run1Data = run1Data(:,1:voxelsToUse);

load([ fileStub '_run4.mat']);
run2Data = unrolledData;
load([ fileStub '_run6.mat']);
run2Data = (run2Data +  unrolledData)/2;

dataMatrix = (run1Data + run2Data)/2;

%Voxel Classification
% errs_vox = doSceneClassification(dataMatrix, laggedLabels, ...
%     movie_times, label_times);
% fprintf('Mean Voxel Error = %d\n', mean(errs_vox));

% findNumComponents_Corr(run1Data, run2Data);
[U, S, V] = svd(dataMatrix, 'econ');

numCompToTry = size(U, 2);
numCompToTuple = 10;
%%
% mean_pca = nan(numCompToTry, 1);
% for comp = 1:numCompToTry
%     R = U(:,1:comp)*S(1:comp,1:comp);
%     errs_pca_comp = doSceneClassification(R, laggedLabels, ...
%         movie_times, label_times);
%     mean_pca(comp) = mean(errs_pca_comp);
%     fprintf('Mean pca error = %d\n', mean_pca(comp));
%     
% end
% 
% save ../../Data/rh_compareClassAccs_circLag_full.mat  ...
%     mean_pca
%%
tuples = cell(numCompToTuple, 1);
numTuples = 0;
for i = 1:numCompToTuple
    tuples{i} = nchoosek(1:numCompToTuple, i);
    numTuples = numTuples + size(tuples{i}, 1);
end

errPerTuple = cell(numCompToTuple, 1);

for comp = 1:numCompToTuple
    tupleToUse = tuples{comp};
    errPerTuple{comp} = nan(size(tupleToUse,1),1);
    for t = 1:size(tupleToUse, 1)
        
        R = U(:,tupleToUse(t,:))*S(tupleToUse(t,:),tupleToUse(t,:));
        errs_pca_comp = doSceneClassification(R, laggedLabels, ...
            movie_times, label_times);
        errPerTuple{comp}(t) = mean(errs_pca_comp);
    end
end

save ../../Data/rh_compareClassAccs_circLag_tuples.mat  ...
    tuples errPerTuple

