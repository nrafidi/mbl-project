function psc = roi_psc_surf(us, roi, test, loc, varargin)

% [psc testruns_used main_idstring] = roi_psc(s, testruntype, testmodel, masktype, roi, varargin)
% For anatomical + contrast: roi_psc(s, testruntype, testmodel, masktype, roi, locruntype, locmodel, contrast)
%
% Main function for computing the psc value for an roi. If loc and test runs are overlapping, uses leave-one-out style analysis.
% Specificy a subject, a test runtype (e.g. 'main', 'loc'), a test model (e.g. 'block' or 'event'), and then a type of mask: anat, anat_contrast, and cluster
%
% For anat you only need to specify an roi (needs to be updated)
% For cluster and anat_contrast, you need to specify an anatomical roi, a localizer contrast, a localizer runtype, & a localizer model (next two arguments respectively)
%
% Sample
% [psc testruns_used main_idstring] = roi_psc(1, 'main', 'block', 'anat_contrast', 'destrieux_pp', 'harm-highfreq_vs_noise-highfreq', 'localizer', 'block')
% roi_psc(1, 'main', 'block', 'anat', 'hvprob_pp', 'harm_vs_noise', 'main', 'block')

% 
% %% Directories, Parameters
% addpath(genpath('/software/Freesurfer/5.3.0/matlab'));
% 
% roidir = [params('rootdir') test.exp '/analysis/roi/'];
% if ~exist(roidir,'dir');
%     mkdir(roidir);
% end
% 
% % id string for this roi
% x = sprintf('%g-',roi.opval);
% roi_idstring = [roi.name '_' roi.op strrep(x(1:end-1),'.','p')];
% 
% allconds = read_conditions(test.exp, us, test.runtype, varargin{:});
% % id string for the test run
% test_idstring = [test.exp '_' test.runtype '_r' num2str(test.run) '_' test.model '_'  num2str(100*test.fwhm, '%.0f') 'mm' '_conds' sprintf('%d',find(ismember(allconds,test.conds)))];
% 
% % id string for localizer analysis
% if ~isempty(loc)
%     loc_idstring = [];
%     for i = 1:length(loc)
%         x = sprintf('%g-',loc(i).opval);
%         loc_idstring = [loc_idstring 'loc' num2str(i) '_' loc(i).exp '_' loc(i).runtype '_' loc(i).con '_' loc(i).sign  '_' loc(i).op '_' strrep(x(1:end-1),'.','p') '_r' sprintf('%d',loc(i).runs) '_' loc(i).model '_' num2str(100*loc(i).fwhm, '%.0f') 'mm']; %#ok<AGROW>
%     end
%     if length(loc)>1
%         loc_idstring = DataHash(loc_idstring);
%     end
%     loc_idstring = DataHash(loc_idstring);
% else
%     loc_idstring = 'anatomical';
% end
% 
% if optInputs(varargin, 'sort_surface_axis');
%     percrange = varargin{optInputs(varargin, 'sort_surface_axis')+1};
%     loc_idstring = [loc_idstring '_sort_surface_axis' num2str(percrange(1)) '-' num2str(percrange(2))];
% end

% second ROI to remove from the first roi
% roidisjoin = '';
% if optInputs(varargin,'roidisjoin');
%     roidisjoin = varargin{optInputs(varargin,'roidisjoin')+1};
%     roi_idstring = [roi_idstring '_disjoin_' roidisjoin];
% end

%%

addpath(genpath('/software/Freesurfer/5.3.0/matlab'));

roidir = [params('rootdir') test.exp '/analysis/roi_surf/'];
if ~exist(roidir,'dir');
    mkdir(roidir);
end

fsl_version = read_fsl_version(test.exp, varargin{:});

%% Signal Averaging Parameters if Used instead of Betas

sigav = false;
win = [NaN, NaN];
if optInputs(varargin,'sigav_timecourse') || optInputs(varargin,'sigav_plateau') || optInputs(varargin,'sigav_peaktime');
    sigav = true;
    [blockdur, nulldur, TR, TA, stimdur, stim2scan, win, ~,~,nullwin] = read_scanparams(test.exp, us, test.runtype); %#ok<ASGLU>
    
    % window
    %     stat_idstring = ['sigav_win' strrep(num2str(win(1)),'.','p') '-' strrep(num2str(win(end)),'.','p')];
    
    if isempty(nullwin) && optInputs(varargin,'nulltc')
        nullwin = win;
        %         stat_idstring = [stat_idstring '_nulltc'];
    elseif isempty(nullwin)
        nullwin = (TR:TR:nulldur-TR) + stim2scan;
        %         nullwin = (TR:TR:nulldur-TR) + stim2scan;
    end
