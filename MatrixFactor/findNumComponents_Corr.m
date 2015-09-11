function [ numComponents ] = findNumComponents_Corr(run1Data, run2Data)
%findNumComponents_Corr Calculates number of PCs based on correlation with
%second run of data. Plots the correlation as a function of components

numVoxels = size(run1Data, 2);

numTimePoints = size(run1Data, 1);

run1Data = run1Data(:,1:numVoxels);
run2Data = run2Data(:,1:numVoxels);

meanToSubtract = mean([run1Data; run2Data], 1);
run1Data = run1Data - repmat(meanToSubtract, numTimePoints, 1);
run2Data = run2Data - repmat(meanToSubtract, numTimePoints, 1);

[U,S, V] = svd(run1Data,'econ');

base_corr = diag(corr(run1Data, run2Data));
numCompToTry = min([size(S, 1), 150]);
corrPerComp_run1run2 = nan(numCompToTry, numVoxels);
% corrPerComp_run2run2 = nan(numCompToTry, numVoxels);
h = waitbar(0, 'Calculating Correlations per component');
for k = 1:numCompToTry
    waitbar(k/numCompToTry, h);
%     tic
    projRun1 = U(:,1:k) * S(1:k,1:k) * V(:, 1:k)';
%     toc
    
%     tic
%     R = U(:,1:k) * S(1:k,1:k);
%     projMatrix = R*((R'*R)\R');    
%     projRun2 = projMatrix*run2Data;
%     toc
    
    corrPerComp_run1run2(k, :) = diag(corr(projRun1, run2Data));
%     corrPerComp_run2run2(k, :) = diag(corr(projRun2, run2Data));
%     fprintf('(%d, %d)\n', k, median(corrPerComp(k,:)));
end
close(h);

medCorr_run1run2 = median(corrPerComp_run1run2, 2);
medBase = median(base_corr);
f = figure;
scatter(1:numCompToTry, medCorr_run1run2);
hold on;
line([0 (numCompToTry + 1)], [medBase medBase])
ylim([0 0.1]);
xlabel('Component')
ylim([(min(medCorr_run1run2)-0.001) (max(medCorr_run1run2)+0.001)]);
title('Correlation vs Number of components in reconstruction');
ylabel(sprintf('Median correlation across voxels'));
legend({'Between reconstructed R1 and R2', 'Between R1 and R2'}, 'Location', 'SouthEast');

% saveas(f, '../../Data/CorrVComp_RH_segment_avg_R1R2.png');


% medCorr_run2run2 = median(corrPerComp_run2run2, 2);
% % medBase = median(base_corr);
% f = figure;
% scatter(1:numCompToTry, medCorr_run2run2);
% hold on;
% % line([0 (numCompToTry + 1)], [medBase medBase])
% ylim([0 0.1]);
% xlabel('Component')
% ylim([(min(medCorr_run2run2)-0.001) (max(medCorr_run2run2)+0.001)]);
% title('Correlation vs Number of components in reconstruction');
% ylabel(sprintf('Median correlation across voxels'));
% legend({'Between Projected R2 and R2'}, 'Location', 'SouthEast');
% 
% saveas(f, '../../Data/CorrVComp_RH_segment_avg_R2R2.png');


[~, numComponents] = max(medCorr_run1run2);

% save ../../Data/corrPerComp_segment_avg_run1run2.mat corrPerComp_run1run2  base_corr

end

