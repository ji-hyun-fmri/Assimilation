clear; clc;


subject_info  = 
nSub     = size(subject_info,1);

numSlice          = 72;
TR                = 2;
TA                = TR - (TR/numSlice);
if mod(numSlice,2)
    sliceorder     = [1:2:numSlice 2:2:numSlice];
    refslice       = 1;
else
    sliceorder     = [2:2:numSlice 1:2:numSlice];
    refslice       = 2;
end
numrun = 10;

%%%% Step 0: copy all files in 'postOrigin' -> 'preProc'
for sub = 
    sub_dir     = subject_info{sub,2};
    post_path   = fullfile(MRI_PATH,sub_dir,'postOrigin');
    proc_path   = fullfile(MRI_PATH,sub_dir,'preProc');
    fprintf('Step 0: Copying....\n');
    fprintf('%20s --> %20s\n', post_path, proc_path);
    
    post_file   = dir(fullfile(post_path, '*.nii'));
    post_file   = {post_file.name}';
    
    if   exist(proc_path,'dir'),   rmdir(proc_path,'s');
    end
    mkdir(proc_path);
    
    parfor f = 1:length(post_file)
        copyfile(fullfile(post_path,post_file{f}), fullfile(proc_path,post_file{f}));
        %         delete(fullfile(post_path,post_file{f}));
    end
    
end


for sub = 
    sub_dir     = subject_info{sub,2};
    disp(sub_dir);
    %%%%% Step 1: Realignment
    %%%%% Input files: [ arun1.nii  arun2.nii] (prefix: 'a')
    %%%%% output files:
    %%%%% 1) text files for the result realignment [ rp_arun1.txt rp_arun2.txt ]
    %%%%% 2) mat files [ arun1.mat arun2.mat ]
    %%%%% 3) realigned nifti files [ arun1.nii arun2.nii ] (updated!)
    %%%%% 4) mean files [ meanarun1.nii meanarun2.nii ]
    fprintf('Step 1: Realignment performing....\n');
    for run = 1:numrun
        run_dir        = fullfile(MRI_PATH,sub_dir,'preProc');
        if run<10;
            nii_file       = dir(fullfile(run_dir, ['run00' num2str(run,'%d') '*.nii']));
        elseif run==10
            nii_file       = dir(fullfile(run_dir, ['run0' num2str(run,'%d') '*.nii']));
        end
        nii_file       = nii_file.name;
        volumeInfo     = spm_vol(fullfile(run_dir,nii_file));
        numVolume      = length(volumeInfo);
        fprintf('Input file: % 50s\n', nii_file);
        clear filesToRealign
        clear matlabbatch
        for vol = 1:numVolume 
            filesToRealign{1}{vol}  = fullfile(run_dir, [nii_file ',' num2str(vol)]);
        end
        filesToRealign{1}    = filesToRealign{1}';
%         realign_file{run} = filesToRealign{1};
        matlabbatch{1}.spm.spatial.realign.estwrite.data = filesToRealign;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.quality = 0.9;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.sep = 4;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.fwhm = 5;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.rtm = 0;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.interp = 2;
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.realign.estwrite.eoptions.weight = '';
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.which = [2 1];
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.interp = 4;
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.wrap = [0 0 0];
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.mask = 1;
        matlabbatch{1}.spm.spatial.realign.estwrite.roptions.prefix = 'r';
        batch{sub}{run} = matlabbatch;
    end
end
parfor sub = 1:34
    for run=1:numrun
    fprintf('realign sub % d\n', sub);
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub}{run});
    end