end


%% Misc Setup

% string used to remember this specific analysis
main_idstring = ['psc_surf_hash-' DataHash({us, roi, test, loc, varargin})];

% initialize psc matrix
if sigav
    psc = nan(length(win), length(test.conds));
else
    psc = nan(length(test.conds),1);
end

if ~optInputs(varargin,'nowrite')
    fprintf('\nS%d, %s\n',us, roi.name);
    for i = 1:length(loc)
        fprintf('Localizer: %s, runs %s\n',loc(i).con, sprintf('%d ',loc(i).runs))
    end
    fprintf('Test: run %d\n', test.run);
end

if exist([roidir main_idstring '.mat'],'file') && ~optInputs(varargin,'overwrite')
    load([roidir main_idstring '.mat']);
    return;
end

%% Read in ROI and Localizer

if optInputs(varargin, 'monkey')
    label_rh = read_label_SNH([params('rootdir') 'freesurfer/' test.exp '_us' num2str(us) '/label/rh.' roi.name '.label']);
    label_lh = read_label_SNH([params('rootdir') 'freesurfer/' test.exp '_us' num2str(us) '/label/lh.' roi.name '.label']);
else
    label_rh = read_label_SNH([params('rootdir') 'freesurfer/fsaverage/label/rh.' roi.name '.label']);
    label_lh = read_label_SNH([params('rootdir') 'freesurfer/fsaverage/label/lh.' roi.name '.label']);
end

if optInputs(varargin, 'just-rh')
    label_lh.vnums = [];
end

if optInputs(varargin, 'just-lh')
    label_rh.vnums = [];
end

analysis_name = varargin{optInputs(varargin,'surf')+1};

if ~isempty(loc)
    
    clear loc_contrast_rh loc_contrast_lh;
    for i = 1:length(loc)
        
        if length(loc(i).runs) > 50
            run_string = ['_' num2str(length(loc(i).runs)) 'r-' num2str(loc(i).runs(1)) '-' num2str(loc(i).runs(end)) '_' DataHash(loc(i).runs)];
        else
            run_string = ['_r' sprintf('%d',loc(i).runs)];
        end
        
        if optInputs(varargin, 'monkey')
            sla_directory = [params('rootdir') 'freesurfer/' loc(i).exp '_us' num2str(us) '/sla_matlab/' loc(i).runtype run_string '/' analysis_name '/'];
            loc_contrast_rh(i) = MRIread([sla_directory 'rh.pstat_' loc(i).con '_random.mgz']);
            loc_contrast_lh(i) = MRIread([sla_directory 'lh.pstat_' loc(i).con '_random.mgz']);
        else
            if length(loc(i).runs) > 1
                sla_directory = [params('rootdir') 'freesurfer/fsaverage/sla_matlab/' loc(i).exp '_us' num2str(us) '/' loc(i).runtype run_string '/' analysis_name '/'];
                loc_contrast_rh(i) = MRIread([sla_directory 'rh.pstat_' loc(i).con '_random.mgz']);
                loc_contrast_lh(i) = MRIread([sla_directory 'lh.pstat_' loc(i).con '_random.mgz']);
            else
                fla_directory = [params('rootdir') 'freesurfer/fsaverage/fla_matlab/' loc(i).exp '_us' num2str(us) '/' loc(i).runtype run_string '/' analysis_name '/contrasts/'];
                loc_contrast_rh(i) = MRIread([fla_directory 'rh.pstat_' loc(i).con '.mgz']);
                loc_contrast_lh(i) = MRIread([fla_directory 'lh.pstat_' loc(i).con '.mgz']);
            end
        end
        
            
        % flip contrast if necessary
        switch loc(i).sign
            case 'pos'
            case 'neg'
                loc_contrast_rh(i).vol = -loc_contrast_rh(i).vol; %#ok<*AGROW>
                loc_contrast_lh(i).vol = -loc_contrast_lh(i).vol; %#ok<*AGROW>
            case 'abs'
                loc_contrast_rh(i).vol = abs(loc_contrast_rh(i).vol); %#ok<*AGROW>
                loc_contrast_lh(i).vol = abs(loc_contrast_lh(i).vol); %#ok<*AGROW>
            otherwise
                error('Bad sign');
        end
    end
