function [errs, preds, dists] = do2v2CrossValNoZ(X, Y, fname, doSave, alg, doSub, ...
    doBias, distMet)
%do2v2CrossValNoZ runs the 2 vs 2 test without zscoring within
% cross-validation folds. Returns a vector errs containing a 1 for each pair
% that was incorrect. preds contains the words that were used during each
% pair. dists allows you to check the calculated distance between each pair

% X and Y are the data by which we learn the regression Y = X*W
% if doSave == 1, errs and preds will be saved to fname
% if alg == 0, kernel regression will be used (mine). if alg == 1,
% Gus' kernel regression will be used. if alg == 2, matlab's regress
% function will be used, and if alg == 3 lscov will be used
% if doSub  ~= 0, 1/doSub of the possible pairs (randomly sampled) will be used
% instead of all the pairs.
% if doBias == 1, a feature of 1s is added to X to learn a bias
% distMet indicates what distance metric to use, e.g. 'cosine'

N = size(Y, 1);

if doBias 
    X(:,end+1) = 1;
end

numtest = 2;
pairs = combnk(1:N, numtest);
nump = size(pairs, 1);

if doSub
    numpairs = floor(nump/doSub);
    subsamp = randsample(nump, numpairs);
else
    numpairs = nump;
end

printed = false;

wordvec = 1:N;
preds = zeros(numpairs, 2);
errs = -1*ones(numpairs, 1);
dists = zeros(numpairs, 2);
for j = 1:numpairs
    
    if doSub
        i = subsamp(j);
    else
        i = j;
    end
    
    tr = find(wordvec ~= pairs(i, 1) & wordvec ~= pairs(i, 2));
    
    
    if alg == 0
        % myKernal, reg Bias
        [W,~]=kernel_reg(X(tr,:), Y(tr,:),1,0);
    elseif alg == 1
        W = regKernelLinearRegressionSeparateLambda(X(tr,:), Y(tr,:), 1);
    elseif alg == 2
        W = [];
        for t = 1:size(Y, 2)
            W = [W regress(Y(tr, t), X(tr,:))]; %#ok<*AGROW>
        end
    elseif alg == 3
        W = lscov(X(tr,:), Y(tr,:));
    end
    
    
    d = zeros(numtest);
    testSamples = X(pairs(i, :),:);
    targetEst = testSamples*W;
    for cur_word = 1:numtest
        d(cur_word, 1) = pdist([targetEst(cur_word, :); ...
            Y(pairs(i, cur_word), :)], distMet); 
        d(cur_word, 2) = pdist([targetEst(cur_word, :); ...
            Y(pairs(i, 1:numtest ~= cur_word), :)], distMet); 
    end
    
    
    % The first column of d is the correct match, and the second is
    % incorrect
    if (sum(targetEst(1,:) == targetEst(2,:)) == size(Y,2)) && ~printed
        fprintf('A hat and B hat are equal\n');
        printed = true;
    end
    if sum(d(:, 1), 1) == sum(d(:, 2), 1)
%         fprintf('Wooops\n');
        if rand(1) > 0.5
            d(1,1) = d(1,1) + 1;
        else
            d(1,2) = d(1,2) + 1;
        end
    end
    dists(j, 1) = sum(d(:, 1), 1);
    dists(j,2) = sum(d(:, 2), 1);
    if sum(d(:, 1), 1) > sum(d(:, 2), 1)
        errs(j) = 1;
        preds(j, 1) = pairs(i, 2);
        preds(j, 2) = pairs(i, 1);
    else
        errs(j) = 0;
        preds(j, 1) = pairs(i, 1);
        preds(j, 2) = pairs(i, 2);
    end
    
end

if doSave
    save(fname,'preds', 'errs');
end

end