end
clear batch;
for sub = 
    sub_dir     = subject_info{sub,2};
    disp(sub_dir);
    %%%%% Step 1: Slice Time
    %%%%% Input files:  [  run1.nii  run2.nii ]
    %%%%% ouptut files: [ arun1.nii arun2.nii ] (prefix: 'a')
    fprintf('Step 1: Slice Time performing....\n');
    filesToSliceTime  = cell(numrun,1);
    for run = 1:numrun;
        run_path       = fullfile(MRI_PATH,sub_dir,'preProc');
        if run<10;
            nii_file       = dir(fullfile(run_path, ['rrun00' num2str(run,'%d') '.nii']));
        elseif run==10
            nii_file       = dir(fullfile(run_path, ['rrun0' num2str(run,'%d') '.nii']));
        end
        nii_file       = nii_file.name;
        volumeInfo     = spm_vol(fullfile(run_path,nii_file));
        numVolume      = length(volumeInfo);
        fprintf('Input file: %50s\n', nii_file);
        for vol = 1:numVolume
            filesToSliceTime{run}{vol}    = fullfile(run_path,[nii_file ',' num2str(vol)]);
        end
        filesToSliceTime{run} = filesToSliceTime{run}';
    end
    clear matlabbatch;
    matlabbatch{1}.spm.temporal.st.scans      = filesToSliceTime;
    matlabbatch{1}.spm.temporal.st.nslices    = numSlice;
    matlabbatch{1}.spm.temporal.st.tr         = TR;
    matlabbatch{1}.spm.temporal.st.ta         = TA;
    matlabbatch{1}.spm.temporal.st.so         = sliceorder;
    matlabbatch{1}.spm.temporal.st.refslice   = refslice;
    matlabbatch{1}.spm.temporal.st.prefix     = 'a';
    batch{sub} = matlabbatch;
end
parfor sub = 1:34
    fprintf('slicetiming sub % d\n', sub);
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub});
end
clear batch;
for sub = 
    sub_dir     = subject_info{sub,2};
    disp(sub_dir);
    %%%%% Step 3: Coregistration
    %%%%% Input files : [ meanarun1.nii meanarun2.nii] + t1.nii
    %%%%%    Prior to this procecess, t1.nii must be copyed -> [run1t1.nii run2t1.nii]
    %%%%%    Because t1.nii will be modified after coregistration
    %%%%% Output: no new files but modified run1t1.nii run2t1.nii
    
    fprintf('Step 3: Coregistration performing....\n');
    anat_file      = dir(fullfile(MRI_PATH,sub_dir,'preProc','t1.nii'));
    anat_name      = anat_file.name;
    anat_name      = fullfile(MRI_PATH,sub_dir,'preProc',anat_name);
    
    for run = 1:numrun
        if run <10
            anat_run_file  = ['run00' num2str(run,'%d') anat_file.name];
        elseif run==10
            anat_run_file  = ['run0' num2str(run,'%d') anat_file.name];
        end
        anat_run_name  = fullfile(MRI_PATH,sub_dir,'preProc',anat_run_file);
        fprintf('copying...\n');
        fprintf('source: %40s\n', anat_name);
        fprintf('destination: %40s\n', anat_run_name);
        copyfile(anat_name,anat_run_name);
        if run < 10
            mean_nii_file  = dir(fullfile(MRI_PATH,sub_dir,'preProc',['meanrun00' num2str(run,'%d') '.nii']));
        elseif run == 10
            mean_nii_file  = dir(fullfile(MRI_PATH,sub_dir,'preProc',['meanrun0' num2str(run,'%d') '.nii']));
        end
        mean_nii_file  = mean_nii_file.name;
        mean_nii_file  = fullfile(MRI_PATH,sub_dir,'preProc',mean_nii_file);
        clear matlabbatch;
        matlabbatch{1}.spm.spatial.coreg.estimate.ref   = {mean_nii_file};
        matlabbatch{1}.spm.spatial.coreg.estimate.source = {anat_run_name};
        batch{sub}{run} = matlabbatch;
    end
end
parfor sub = 
    for run=1:numrun
    fprintf('slicetiming sub % d\n', sub);
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub}{run});
    end