end

%% Create Mask

% roi with operation applied, should probably be a binary operation, such as thresholding
% mask = roi_brain;
% mask.data = brainops(mask.data, roi.op, roi.opval);
% masksize = sum(mask.data(:));
% fprintf('Mask size: %d voxels, %.2f cubic mm\n',masksize,masksize*2.0833*2.0833*4.4);

% remove a second roi from the initial roi, should recheck code before using
% if ~isempty(roidisjoin)
%     error('Check this functionality before using.');
%     anatfile = [testfeat 'masks/' roidisjoin  '_func_func2highres_' func2highres  '_highres2standard_' highres2standard  '.nii.gz']; %#ok<UNRCH>
%     x = readmr(anatfile,'NOPROGRESSBAR');
%     y = brainops(x.data, roi_op, roi_opval);
%     mask.data(y==1) = 0;
% end

mask = zeros(size([loc_contrast_rh(1).vol(:); loc_contrast_lh(1).vol(:)]));
mask(label_rh.vnums+1) = 1;
mask(label_lh.vnums+1 + numel(loc_contrast_rh(1).vol)) = 1;
fprintf('Mask size: %d voxels\n',sum(mask(:)));

if ~isempty(loc)
    for i = 1:length(loc)
        locdata = [loc_contrast_rh(i).vol(:); loc_contrast_lh(i).vol(:)];
        locdata(~logical(mask)) = 0;
        mask = brainops(locdata,loc(i).op,loc(i).opval,sum(mask(:)));
        fprintf('Mask size: %d voxels\n',sum(mask(:)));
    end
end

% if ~isempty(loc2)
%     roimask = logical(mask.data);
%     mask.data = loc2_brain.data;
%     mask.data(~roimask) = -inf;
%     mask.data = brainops(mask.data,loc2_op,loc2_opval,masksize);
%     masksize = sum(mask.data(:));
%     fprintf('Mask size: %d voxels, %.2f cubic mm\n',masksize,masksize*2.0833*2.0833*4.4);
% end

%% Calculate PSC Values

% normalization factor
masknorm = sum(mask(:));

% 3) Calculate PSC values, either by signal averaging or using betas
if sigav
        
    error('Need to check implementation before using\n');
    fprintf('Reading functional data...\n');
    
    if optInputs(varargin, 'monkey')
        func_rh = MRIread([params('rootdir') 'freesurfer/' test.exp '_us' num2str(us) '/preprocess/' test.runtype '_r' num2str(test.run)  '/rh.brain_thresh_detrend1_smooth' num2str(10000*test.fwhm, '%.0f') 'mm.mgz']);
        func_lh = MRIread([params('rootdir') 'freesurfer/' test.exp '_us' num2str(us) '/preprocess/' test.runtype '_r' num2str(test.run)  '/lh.brain_thresh_detrend1_smooth' num2str(10000*test.fwhm, '%.0f') 'mm.mgz']);
    else
        func_rh = MRIread([params('rootdir') 'freesurfer/fsaverage/preprocess/' test.exp '_us' num2str(us) '/' test.runtype '_r' num2str(test.run)  '/rh.brain_thresh_detrend1_smooth' num2str(10000*test.fwhm, '%.0f') 'mm.mgz']);
        func_lh = MRIread([params('rootdir') 'freesurfer/fsaverage/preprocess/' test.exp '_us' num2str(us) '/' test.runtype '_r' num2str(test.run)  '/lh.brain_thresh_detrend1_smooth' num2str(10000*test.fwhm, '%.0f') 'mm.mgz']);
    end    
    
    %     funcbr = readmr( preproc_file, 'NOPROGRESSBAR' );
    func = [squeeze(func_rh.vol); squeeze(func_lh.vol)];
    funcmask = func .* (mask * ones(1,size(func,2)));
    
    % fixation based on response during null periods
    behavdat = read_timings(test.exp, us, test.runtype, test.run, test.model);
    x = behavdat.onsets(strcmp('NULL',behavdat.conds));
    y = repmat(x, 1, length(nullwin)) + repmat(nullwin, length(x), 1);
    z = round(y/TR) + 1;
    if any(abs(z(:) - (y(:)/TR + 1)) > 1e-3)
        fprintf('Error in roi_psc.m: index should be an integer\n');
        drawnow;
        keyboard;
    end
    
    if optInputs(varargin,'nulltc')
        onsets = behavdat.onsets(strcmp('NULL',behavdat.conds));
        % loop through each stimulus presentation/repetition
        nullmean_allreps = nan( length(nullwin), length(onsets) );
        for j = 1:length(onsets)
            x = round((onsets(j) + nullwin)/TR) + 1;%(onsets(j)/TR + 1) + (win(1)/TR : win(2)/TR);
            y = squeeze(sum(funcmask(:,x))) / masknorm;
  
            if any(isnan(y));
                error('signal average is nan for some reason');
            end
            nullmean_allreps(:,j) = y;
        end
        nullmean = nanmean(nullmean_allreps,2);
    else
        nullmean = squeeze(sumdims(funcmask(:,z(:)),1:2)) / (numel(z)*masknorm);
    end
    
    for i = 1:length(test.conds)
        onsets = behavdat.onsets(strcmp(test.conds{i},behavdat.conds));
        % loop through each stimulus presentation/repetition
        psc_allreps = nan( length(win), length(onsets) );
        for j = 1:length(onsets)
            x = round((onsets(j) + win)/TR) + 1;%(onsets(j)/TR + 1) + (win(1)/TR : win(2)/TR);
            if abs(x - ((onsets(j) + win)/TR + 1)) > 1e-3
                fprintf('Error in roi_psc.m: index should be an integer\n');
                drawnow;
                keyboar;
            end
            y = squeeze(sum(funcmask(:,x)))' / masknorm;
            if any(isnan(y));
                error('signal average is nan for some reason');
            end
            psc_allreps(:,j) = 100*((y-nullmean)./nullmean);
        end
        psc(:,i) = nanmean(psc_allreps,2);
    end
    
