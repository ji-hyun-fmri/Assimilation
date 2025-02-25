clear; clc;
RAW_PATH       = 
DAT_DIR       = 


subject_info  = {
 
    };
subject_order = {
  
    };
nSub     = size(subject_info,1);


condition_label   = {
    'ND'
    'Second'
    'Questions';};
nCond             = length(condition_label);


motion_regressor  = {'Raw',            1;
    'Sqaure',         0;
    'firstDerivate',  0;
    'secondDerivate', 0};
regress_param     = {'GreyMatter',     0;
    'WhiteMatter',    0.999;
    'CSF_Bone',       0.999;
    'SoftTissue',     0.999;
    'Air_Background', 0.999};


contrast_model    = {'model1_Stim_Baseline_ND';}
%     'model2_Stim_Rest_ND';
%     'model3_Between_Stim_ND'};
for sub = 1:nSub
    display(sub)
    sub_dir           = fullfile(DAT_DIR, subject_info{sub,2});
    nii_dir           = fullfile(sub_dir,'preProc');
    firstlevel_dir    = fullfile(sub_dir,'1st_ND');
    spm_file{sub}          = fullfile(firstlevel_dir, 'SPM.mat');
    
    if ~exist(firstlevel_dir,'dir'), mkdir(firstlevel_dir);
    end
    if  exist(spm_file{sub},'file'),      delete(spm_file{sub});
    end
    
    clear matlabbatch;
    matlabbatch{1}.spm.stats.fmri_spec.dir             = {firstlevel_dir};
    matlabbatch{1}.spm.stats.fmri_spec.timing.units    = 'secs';
    matlabbatch{1}.spm.stats.fmri_spec.timing.RT       = 2;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t   = 72;
    matlabbatch{1}.spm.stats.fmri_spec.timing.fmri_t0  = 36;
    matlabbatch{1}.spm.stats.fmri_spec.fact            = struct('name', {}, 'levels', {});
    matlabbatch{1}.spm.stats.fmri_spec.volt            = 1;
    matlabbatch{1}.spm.stats.fmri_spec.global          = 'None';
    matlabbatch{1}.spm.stats.fmri_spec.mthresh         = 0.8;
    matlabbatch{1}.spm.stats.fmri_spec.mask            = {''};
    matlabbatch{1}.spm.stats.fmri_spec.cvi             = 'AR(1)';
    
    %% AHc vs AHt condtion
    order = {subject_order{sub,:}};
    if order{2} == 'ND'
        sess_num = [1];
        position = {order{3},order{4}};
    elseif order{5} =='ND'
        sess_num = [5];
        position = {order{6},order{7}}; 
    elseif order{8} =='ND'
        sess_num=[9];
        position = {order{9},order{10}};
    end
    sub_num = subject_info{sub,1};
    respname{1} = fullfile(['sub',num2str(sub_num,'%d'),'_ND_',position{1},'_0.mat']);
    respname{2} = fullfile(['sub',num2str(sub_num,'%d'),'_ND_',position{2},'_0.mat']);

    for sess = 1:2
        num_sess = sess_num+sess-1;
        if num_sess <10
            nii_file       = fullfile(nii_dir, ['swarrun00' num2str(num_sess,'%d') '.nii']);
        elseif num_sess==10
            nii_file       = fullfile(nii_dir, ['swarrun0' num2str(num_sess,'%d') '.nii']);
        end
        
        volumeInfo     = spm_vol(nii_file);
        numVolume      = length(volumeInfo);
        epiData        = spm_read_vols(volumeInfo);
        sess_file      = cell(numVolume,1);
        for vol = 1:numVolume
            sess_file{vol,1}  = fullfile([nii_file ',' num2str(vol)]);
        end
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).scans   = sess_file;
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).multi   = {''};
        matlabbatch{1}.spm.stats.fmri_spec.sess(sess).hpf     = 128;
        if num_sess<10
            motionFile           = fullfile(nii_dir, ['rp_run00' num2str(num_sess,'%d') '.txt']);
        elseif num_sess==10
            motionFile           = fullfile(nii_dir, ['rp_run0' num2str(num_sess,'%d') '.txt']);
        end
        motionParam          = load(fullfile(motionFile));
        motionParam(:,4:6)   = (motionParam(:,4:6).*180)./pi;
        regressor            = [];
        regressorName        = [];
        if motion_regressor{1,2}   % raw
            regressor         = [regressor, motionParam];
            regressorName     = [regressorName {'MovX','MovY','MovZ','Pitch','Roll','Yaw'}];
        end
        if motion_regressor{2,2}   % square
            regressor         = [regressor, motionParam.^2];
            regressorName = [regressorName {'X_Sq','Y_Sq','Z_Sq','Pitch_Sq','Roll_Sq','Yaw_Sq'}];
        end
        if motion_regressor{3,2}   % firstDerivate
            regressor         = [regressor, [zeros(1,6); diff(motionParam)]];
            regressorName = [regressorName {'X_1stDer','Y_1stDer','Z_1stDer','Pitch_1stDer','Roll_1stDer','Yaw_1stDer'}];
        end
        if motion_regressor{4,2}   % secondDerivate
            regressor         = [regressor, [zeros(2,6); diff(motionParam,2)]];
            regressorName = [regressorName {'X_2ndDer','Y_2ndDer','Z_2ndDer','Pitch_2ndDer','Roll_2ndDer','Yaw_2ndDer'}];
        end
        
        for rc = 1:length(regressorName)
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess).regress(rc).name    = regressorName{rc};
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess).regress(rc).val     = regressor(:,rc);
        end
        load(fullfile('C:\Users\User\Desktop\jihyun\result2',respname{sess}));
        stimuli_dummy = reshape([respMat{:,4}],1,24);
        for cond = 1:nCond
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).name  = condition_label{cond};
            if cond==1
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).onset = [respMat{:,4}];
            elseif cond==2
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).onset = [respMat{:,5}];
            elseif cond==3
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).onset =  [respMat{:,5}]+2;

            end
            if cond<5
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).duration = 0;
            elseif cond==5
                matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).duration = [respMat{:,7}];
            end
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).tmod  = 0;
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).pmod  = struct('name', {}, 'param', {}, 'poly', {});
            matlabbatch{1}.spm.stats.fmri_spec.sess(sess).cond(cond).orth  = 0;

            matlabbatch{1}.spm.stats.fmri_spec.bases.hrf.derivs = [0 0];
        end
    end
    batch{sub} = matlabbatch;
