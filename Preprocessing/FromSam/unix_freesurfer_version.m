function unix_freesurfer_version(freesurfer_version, command)

setupstr = ['export FREESURFER_HOME=/software/Freesurfer/' freesurfer_version  '; source ${FREESURFER_HOME}/SetUpFreeSurfer.sh; export SUBJECTS_DIR=~/freesurfer; '];
unix([setupstr command]);