else
    
    %     % 2) Read in Mean Func
    %     nullbr = readmr([testfeat 'mean_func.nii.gz'],'NOPROGRESSBAR');
    %     nullmask = mask.data.*nullbr.data;
    %     nullmean = squeeze(sumdims(nullmask,1:3)/masknorm);
    %     if isnan(nullmean);
    %         fprintf(['fixation is nan.\n']); drawnow;
    %         keyboard;
    %     end
    %
    %
    %     % read in names of evs in the proper order
    %     fid = fopen([testfeat 'evname.txt'],'r');
    %     tmp = textscan(fid,'%s'); fclose(fid);
    %     evname = tmp{1};
    %     evs = test.conds;
    
    
    
    if optInputs(varargin, 'monkey')
        fla_directory = [params('rootdir') 'freesurfer/' test.exp '_us' num2str(us) '/fla_matlab/' test.runtype '_r' num2str(test.run) '/' analysis_name '/'];
    else
        fla_directory = [params('rootdir') 'freesurfer/fsaverage/fla_matlab/' test.exp '_us' num2str(us) '/' test.runtype '_r' num2str(test.run)  '/' analysis_name '/'];
    end
        
    psc_rh = MRIread([fla_directory 'rh.psc.mgz']);
    psc_lh = MRIread([fla_directory 'lh.psc.mgz']);
    
    psc_matrix = [squeeze(psc_rh.vol(1,:,1,1:length(test.conds)))', squeeze(psc_lh.vol(1,:,1,1:length(test.conds)))'];
    psc = 100*mean(psc_matrix(:,logical(mask)),2);
    
    if any(isnan(psc))
        fprintf('Error in roi_psc_surf: NaNs in psc measure.\n'); drawnow;
        keyboard;
    end
    
end

save([roidir main_idstring '.mat'],'psc');

