% Compare ICs, PCs, and raw voxel decoding
addpath ../MatrixFactor/


hemiToUse = 1;
ROI = 'rsts';

fileStub = '../../Data/segment_';
if exist('ROI', 'var')
    fileStub = [fileStub ROI];
else
    fileStub = [fileStub 'hemiData_' num2str(hemiToUse)];
end

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
errs_vox = doSceneClassification(dataMatrix, laggedLabels, ...
    movie_times, label_times);
fprintf('Mean Voxel Error = %d\n', mean(errs_vox));
% errs_vox = .5;

% Using the number of components determined by correlation
[Rica, Wica, Rpca, Wpca] = getICAPCA(dataMatrix, run1Data, run2Data);
errs_ica_corr = doSceneClassification(Rica, laggedLabels, ...
    movie_times, label_times);
errs_pca_corr = doSceneClassification(Rpca, laggedLabels, ...
    movie_times, label_times);
fprintf('Mean Correlation-based Error, ICA = %d\n', mean(errs_ica_corr));
fprintf('Mean Correlation-based Error, PCA = %d\n', mean(errs_pca_corr));

% Determining the number of components using classification accuracy
numCompToTry = 10;%100;%size(Rica, 2) + 5;
Rica_comp = cell(numCompToTry, 1);
Wica_comp = cell(numCompToTry, 1);
Rpca_comp = cell(numCompToTry, 1);
Wpca_comp = cell(numCompToTry, 1);
errs_ica_comp = cell(numCompToTry, 1);
errs_pca_comp = cell(numCompToTry, 1);
mean_ica = nan(numCompToTry, 1);
mean_pca = nan(numCompToTry, 1);
for comp = 1:numCompToTry
    if comp ~= size(Rica, 2)
        [Rica_comp{comp}, Wica_comp{comp}, Rpca_comp{comp}, Wpca_comp{comp}] = ...
            getICAPCA(dataMatrix, [], [], comp);
        errs_ica_comp{comp} = doSceneClassification(Rica_comp{comp}, laggedLabels, ...
            movie_times, label_times);
        mean_ica(comp) = mean(errs_ica_comp{comp});
        fprintf('Mean ica error = %d\n', mean_ica(comp));
        errs_pca_comp{comp} = doSceneClassification(Rpca_comp{comp}, laggedLabels, ...
            movie_times, label_times);
        mean_pca(comp) = mean(errs_pca_comp{comp});
        fprintf('Mean pca error = %d\n', mean_pca(comp));
    else
        Rica_comp{comp} = Rica;
        Wica_comp{comp} = Wica;
        Rpca_comp{comp} = Rpca;
        Wpca_comp{comp} = Wpca;
        errs_ica_comp{comp} = errs_ica_corr;
        errs_pca_comp{comp} = errs_pca_corr;
        
        mean_ica(comp) = mean(errs_ica_comp{comp});
        fprintf('Mean ica error = %d\n', mean_ica(comp));
        
        mean_pca(comp) = mean(errs_pca_comp{comp});
        fprintf('Mean pca error = %d\n', mean_pca(comp));
    end
    
end

save ../../Data/rppa_compareClassAccs_circLag.mat errs_vox errs_ica_corr ...
    errs_ica_comp errs_pca_corr errs_pca_comp Rica Rica_comp Wica Wica_comp ...
    Rpca Rpca_comp Wpca Wpca_comp mean_ica mean_pca