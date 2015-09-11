% Plot error v num comps for both ICA and PCA
roi = 'rffa';

load(['../../Data/' roi '_compareClassAccs_circLag.mat']);

f = figure;
vox_avg = mean(errs_vox);
numComps = length(mean_pca);

plot(1:numComps, mean_ica, 'b');
hold on;
plot(1:numComps, mean_pca(1:numComps), 'r--');
line([1 numComps], [vox_avg vox_avg], 'Color', 'g');
line([1 numComps], [0.5 0.5], 'Color', 'k');
xlim([1 numComps]);
ylim([0.25 0.8]);
legend({'ICA', 'PCA', 'Voxels', 'Chance'}, 'FontSize', 20, 'Location', 'northeast');
xlabel('Number of Components', 'FontSize', 20);
ylabel('2v2 Classification Error', 'FontSize', 20);
title(roi, 'FontSize', 20);
set(gca, 'FontSize', 14);


saveas(f, ['../../Data/' roi '_errVcomp.pdf']);