%% Scraps
%
%
%     switch masktype
%
%         case {'anat'}
%
%             m2 = m1;
%
%         case {'anat_contrast', 'cluster'}
%
%             zstatfile = [testfeat 'slacontrasts/' locruntype '_' loc '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm.nii.gz'];
%             % register contrast, will not overwrite unless overwrite is specified in optional arguments
%             register_contrast(s,testruntype,r,testmodel,loc,locruntype,locruns,locmodel,varargin{:});
%
%             % read files
%             anatbr = readmr(anatfile,'NOPROGRESSBAR');
%             zstatbr = readmr(zstatfile,'NOPROGRESSBAR');
%
%             % flip contrast if necessary
%             if negcontrast;
%                 zstatbr.data = -zstatbr.data;
%             end
%
%             if ~isempty(ztopvoxel)
%
%                 m1inds = find(m1.data);
%                 [~,ztopinds] = zstatbr.data(m1inds);
%                 m2 = m1;
%                 m2.data = zeros(size(m1.data));
%                 m2.data(m1inds(ztopinds(1:ztopvoxels))) = 1;
%
%             else
%
%                 % weight zstatistic and truncate extreme values
%                 zpow = zstatbr.data.^zpower;
%                 zpow(zpow > 1e10) = 1e10;
%                 m2 = m1;
%                 m2.data = m1.data .* (zstatbr.data > zthresh) .* zpow;
%             end
%
%     end
%
%             end
%
%
%
%             if strcmp(masktype, 'anat')
%
%                 m2 = anatmaskbr;
%
%             elseif strcmp(masktype, 'anat_contrast');
%
%                 zstatfile = [testfeat 'slacontrasts/' locruntype '_' loc '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm.nii.gz'];
%
%                 % register contrast, will not overwrite unless overwrite is specified in optional arguments
%                 register_contrast(s,testruntype,r,testmodel,loc,locruntype,locruns,locmodel,varargin{:});
%
%                 % read files
%                 anatbr = readmr(anatfile,'NOPROGRESSBAR');
%                 zstatbr = readmr(zstatfile,'NOPROGRESSBAR');
%
%                 % flip contrast if necessary
%                 if negcontrast;
%                     zstatbr.data = -zstatbr.data;
%                 end
%
%                 if ~
%
%
%         case 'cluster'
%
%             % if test and localizer runtypes are the same, use left-over runs to localizer
%             % else use all of the localizer runs
%             if strcmp( testruntype, locruntype );
%                 locruns = setdiff(testruns,r);
%             else
%                 locruns = read_runs(s,locruntype);
%             end
%
%             fprintf('Localizer: %s, runs %s\n', locruntype, sprintf('%d ',locruns));
%
%             % contrast and anatomical file
%             clustfile = [testfeat 'masks/' roi '_' locruntype '_' loc '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm_z' strrep(num2str(zthresh),'.','') '_func_func2highres_' func2highres '.nii.gz'];
%             zstatfile = [testfeat 'slacontrasts/' locruntype '_' loc '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm.nii.gz'];
%
%             % register contrast, will not overwrite unless overwrite is specified in optional arguments
%             register_contrast(s,testruntype,r,testmodel,localizer,locruntype,locruns,locmodel,varargin{:});
%
%             % register contrast, will not overwrite unless overwrite is specified in optional arguments
%             register_cluster(roi,s,testruntype,r,testmodel,localizer,locruntype,locruns,locmodel,varargin{:});
%
%             if ~exist(clustfile,'file');
%                 fprintf('No cluster for this run.\n'); drawnow;
%                 continue;
%             end
%
%             % read files
%             clustbr = readmr(clustfile,'NOPROGRESSBAR');
%             zstatbr = readmr(zstatfile,'NOPROGRESSBAR');
%
%             % flip contrast if necessary
%             if negcontrast;
%                 zstatbr.data = -zstatbr.data;
%             end
%
%             % weight zstatistic and truncate extreme values
%             zpow = zstatbr.data.^zpower;
%             zpow(zpow > 1e10) = 1e10;
%
%             % weight anatomical mask and truncate extreme values
%             mpow = clustbr.data.^maskpower;
%             mpow(mpow > 1e10) = 1e10;
%
%             % threshold and weight
%             m2 = clustbr;
%             maskbr.data = mpow .* (zstatbr.data>zthresh) .* zpow;
%
%     end
%
%
%
%
%
%         case 'anat_contrast'  % anatomical ANDed with functional contrast
%
%             % if test and localizer runtypes are the same, use left-over runs to localizer
%             % else use all of the localizer runs
%             if strcmp( testruntype, locruntype );
%                 locruns = setdiff(testruns,r);
%             else
%                 locruns = read_runs(s,locruntype);
%             end
%
%             fprintf('Localizer: %s, runs %s\n', locruntype, sprintf('%d ',locruns));
%
%             % contrast and anatomical file
%             anatfile = [testfeat 'masks/' roi  '_func_func2highres_' func2highres  '_highres2standard_' highres2standard  '.nii.gz'];
%             zstatfile = [testfeat 'slacontrasts/' locruntype '_' localizer '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm.nii.gz'];
%
%             % register contrast, will not overwrite unless overwrite is specified in optional arguments
%             register_contrast(s,testruntype,r,testmodel,localizer,locruntype,locruns,locmodel,varargin{:});
%
%             % read files
%             anatbr = readmr(anatfile,'NOPROGRESSBAR');
%             zstatbr = readmr(zstatfile,'NOPROGRESSBAR');
%
%             % flip contrast if necessary
%             if negcontrast;
%                 zstatbr.data = -zstatbr.data;
%             end
%
%
%             % weight zstatistic and truncate extreme values
%             zpow = zstatbr.data.^zpower;
%             zpow(zpow > 1e10) = 1e10;
%
%             % weight anatomical mask and truncate extreme values
%             mpow = anatbr.data.^maskpower;
%             mpow(mpow > 1e10) = 1e10;
%
%             if ~isempty(masksize) % threshold anatomical by taking the best "masksize" number of voxels
%                 nvox = round(masksize/prod(funcdims));
%                 x = mpow(:);
%                 [maskvals, maskinds] = sort(x,'descend');
%                 if maskvals(nvox) == 0;
%                     error('Mask nvox is Too Big');
%                 end
%                 threshinds = zeros(size(maskinds));
%                 threshinds(maskinds(1:nvox)) = 1;
%                 mthresh = reshape(threshinds, size(anatbr.data));
%
%                 maskbr = anatbr;
%                 maskbr.data = mthresh .* (zstatbr.data>zthresh) .* zpow;
%             elseif ~isempty(maskthresh) % threshold based on some absolute value
%                 maskbr = anatbr;
%                 maskbr.data = (mpow > maskthresh).* (zstatbr.data>zthresh) .* zpow;
%             else % weighted mask
%                 maskbr = anatbr;
%                 maskbr.data = mpow .* (zstatbr.data>zthresh) .* zpow;
%             end
%
%         case 'cluster'
%
%             % if test and localizer runtypes are the same, use left-over runs to localizer
%             % else use all of the localizer runs
%             if strcmp( testruntype, locruntype );
%                 locruns = setdiff(testruns,r);
%             else
%                 locruns = read_runs(s,locruntype);
%             end
%
%             fprintf('Localizer: %s, runs %s\n', locruntype, sprintf('%d ',locruns));
%
%             % contrast and anatomical file
%             clustfile = [testfeat 'masks/' roi '_' locruntype '_' localizer '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm_z' strrep(num2str(zthresh),'.','') '_func_func2highres_' func2highres '.nii.gz'];
%             zstatfile = [testfeat 'slacontrasts/' locruntype '_' localizer '_r' sprintf('%d',locruns) '_' locmodel '_' params('smooth') 'mm.nii.gz'];
%
%             % register contrast, will not overwrite unless overwrite is specified in optional arguments
%             register_contrast(s,testruntype,r,testmodel,localizer,locruntype,locruns,locmodel,varargin{:});
%
%             % register contrast, will not overwrite unless overwrite is specified in optional arguments
%             register_cluster(roi,s,testruntype,r,testmodel,localizer,locruntype,locruns,locmodel,varargin{:});
%
%             if ~exist(clustfile,'file');
%                 fprintf('No cluster for this run.\n'); drawnow;
%                 continue;
%             end
%
%             % read files
%             clustbr = readmr(clustfile,'NOPROGRESSBAR');
%             zstatbr = readmr(zstatfile,'NOPROGRESSBAR');
%
%             % flip contrast if necessary
%             if negcontrast;
%                 zstatbr.data = -zstatbr.data;
%             end
%
%             % weight zstatistic and truncate extreme values
%             zpow = zstatbr.data.^zpower;
%             zpow(zpow > 1e10) = 1e10;
%
%             % weight anatomical mask and truncate extreme values
%             mpow = clustbr.data.^maskpower;
%             mpow(mpow > 1e10) = 1e10;
%
%             % threshold and weight
%             maskbr = clustbr;
%             maskbr.data = mpow .* (zstatbr.data>zthresh) .* zpow;
%
%     end