end
parfor sub=1:nSub
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub});
end

clear batch;
for sub=1:nSub
    %%%% run 'SPM estimate'
    clear matlabbatch;
    matlabbatch{1}.spm.stats.fmri_est.spmmat           = {spm_file{sub}};
    matlabbatch{1}.spm.stats.fmri_est.write_residuals  = 0;
    matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
    batch{sub} = matlabbatch;
end
parfor sub=1:nSub
    spm('defaults', 'fmri');
    spm_jobman('initcfg');
    spm_jobman('run',batch{sub});
end
clear batch;

%%%% run 'Contrast'
for sub=1:nSub
    sub_dir           = fullfile(DAT_DIR, subject_info{sub,2});
    nii_dir           = fullfile(sub_dir,'preProc');
    firstlevel_dir    = fullfile(sub_dir,'1st_ND');
    numEpiRun      = 2;
    for ct = 1:size(contrast_model,1)
        model_dir      = fullfile(sub_dir, contrast_model{ct});
        if ~exist(model_dir,'dir'),      mkdir(model_dir);
        end
        model_spm      = fullfile(model_dir,'SPM.mat');
        copyfile(firstlevel_dir, model_dir);
        contrast_info  = set_contrast_ND(contrast_model{ct},6,numEpiRun);
        clear matlabbatch;
        if  ct ==1
            for c = 1:size(contrast_info.name,2)
                if c==1
                    matlabbatch{1}.spm.stats.con.consess{c}.tcon.name     = contrast_info.name{c}; %%change the f contrast
                    matlabbatch{1}.spm.stats.con.consess{c}.tcon.convec   = contrast_info.formular{c};
                    matlabbatch{1}.spm.stats.con.consess{c}.tcon.sessrep  = 'none';
                else
                    matlabbatch{1}.spm.stats.con.consess{c}.tcon.name     = contrast_info.name{c}; %%change the f contrast
                    matlabbatch{1}.spm.stats.con.consess{c}.tcon.convec   = contrast_info.formular{c};
                    matlabbatch{1}.spm.stats.con.consess{c}.tcon.sessrep  = 'none';
                end
            end
        elseif ct==2
            for c = 1:size(contrast_info.name,2)
                matlabbatch{1}.spm.stats.con.consess{c}.tcon.name     = contrast_info.name{c}; %%change the f contrast
                matlabbatch{1}.spm.stats.con.consess{c}.tcon.convec   = contrast_info.formular{c};
                matlabbatch{1}.spm.stats.con.consess{c}.tcon.sessrep  = 'none';
            end
        elseif ct==3
            for c = 1:size(contrast_info.name,2)
                matlabbatch{1}.spm.stats.con.consess{c}.tcon.name     = contrast_info.name{c}; %%change the f contrast
                matlabbatch{1}.spm.stats.con.consess{c}.tcon.convec   = contrast_info.formular{c};
                matlabbatch{1}.spm.stats.con.consess{c}.tcon.sessrep  = 'none';
            end
        end
        matlabbatch{1}.spm.stats.con.delete    = 1;
        matlabbatch{1}.spm.stats.con.spmmat    = {model_spm};
        batch{sub,ct} = matlabbatch;
    end
end
parfor sub=1:nSub
    for ct = 1:size(contrast_model,1)
        fprintf('==================================================\n');
        fprintf(['MAKING CONTRAST: ' subject_info{sub,2} ';' contrast_model{ct} '\n']);
        fprintf('==================================================\n');
        spm('defaults','fmri');
        spm_jobman('initcfg');
        spm_jobman('run',batch{sub,ct});
    end
end




