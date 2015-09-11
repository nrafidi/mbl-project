% Decompose and save both runs

addpath ./mutual-information-ICA/

K = 10;
hemiToUse = 1;

load(['../../Data/hemiData_' num2str(hemiToUse) '_run1.mat']);
run1Data = unrolledData;
load(['../../Data/hemiData_' num2str(hemiToUse) '_run2.mat']);
run2Data = unrolledData;

[Rica_run1, Wica_run1, Rpca_run1, Wpca_run1] = ...
    mutual_information_ICA(run1Data, K);

[Rica_run2, Wica_run2, Rpca_run2, Wpca_run2] = ...
    mutual_information_ICA(run2Data, K);

save ../../Data/icaComp_10_RH.mat Rica_run1 Wica_run1 Rpca_run1 Wpca_run1 ...
    Rica_run2 Wica_run2 Rpca_run2 Wpca_run2