% The default type of mask is just a binary mask with a set threshold (default = 0.5)
% For non-binary masks, masks can be binarized by picking the top.
% You can also just weight voxels by their mask weight, raised to a power.
% The power can be used to emphasize voxels that better fit the roi.
% You can only use 1 of the 3 methods, not combinations.
% % threshold mask with a specific number, default
% roithresh = 0.5;
% if optInputs(varargin,'roithresh');
%     roithresh = varargin{optInputs(varargin,'roithresh')+1};
% end
% roi_idstring = ['roithresh' strrep(num2str(roithresh), '.', 'p')];
%
% % threshold mask by picking top masksize voxels
% roisize = [];
% if optInputs(varargin,'roisize');
%     roisize = varargin{optInputs(varargin,'roisize')+1};
%     roithresh = [];
%     roi_idstring = ['roisize' num2str(roisize)];
% end
%
% % default is to linearly weight localizer voxels by mask weight
% roipower = [];
% if optInputs(varargin,'roipower');
%     roipower = varargin{optInputs(varargin,'roipower')+1};
%     roisize = [];
%     roithresh = [];
%     roi_idstring = ['roipower' num2str(roipower)];
% end
%
% roidisjoin = '';
% if optInputs('roidisjoin');
%     roidisjoin = varargin{ptInputs('roidisjoin')+1};
%     roi_idstring = [roi_idstring '_disjoin_' roidisjoin];
% end

