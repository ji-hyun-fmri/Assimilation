clear; clc;
RAW_PATH       = 
MRI_PATH       = 

subject_info  = {
    
    };

nSub     = length(subject_info);

dir_list       = dir(RAW_PATH);
dir_name       = {dir_list.name}';
dir_idx        = cell2mat(cellfun(@(x) ~contains(x,'.') & length(x)>=2, dir_name,'uniformoutput',0));
dir_name       = dir_name(dir_idx,:);
nSub           = length(dir_name);

dir1_tag       = 'HEAD_PI_';
dir2_tag       = 'Task';
t1_tag         = 'T1_';


%%%% Step 0: IMA (move directory: RAW_PATH -> MRI_PATH)%
for sub = 
    %    sub_dir     = dir_name{sub};
    sub_dir     = subject_info{sub,2};
    dir1_list   = dir(fullfile(RAW_PATH,sub_dir));
    dir1_name   = {dir1_list.name}';
    mri_idx     = cell2mat(cellfun(@(x) contains(x,'HEAD_PI_'), dir1_name,'uniformoutput',0));
    mri_dir     = dir1_name(mri_idx);
    mri_dir     = mri_dir{1};
    
    fprintf('Subject %02d: %10s\n', subject_info{sub,1}, sub_dir);
    %%%%% mri_dir  = [... / 'Head_PI_OTHERS_ ...]'
    
    
    
    %%%%% T1 images
    dir2_list   = dir(fullfile(RAW_PATH,sub_dir,mri_dir));
    dir2_name   = {dir2_list.name}';
    t_idx       = cell2mat(cellfun(@(x) contains(x,'T1_'), dir2_name,'uniformoutput',0));
    t1_dir      = dir2_name(t_idx);
    t1_dir      = t1_dir{1};
    t1_list     = dir(fullfile(RAW_PATH,sub_dir,mri_dir,t1_dir));
    t1_name     = {t1_list.name}';
    t1_idx      = cell2mat(cellfun(@(x) contains(x,'.IMA'), t1_name,'uniformoutput',0));
    numT1       = sum(t1_idx);
    if numT1 ~= 192
        error('ERROR: # of T1');
    end
    t1_name     = t1_name(t1_idx);
    src_t1_dir  = fullfile(RAW_PATH,sub_dir,mri_dir,t1_dir);
    dest_t1_dir = fullfile(MRI_PATH,sub_dir,'preOrigin','T1');
    if ~exist(dest_t1_dir,'dir'), success   = mkdir(dest_t1_dir);
    end
    
    
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% SPM BATCH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    clear matlabbatch
    spm('defaults','fmri');
    spm_jobman('initcfg');
    fprintf('[========\nConverting DICOMs from folders:');
    matlabbatch{1}.spm.util.import.dicom.root    = 'flat';
    matlabbatch{1}.spm.util.import.dicom.data    = fullfile(src_t1_dir,t1_name);
    matlabbatch{1}.spm.util.import.dicom.outdir  = {dest_t1_dir};
    matlabbatch{1}.spm.util.import.dicom.convopts.format = 'nii';
    matlabbatch{1}.spm.util.import.dicom.convopts.meta = 0;
    matlabbatch{1}.spm.util.import.dicom.convopts.icedims = 0;
    spm_jobman('run',matlabbatch);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% SPM BATCH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%%% EPI images
    dir2_list   = dir(fullfile(RAW_PATH,sub_dir,mri_dir));
    dir2_name   = {dir2_list.name}';
    s_idx       = cell2mat(cellfun(@(x) contains(x,'TASK'), dir2_name,'uniformoutput',0));
    s_dir       = dir2_name(s_idx);
    
    k  = 1;
    run_dir     = {};
    for s2 = 1:length(s_dir)
        s2_dir      = s_dir{s2};
        dir3_list   = dir(fullfile(RAW_PATH,sub_dir,mri_dir,s2_dir));
        dir3_name   = {dir3_list.name}';
        ima_idx     = cell2mat(cellfun(@(x) contains(x,'.IMA'), dir3_name,'uniformoutput',0));
        numIMA      = sum(ima_idx);
        if  s2==1
            run_dir{length(s_dir)}     = s2_dir;
        else
            run_dir{s2-1} = s2_dir;
        end
    end
    %%%% run_dir = [ .../ 1_ILLUSION_EP2D ...']
    
    clear matlabbatch
    for s3 = 1:length(run_dir)
        s3_dir         = run_dir{s3};
        dir4_list      = dir(fullfile(RAW_PATH,sub_dir,mri_dir,s3_dir));
        dir4_name      = {dir4_list.name}';
        ima_idx        = cell2mat(cellfun(@(x) contains(x,'.IMA'), dir4_name,'uniformoutput',0));
        ima_name       = dir4_name(ima_idx);
        src_img_dir    = fullfile(RAW_PATH,sub_dir,mri_dir,s3_dir);
        if s3<10
            dest_img_dir   = fullfile(MRI_PATH, sub_dir, 'preOrigin', ['run00' num2str(s3,'%d')]);
        elseif s3==10
            dest_img_dir   = fullfile(MRI_PATH, sub_dir, 'preOrigin', ['run0' num2str(s3,'%d')]);
        end
        if ~exist(dest_img_dir,'dir'), mkdir(dest_img_dir);
            %else,                delete([dest_img_dir '/*']);
        end
        matlabbatch{s3}.spm.util.import.dicom.root    = 'flat';
        matlabbatch{s3}.spm.util.import.dicom.data    = fullfile(src_img_dir,ima_name);
        matlabbatch{s3}.spm.util.import.dicom.outdir  = {dest_img_dir};
        matlabbatch{s3}.spm.util.import.dicom.convopts.format = 'nii';
        matlabbatch{s3}.spm.util.import.dicom.convopts.meta = 0;
        matlabbatch{s3}.spm.util.import.dicom.convopts.icedims = 0;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% SPM BATCH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    spm('defaults','fmri');
    spm_jobman('initcfg');
    fprintf('[========\nConverting DICOMs from folders:');
    spm_jobman('run',matlabbatch);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%% SPM BATCH %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%%% 3D to 4D conversion
    clear matlabbatch
    for s4 = 1:length(run_dir)
        if s4<10
            dest_img_dir = fullfile(MRI_PATH, sub_dir, 'preOrigin',['run00' num2str(s4, '%d')]);
            dir5_list = dir(fullfile(dest_img_dir));
            dir5_name = {dir5_list.name}';
            nii_idx = cell2mat(cellfun(@(x) contains(x,'.nii'),dir5_name, 'uniformoutput',0));
            nii_name = dir5_name(nii_idx);
            
            spm('defaults','fmri');
            spm_jobman('initcfg');
            epiname = ['run00' num2str(s4,'%d') '.nii'];
            matlabbatch{s4}.spm.util.cat.vols = fullfile(dest_img_dir,nii_name);
            matlabbatch{s4}.spm.util.cat.name = epiname;
            matlabbatch{s4}.spm.util.cat.dtype = 4;
        elseif s4==10;
            dest_img_dir = fullfile(MRI_PATH, sub_dir, 'preOrigin',['run0' num2str(s4, '%d')]);
            dir5_list = dir(fullfile(dest_img_dir));
            dir5_name = {dir5_list.name}';
            nii_idx = cell2mat(cellfun(@(x) contains(x,'.nii'),dir5_name, 'uniformoutput',0));
            nii_name = dir5_name(nii_idx);
            
            spm('defaults','fmri');
            spm_jobman('initcfg');
            epiname = ['run0' num2str(s4,'%d') '.nii'];
            matlabbatch{s4}.spm.util.cat.vols = fullfile(dest_img_dir,nii_name);
            matlabbatch{s4}.spm.util.cat.name = epiname;
            matlabbatch{s4}.spm.util.cat.dtype = 4;
        end
    end
    spm_jobman('run',matlabbatch);
    
    %%%% move the file preOrigin to postOrigin
    pre_dir     = fullfile(MRI_PATH, subject_info{sub,2},'preOrigin');
    post_dir    = fullfile(MRI_PATH, subject_info{sub,2},'postOrigin');
    if ~exist(post_dir),  mkdir(post_dir);
    end
    for s5 = 1:length(run_dir)
        d6_list = dir(pre_dir);
        d6_name = {d6_list.name}';
        d6_idx = cell2mat(cellfun(@(x) ~isempty(strfind(x,'run')), d6_name, 'uniformOutput',0 ));
        d6_get_name = d6_name(d6_idx);
        if s5<10
            epiname = ['run00' num2str(s5,'%d') '.nii'];
        elseif s5==10
            epiname = ['run0' num2str(s5,'%d') '.nii'];
        end
        movefile(fullfile(pre_dir,d6_get_name{s5},epiname), fullfile(post_dir));
    end
    dir_7 = dir(fullfile(dest_t1_dir));
    dir7_name={dir_7.name}';
    movefile(fullfile(dest_t1_dir,dir7_name{3}), fullfile(post_dir));
    movefile(fullfile(post_dir,dir7_name{3}),fullfile(post_dir,'t1.nii'));
end
%%









