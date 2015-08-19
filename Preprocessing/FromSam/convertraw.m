function convertraw(exp, usubs, varargin)

% function convertraw(usubs,varargin)
%
% converts data from dicom format using mri_convert

% directory setup
datadir = [params('rootdir') exp '/data/'];
fsl_version = read_fsl_version(exp,varargin{:});

for i = 1:length(usubs)
    
    runtypes = read_runtypes(exp, usubs(i), 'raw', varargin{:});
    if optInputs(varargin,'runtypes')
        runtypes = varargin{optInputs(varargin,'runtypes')+1};
    end
    
    for j = 1:length(runtypes)
        
        try
            [runnum dicomid scanid] = read_runs(exp,usubs(i),runtypes{j},varargin{:});
        catch
            keyboard
        end
        if optInputs(varargin,'runnum')
            x = varargin{optInputs(varargin,'runnum')+1};
            [~,xi] = intersect(runnum,x);
            runnum = runnum(xi);
            dicomid = dicomid(xi);
            scanid = scanid(xi);
        end
        
        for k = 1:length(runnum)
            
            fprintf('%s, sub %d, %s, run %d\n',exp,usubs(i),runtypes{j},runnum(k));
            
            niidir = [datadir 'brain/nifti/usub' num2str(usubs(i)) '/'];
            niifile = [niidir runtypes{j} '_r' num2str(runnum(k)) '.nii.gz'];
            if ~exist(niidir,'dir');
                mkdir(niidir);
            end
            
            dicomsdir = [datadir 'brain/dicoms/usub' num2str(usubs(i)) '_scan' num2str(scanid(k)) '/'];
            firstdicom = dir([dicomsdir '*-1-1*']);
            if length(firstdicom)~= 1;
                error('Error: problem reading first dicom file');
            end
            
            
            if ~strcmp('struct',runtypes{j})
                [~, ~, ~, ~, ~, ~, ~, ~, disdaqs] = read_scanparams(exp,usubs(i),runtypes{j},'run',runnum(k),varargin{:});
                if disdaqs > 0
                    disdaqdir = [dicomsdir 'disdaqs/'];
                    if ~exist(disdaqdir,'dir');
                        mkdir(disdaqdir);
                    end
                    for m = 1:disdaqs
                        dicomfile_old = [dicomsdir strrep(firstdicom.name, '-1-1', ['-' num2str(dicomid(k)) '-' num2str(m)])];
                        dicomfile_new = [disdaqdir strrep(firstdicom.name, '-1-1', ['-' num2str(dicomid(k)) '-' num2str(m)])];
                        if exist(dicomfile_old,'file')
                            unix(['mv ' dicomfile_old ' ' dicomfile_new]);
                        end
                    end
                end
            end
            
            dicomfile = [dicomsdir strrep(firstdicom.name, '-1-1', ['-' num2str(dicomid(k)) '-' num2str(disdaqs+1)])];
            if ~exist(niifile,'file') || optInputs(varargin, 'overwrite');
                fprintf(['mri_convert --in_type siemens_dicom --out_type nii '  dicomfile '  ' niifile '\n']);
                unix(['mri_convert --in_type siemens_dicom --out_type nii '  dicomfile '  ' niifile]);
            end
        end
    end
end