%
%
% % voxels above threshold from the localizer
% zthresh = params('zthresh');
% if optInputs(varargin,'zthresh');
%     zthresh = varargin{optInputs(varargin,'zthresh')+1};
% end
% zstr = ['zthresh' strrep(num2str(zthresh), '.', 'p')];
%
% % weight voxels z-stat of the localizer
% zpower = [];
% if optInputs(varargin,'zpower');
%     zpower = varargin{optInputs(varargin,'zpower')+1};
%     zthresh = [];
%     zstr = ['zpower' num2str(zpower)];
% end
%
% % select ztopvoxels with the highest z-stat from the localizer
% % requires a set mask threshold
% zvoxsort = [];
% if optInputs(varargin,'zvoxsort');
%     zvoxsort = varargin{optInputs(varargin,'zvoxsort')+1};
%     zthresh = [];
%     zpower = [];
%     zstr = ['zvoxsort' num2str(zvoxsort(1)) '-' num2str(zvoxsort(2))];
%     if ~isempty(roipower)
%         error('Selecting Top Localizer Voxels Requires a Binary Mask');
%     end
% end

% dimensions of functional image
% funcdims = [2.083, 2.083, 4.400];

% string used to remember contrast, not relevant if a contrast isn't specified
% if isempty(localizer)
%     loc_idstring = '';
% else
%     loc_idstring = ['loc_' ifelse(negcontrast,'neg-','') localizer '_' locruntype '_r' sprintf('%d',locruns) '_' locmodel];
% end


% % 4) Threshold or Weight the Localizer Data
% if isempty(localizer)
%
%     m2 = m1;
%
% elseif ~isempty(zthresh)
%
%     % binarize initial mask
%     m2 = m1;
%     m2.data = m1.data .* (loc.data > zthresh);
%
% elseif ~isempty(zvoxsort)
%
%     % threshold anatomical by taking the best "masksize" number of voxels
%     m1inds = find(m1.data > 0.5);
%     [~, zsortinds] = sort(loc.data(m1inds),'descend');
%
%     m2 = m1;
%     m2.data = zeros(size(m1.data));
%     m2.data(m1inds(zsortinds(zvoxsort(1):zvoxsort(2)))) = 1;
%
% elseif ~isempty(zpower)
%
%     m2 = m1;
%     m2.data = m1.data .* (loc.data .^ zpower);
%     m2.data(m2.data > 1e10) = 1e10;
%
% end
%
% if sumdims(m2.data,1:3)==0;
%     psc = NaN;
%     fprintf('Mask is empty.\n');
%     return;
% end




% 2) Threshold or Weight the Initial ROI
% if ~isempty(roithresh)
%
%
%     % binarize initial mask
%     m1 = roibr;
%     m1.data = roibr.data > roithresh;
%
% elseif ~isempty(roisize)
%
%     % threshold anatomical by taking the best "masksize" number of voxels
%     n = round(roisize/prod(funcdims));
%     [sortvals, sortinds] = sort(roibr.data(:),'descend');
%
%     if sortvals(n) == 0;
%         error('Mask nvox is Too Big');
%     end
%
%     m1 = roibr;
%     m1.data = zeros(size(roibr.data));
%     m1.data(sortinds(1:n)) = 1;
%
% else
%
%     m1 = roibr;
%     m1.data = roibr.data.^roipower;
%     m1.data(m1.data > 1e10) = 1e10;
%
% end





