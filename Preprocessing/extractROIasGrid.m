function [ gridROI ] = extractROIasGrid( ROI, surface_rh, surface_lh, plotFig )
%extractROIasGrid Extracts the requested ROI from the surface images given
%by surface_rh and surface_lh (must provide full path) plotFig = 1 will
%plot some sanity check figures


% surface_rh = '/mindhive/nklab/u/svnh/fmri-analysis/test_data/rh.naturalsound_example_subject.mgz';
% surface_lh = '/mindhive/nklab/u/svnh/fmri-analysis/test_data/lh.naturalsound_example_subject.mgz';
% patch_rh = '/mindhive/nklab/u/svnh/freesurfer/fsaverage/surf/rh.cortex.patch.flat';
% patch_lh = '/mindhive/nklab/u/svnh/freesurfer/fsaverage/surf/lh.cortex2.patch.flat';
% roi_rh_label = '/mindhive/nklab/u/svnh/freesurfer/fsaverage/label/rh.stp.label';
% roi_lh_label = '/mindhive/nklab/u/svnh/freesurfer/fsaverage/label/lh.stp.label';

% TODO: figure out how to format patch/label files so that read_patch_SNH
% and read_label_SNH can read them

grid_spacing_mm = 2;

gridROI = interp_from_surface_to_grid(surface_rh, surface_lh, ...
    patch_rh, patch_lh, ...
    roi_rh_label, roi_lh_label, ...
    grid_spacing_mm, plotFig);

end

