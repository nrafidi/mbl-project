% Generate ridge regression weights from trainingData to trainingTargets
% traininTargets = trainingData*weightMatrix
% Input:
% trainingData: samples x features matrix of training samples
% traininTargets: samples x outputs  matrix of outputs
% fCrossValidate: set to 1 to have it choose lambda (ridge penalty weight)
% by cross-validation
% unregBias: set to 1 to add extra bias term (not recommended)
% Outputs:
% weightMatrix: weight matrix to map from trainingData to trainingTargets
% r: vector of lambda values (one for each feature of trainingData)
% Sample Usage:
% weights = kernel_reg(brainData, semVec, 1, 0);
% estimate = testData*weights

function [weightMatrix, r] = kernel_reg(trainingData, trainingTargets, fCrossValidate, unregBias)

numTargetDimensions = size(trainingTargets,2);
numExamples = size(trainingData,1);

% If we're not regularizing the bias (by adding a column of 1's to training
% Data), then we compute it the Hastie way:
if unregBias
    b0 = mean(trainingTargets);
    trainingTargets = trainingTargets - repmat(b0,numExamples,1);
end


params = [.0000001 .000001 .00001 .0001 .001 .01 .1 .5 1 5 10 50 100 500 1000 10000 20000 50000 ...
    100000 500000 1000000 5000000 10000000];
n_params = length(params);

CVerr = zeros(n_params, numTargetDimensions);

if (fCrossValidate==1)
    
    % If we do an eigendecomp first we can quickly compute the inverse for many different values
    % of lambda. SVD uses X = UDV' form.
    % First compute K0 = (XX' + lambda*I) where lambda = 0.
    K0 = trainingData*trainingData';
    %     try
    [U,D,V] = svd(K0);
    %     catch
    %         keyboard;
    %     end
    
    for i = 1:length(params)
        regularizationParam = params(i);
        %fprintf('CVLoop: Testing regularation param: %f,\n', regularizationParam);
        
        % Now we can obtain Kinv for any lambda doing Kinv = V * (D + lambda*I)^-1 U'
        dlambda = D + regularizationParam*speye(size(D));
        dlambdaInv = diag(1 ./ diag(dlambda));
        KlambdaInv = V * dlambdaInv * U';
        
        % Compute pseudoinverse of linear kernel.
        KP = trainingData' * KlambdaInv;
        
        % Compute S matrix of Hastie Trick X*KP
        S = trainingData * KP;
        %
        %         if isempty(trainingTargets);
        %             keyboard;
        %         end
        %
        % Solve for weight matrix so we can compute residual
        weightMatrix = KP * trainingTargets;
        
        %         if isempty(trainingTargets);
        %             keyboard;
        %         end
        
        Snorm = repmat(1 - diag(S), 1, numTargetDimensions);
        YdiffMat = (trainingTargets - (trainingData*weightMatrix));
        YdiffMat = YdiffMat ./ Snorm;
        CVerr(i,:) = (1/numExamples).*sum(YdiffMat .* YdiffMat);
    end
    
    [~, minerrIndex] = min(mean(CVerr, 2));
    r = params(minerrIndex);
    
    % got good param, now obtain weights
    dlambda = D + r*speye(size(D));
    dlambdaInv = diag(1 ./ diag(dlambda));
    KlambdaInv = V * dlambdaInv * U';
    
    % Solve for weight matrix so we can compute residual
    weightMatrix = trainingData' * KlambdaInv * trainingTargets;
    
    %     % try using min of avg err
    
    %     r=zeros(1,numTargetDimensions);
    %     for cur_targ = 1:numTargetDimensions,
    %         regularizationParam = params(minerrIndex(cur_targ));
    %         r(cur_targ) = regularizationParam;
    %
    %         % got good param, now obtain weights
    %         dlambda = D + regularizationParam*speye(size(D));
    %         dlambdaInv = diag(1 ./ diag(dlambda));
    %         KlambdaInv = V * dlambdaInv * U';
    %
    %         % Solve for weight matrix so we can compute residual
    %         weightMatrix(:,cur_targ) = trainingData' * KlambdaInv * trainingTargets(:,cur_targ);
    %     end
    
else
    
    % The exact same code with no cross-validation to choose lambda
    K0 = trainingData*trainingData';
    [U,D,V] = svd(K0);
    regularizationParam = fCrossValidate;
    r = regularizationParam;
    for cur_targ = 1:numTargetDimensions,
        dlambda = D + regularizationParam*speye(size(D));
        dlambdaInv = diag(1 ./ diag(dlambda));
        KlambdaInv = V * dlambdaInv * U';
        
        % Solve for weight matrix so we can compute residual
        weightMatrix(:,cur_targ) = trainingData' * KlambdaInv * trainingTargets(:,cur_targ); %#ok<*AGROW>
    end
end

if unregBias
    weightMatrix(end+1,:) = b0;
end

end

