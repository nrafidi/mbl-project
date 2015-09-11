function [errs, preds] = do2v2CrossValWinZ_cellX(X, Y, fname, doSave,...
    alg, doSub, doBias, unregBias, distMet)
%do2v2CrossValWinZ_cellX runs the 2 vs 2 test zscoring X within
% cross-validation folds. Returns a vector errs containing a 1 for each pair
% that was incorrect. preds contains predicted pair assignments

% X and Y are the data by which we learn the regression Y = X*W
% if doSave == 1, errs and preds will be saved to fname
% if alg == 0, kernel regression will be used (mine). if alg == 1,
% Gus' kernel regression will be used. if alg == 2, matlab's regress
% function will be used, and if alg == 3 lscov will be used
% if doSub  ~= 0, 1/doSub of the possible pairs (randomly sampled) will be used
% instead of all the pairs.
% if doBias == 1, a feature of 1s is added to X to learn a bias
% If unregBias == 1, my kernel regression code will not regularize the bias
% distMet indicates what distance metric to use, e.g. 'cosine'

N = length(Y);
pairs = combnk(1:N, 2);
nump = size(pairs, 1);
numtest = 2;

if doSub
    numpairs = floor(nump/doSub);
    subsamp = randsample(nump, numpairs);
else
    numpairs = nump;
end

printed = false;

wordvec = 1:N;
preds = zeros(numpairs, 2);
errs = zeros(numpairs, 1);
for j = 1:numpairs
    
    
    
    if doSub
        i = subsamp(j);
    else
        i = j;
    end
    
    tr = find(wordvec ~= pairs(i, 1) & wordvec ~= pairs(i, 2));
    X_tr = cell2mat(X(tr));
    Y_tr = cell2mat(Y(tr));
    
    [Xz_tr, mu, sig] = zscore(X_tr);
    
    if doBias && ~unregBias
        Xz_tr(:,end+1) = 1; %#ok<*AGROW>
    end
    
    if alg == 0
        tic
        [W,~]=kernel_reg_quick(Xz_tr, Y_tr,1,unregBias&doBias);
        toc
    elseif alg == 1
        W = regKernelLinearRegressionSeparateLambda(Xz_tr, Y_tr, 1);
    elseif alg == 2
        W = [];
        for t = 1:size(Y, 2)
            W = [W regress(Y(tr, t), Xz_tr)]; %#ok<*AGROW>
        end
    elseif alg == 3
        W = lscov(Xz_tr, Y_tr);
    end
    
    % Adjust the test sample
    
    
    d = zeros(numtest);
    
    for cur_word = 1:numtest
        X_ts = cell2mat(X(pairs(i, cur_word)));
        numSamp = size(X_ts, 1);
        testSample = (X_ts - ...
            repmat(mu, numSamp, 1))./repmat(sig, numSamp, 1);
        if doBias || alg == 1
            testSample(:,end+1) = 1;
        end
        targetEst = testSample*W;
        
        estToCompare = reshape(targetEst, 1, []);
        trueValue = reshape(cell2mat(Y(pairs(i, cur_word))), 1, []);
        falseValue = reshape(cell2mat(Y(pairs(i, 1:numtest ~= cur_word))), 1, []);
        
        d(cur_word, 1) = pdist([estToCompare; ...
            trueValue], distMet);
        d(cur_word, 2) = pdist([estToCompare; ...
            falseValue], distMet);
    end
    
    if (sum(targetEst(1,:) == targetEst(2,:)) == size(Y,2)) && ~printed
        fprintf('A hat and B hat are equal\n');
        printed = true;
    end
    if sum(d(:, 1), 1) == sum(d(:, 2), 1)
        fprintf('Wooops\n');
        if rand(1) > 0.5
            d(1,1) = d(1,1) + 1;
        else
            d(1,2) = d(1,2) + 1;
        end
    end
    if sum(d(:, 1), 1) > sum(d(:, 2), 1)
        errs(j) = 1;
        preds(j, 1) = pairs(i, 2);
        preds(j, 2) = pairs(i, 1);
    else
        preds(j, 1) = pairs(i, 1);
        preds(j, 2) = pairs(i, 2);
    end
    
end

% fprintf('Average error = %d\n', mean(errs));
if doSave
    save(fname,'preds', 'errs');
end

end