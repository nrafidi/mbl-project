function [Rica, Wica, Rpca, Wpca] = getICAPCA(dataMatrix, run1Data, run2Data, varargin)
addpath /Users/nrafidi/Documents/MATLAB/MBL/Project/mbl-project/MatrixFactor/mutual-information-ICA/

if nargin > 3
    if ~isscalar(varargin{1})
        whichComps = varargin{1};
        numCompToUse = length(whichComps);
    else
        whichComps = 1:varargin{1};
        numCompToUse = varargin{1};
    end
    
else
    numCompToUse = findNumComponents_Corr(run1Data, run2Data);
    whichComps = 1:numCompToUse;
end

fprintf('Using %d components\n', numCompToUse);

[Rica, Wica, Rpca, Wpca] = ...
    mutual_information_ICA(dataMatrix, whichComps);

end