end
clear batch;
for sub = 
    sub_dir     = subject_info{sub,2};
    disp(sub_dir);
    %%%%% Step 4: Segmentation
    %%%---------------------------------------------------------------------
    %%% Segment produces 5 new images:
    %%% c1* - grey matter
    %%% c2* - white matter
    %%% c3* - CSF, bone
    %%% c4* - soft tissue
    %%% c5* - air/background
    %%%---------------------------------------------------------------------
    %%%%% Input files : [ run1t1.nii run2t1.nii ] + [ arun1.nii arun2.nii ]
    %%%%% Output:
    %%%%% 1) [     run1t1_seg8.mat     run2t1_seg8.mat ]
    %%%%% 2) [  c[12345]run1t1.nii  c[12345]run2t1.nii ]
    %%%%% 3) [ rc[12345]run1t1.nii rc[12345]run2t1.nii ]
 fprintf('Step 4: Segmentation....\n');
    for run = 1:numrun
        if run<10
            anat_file      = dir(fullfile(MRI_PATH,sub_dir,'preProc',['run00' num2str(run,'%d'), 't1.nii']));
        elseif run==10
            anat_file      = dir(fullfile(MRI_PATH,sub_dir,'preProc',['run0' num2str(run,'%d'), 't1.nii']));
        end
        anat_name      = anat_file.name;
        anat_file      = fullfile(MRI_PATH,sub_dir,'preProc',anat_name);
        for c=1:5
            names{c} = fullfile(MRI_PATH,sub_dir,'preProc', ['c' num2str(c) anat_name]);
        end
        disp(anat_file);
        clear matlabbatch;

        matlabbatch{1}.spm.spatial.preproc.channel.vols = {anat_file};
        matlabbatch{1}.spm.spatial.preproc.channel.biasreg = 0.001;
        matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm = 60;
        matlabbatch{1}.spm.spatial.preproc.channel.write = [0 1];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).tpm = {'C:\Users\User\Desktop\jihyun\spm12\tpm/TPM.nii,1'};
        matlabbatch{1}.spm.spatial.preproc.tissue(1).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(1).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(1).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).tpm = {'C:\Users\User\Desktop\jihyun\spm12\tpm/TPM.nii,2'};
        matlabbatch{1}.spm.spatial.preproc.tissue(2).ngaus = 1;
        matlabbatch{1}.spm.spatial.preproc.tissue(2).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(2).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).tpm = {'C:\Users\User\Desktop\jihyun\spm12\tpm/TPM.nii,3'};
        matlabbatch{1}.spm.spatial.preproc.tissue(3).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(3).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(3).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).tpm = {'C:\Users\User\Desktop\jihyun\spm12\tpm/TPM.nii,4'};
        matlabbatch{1}.spm.spatial.preproc.tissue(4).ngaus = 3;
        matlabbatch{1}.spm.spatial.preproc.tissue(4).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(4).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).tpm = {'C:\Users\User\Desktop\jihyun\spm12\tpm/TPM.nii,5'};
        matlabbatch{1}.spm.spatial.preproc.tissue(5).ngaus = 4;
        matlabbatch{1}.spm.spatial.preproc.tissue(5).native = [1 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(5).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).tpm = {'C:\Users\User\Desktop\jihyun\spm12\tpm/TPM.nii,6'};
        matlabbatch{1}.spm.spatial.preproc.tissue(6).ngaus = 2;
        matlabbatch{1}.spm.spatial.preproc.tissue(6).native = [0 0];
        matlabbatch{1}.spm.spatial.preproc.tissue(6).warped = [0 0];
        matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
        matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
        matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
        matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
        matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
        matlabbatch{1}.spm.spatial.preproc.warp.write = [0 1];
        batch{sub}{run} = matlabbatch;
    end
end
parfor sub = 1:34
    for run=1:numrun
    fprintf('slicetiming sub % d\n', sub);
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub}{run});
    end
