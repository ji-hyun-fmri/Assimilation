clear; clc;
RAW_PATH       = 
DAT_DIR       =


subject_info  = {
   
    };
nSub              = length(subject_info);

contrast_model    = {'model1_Stim_Baseline_AF', 1;%���⼭�� ���ڴ� aristotle asynch�̱� ������ 3->2�� �� 5/26
                     'model2_Stim_Rest_AF',     1;
                     'model3_Between_Stim_AF',  2};

%%%% Make the specific directory for the 2nd level analysis
secondlevel_dir   = fullfile(DAT_DIR,'second_analysis');
if ~exist(secondlevel_dir,'dir'),   mkdir(secondlevel_dir);
end

for m = 1:size(contrast_model,1)
   sub_1st_model_dirs   = cellfun(@(x,y) fullfile(DAT_DIR,x,contrast_model(m,1)), subject_info(:,2));
   
   for c = 1:contrast_model{m,2}
      allContrastFiles  = {};
      for sub = 1:nSub
         sub_con_file      = dir(fullfile(sub_1st_model_dirs{sub},['con_' num2str(c,'%04d') '.nii']));
         sub_con_filename  = fullfile(sub_1st_model_dirs{sub},{sub_con_file.name}');
         allContrastFiles  = [allContrastFiles; sub_con_filename];
      end
      
      load(fullfile(sub_1st_model_dirs{end},'SPM.mat'));
      contrast_name        = SPM.xCon(c).name;
      clear SPM;
      
      disp(contrast_name);
      disp(allContrastFiles);
      contrast_2nd_dir     = ['/Con' num2str(c,'%02d') '_']; %contrast_name]; %%���� �̸��� <���� �ȵ�
      contrast_2nd_path    = fullfile(secondlevel_dir,contrast_model(m,1),contrast_2nd_dir);
      mkdir(cell2mat(contrast_2nd_path));
      
      %%%% Set up the second level analysis
      clear matlabbatch;
      spm('defaults','fmri');
      spm_jobman('initcfg');
      matlabbatch{1}.spm.stats.factorial_design.dir            = cellstr(contrast_2nd_path);
      matlabbatch{1}.spm.stats.factorial_design.des.t1.scans   = allContrastFiles;
      fprintf(['======\n' 'SPECIFYING SECOND LEVEL for model:']);
      spm_jobman('run', matlabbatch);
      
      
      %%%% Estimate the second level
      clear matlabbatch;
      spm('defaults','fmri');
      spm_jobman('initcfg');
      matlabbatch{1}.spm.stats.fmri_est.spmmat = {[cell2mat(contrast_2nd_path) '/SPM.mat']};
      matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;
      fprintf(['======\n' 'ESTIMATING SECOND LEVEL for model: ']);
      spm_jobman('run', matlabbatch);
   end
end



