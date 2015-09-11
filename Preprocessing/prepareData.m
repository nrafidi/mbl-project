function [unrolledData, movie_times] = prepareData(hemiToProcess, ROI, runNum) %#ok<*STOUT>
% Prepare data as requested
% hemiToProcess: 1 = right, 2 = left, 3 = both;
% ROI = 'rffa', 'rppa'
load(['../../Data/movie_segment_run' num2str(runNum) '_norm_grid.mat']); % produces data and movie_times
load(['../../Data/' ROI '_grid.mat']);
numTimePoints = length(movie_times); %#ok<*USENS>

if hemiToProcess < 3
    unrolledData = unRolDeNan(data{hemiToProcess}, numTimePoints);
else
    unrolledData = [];
    for i = 1:2
        unrolledData = cat(2, unrolledData, ...
            unRolDeNan(data{hemiToProcess}, numTimePoints));
    end
end

roiInd = grid_roi_thresh{hemiToProcess};
roiInd(isnan(roiInd)) = 0;
roiInd = logical(reshape(roiInd, 1, []));

unrolledData = unrolledData(:,roiInd);

save(['../../Data/segment_' ROI '_run' num2str(runNum) '.mat'], 'unrolledData', 'movie_times');

end

function [newHemiData] = unRolDeNan(hemiData, numTimePoints)

hemiData = permute(hemiData, [3 1 2]);
hemiData = reshape(hemiData, numTimePoints, []);

newHemiData = hemiData;

% for t = 1:numTimePoints
% %     timePoint = hemiData(t, ~isnan(hemiData(t,:)));
%     newHemiData = cat(1, newHemiData, timePoint);
% end

end