end
clear batch;
%%%%% Step 5: Normalization
%%%%% Input files : [ run1t1.nii run2t1.nii ] + [ arun1.nii arun2.nii ]
%%%%% Output:
%%%%% 1) [        y_run1t1.nii        y_run2t1.nii ]
%%%%% 2) [          warun1.nii          warun2.nii ]
%%%%% 3) [ wc[12345]run1t1.nii wc[12345]run2t1.nii ]
for sub = 
    sub_dir     = subject_info{sub,2};
    disp(sub_dir);
    for run = 1:numrun
        if run<10
            anat_file      = dir(fullfile(MRI_PATH,sub_dir,'preProc',['y_run00', num2str(run,'%d'),'t1.nii']));
        elseif run==10
            anat_file      = dir(fullfile(MRI_PATH,sub_dir,'preProc',['y_run0', num2str(run,'%d'),'t1.nii']));
        end
        anat_name      = anat_file.name;
        anat_file      = fullfile(MRI_PATH,sub_dir,'preProc',anat_name);
        disp(anat_file);
        
        if run<10
            nii_file       = dir(fullfile(MRI_PATH,sub_dir,'preProc',['arrun00' num2str(run,'%d') '.nii']));
        elseif run==10
            nii_file       = dir(fullfile(MRI_PATH,sub_dir,'preProc',['arrun0' num2str(run,'%d') '.nii']));
        end
        nii_name       = nii_file.name;
        nii_file       = fullfile(MRI_PATH,sub_dir,'preProc',nii_name);
        disp(nii_file);
        
        volumeInfo  = spm_vol(nii_file);
        numVolume   = length(volumeInfo);
        
        clear matlabbatch;
        matlabbatch{1}.spm.spatial.normalise.write.subj.def = {anat_file};
        matlabbatch{1}.spm.spatial.normalise.write.subj.resample = {nii_file};
        matlabbatch{1}.spm.spatial.normalise.write.woptions.bb = [-78 -112 -70; 78 76 85];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.vox = [2 2 2];
        matlabbatch{1}.spm.spatial.normalise.write.woptions.interp = 4;
        matlabbatch{1}.spm.spatial.normalise.write.woptions.prefix = 'w';
        batch{sub}{run} = matlabbatch;
    end
end
parfor sub =
    for run=1:numrun
    fprintf('slicetiming sub % d\n', sub);
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub}{run});
    end
end
clear batch
for sub = 
    sub_dir     = subject_info{sub,2};
    disp(sub_dir);
    %%%%% Step 6: Smoothing
    %%%%% Input files : [  warun1.nii  warun2.nii ]
    %%%%% Output files: [ swarun1.nii swarun2.nii ]
    for run = 1:numrun
        if run<10
            nii_file       = dir(fullfile(MRI_PATH,sub_dir,'preProc',['warrun00' num2str(run,'%d') '.nii']));
        elseif run==10
            nii_file       = dir(fullfile(MRI_PATH,sub_dir,'preProc',['warrun0' num2str(run,'%d') '.nii']));
        end
        nii_name       = nii_file.name;
        nii_file       = fullfile(MRI_PATH,sub_dir,'preProc',nii_name);
        
        volumeInfo     = spm_vol(fullfile(nii_file));
        numVolume      = length(volumeInfo);
        fprintf('Input file: % 50s\n', nii_file);
        
        clear matlabbatch;
        clear filesToSmooth;
        for vol = 1:numVolume
            filesToSmooth{vol}  = fullfile([nii_file ',' num2str(vol)]);
        end
        matlabbatch{1}.spm.spatial.smooth.data = filesToSmooth';
        matlabbatch{1}.spm.spatial.smooth.fwhm = [6 6 6];
        matlabbatch{1}.spm.spatial.smooth.dtype = 0;
        matlabbatch{1}.spm.spatial.smooth.im = 0;
        matlabbatch{1}.spm.spatial.smooth.prefix = 's';
        batch{sub}{run} = matlabbatch;
    end    
end
parfor sub = 
    for run=1:numrun
    fprintf('slicetiming sub % d\n', sub);
    spm('defaults','fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub}{run});
    end
end
