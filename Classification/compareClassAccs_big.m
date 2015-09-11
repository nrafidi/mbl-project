% Compare ICs, PCs, and raw voxel decoding
addpath ../MatrixFactor/


hemiToUse = 1;

fileStub = '../../Data/segment_';

fileStub = [fileStub 'hemiData_' num2str(hemiToUse)];


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

% Using the number of components determined by correlation
% numComponents = findNumComponents_Corr(run1Data, run2Data);
numCompToTry = 100;
[U,S, V] = svd(dataMatrix,'econ');

% Determining the number of components using classification accuracy
%%
Rpca_comp = cell(numCompToTry, 1);
Wpca_comp = cell(numCompToTry, 1);
errs_pca_comp = cell(numCompToTry, 1);
mean_pca = nan(numCompToTry, 1);
for comp = 1:numCompToTry
        Rpca_comp{comp} = U(:,1:comp)*S(1:comp,1:comp);
        Wpca_comp{comp} = V(:,1:comp)';
        errs_pca_comp{comp} = doSceneClassification(Rpca_comp{comp}, laggedLabels, ...
            movie_times, label_times);
        mean_pca(comp) = mean(errs_pca_comp{comp});
        fprintf('Mean pca error = %d\n', mean_pca(comp));
    
end

save ../../Data/rh_compareClassAccs_circLag.mat  ...
     errs_pca_comp ...
     Rpca_comp Wpca_comp  mean_pca