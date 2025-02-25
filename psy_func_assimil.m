%% can we averaing the mr and behav data?
clear all; clc; close all;
stimuli = [15, 21, 25, 36, 42, 60];
iter = 60;
subject_info  = {
   
    };
nSub     = size(subject_info,1);

%%
close all;
clear searchGrid;
clear options;
PF = @PAL_Logistic;
%-- Initial parameter
% threshold, slope, guess rate, lapse rate

parfor sub=1:nSub

    StimLevels = stimuli;
    NumPos1 = 
    NumPos2 = 
    NumPos3 = 
    NumPos4 = 
    NumPos5 = 
    OutOfNum =1*28*ones(1,6); % 5 is num of subj
    
    [paramsValues1 LL exitflag output] = PAL_PFML_Fit(StimLevels,NumPos1, OutOfNum, searchGrid, paramsFree, PF,'SearchOptions',options);
    if exitflag == -1
        fprintf('\n -1 scenario: Fix slope\n\n');
        % 2 -> 32
        [paramsValues1, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos1, OutOfNum, searchGrid_alter1, [1 0 1 1], PF, 'SearchOptions',options);
    elseif exitflag == -2
        
        fprintf('\n -2 scenario: Similar to scenario -1 but without intemediate point.\n\n');
        [paramsValues1, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos1, OutOfNum, searchGrid_alter2, [1 0 1 1], PF, 'searchOptions',options);
    end
    [paramsValues2 LL exitflag output] = PAL_PFML_Fit(StimLevels,NumPos2, OutOfNum, searchGrid, paramsFree, PF,'SearchOptions',options);
    if exitflag == -1
        fprintf('\n -1 scenario: Fix slope\n\n');
        
        [paramsValues2, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos2, OutOfNum, searchGrid_alter1, [1 0 1 1], PF, 'SearchOptions',options);
    elseif exitflag == -2
        
        fprintf('\n -2 scenario: Similar to scenario -1 but without intemediate point.\n\n');
        [paramsValues2, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos2, OutOfNum, searchGrid_alter2, [1 0 1 1], PF, 'searchOptions',options);
    end
    [paramsValues3 LL exitflag output] = PAL_PFML_Fit(StimLevels,NumPos3, OutOfNum, searchGrid, paramsFree, PF,'SearchOptions',options);
    if exitflag == -1
        fprintf('\n -1 scenario: Fix slope\n\n');
        
        [paramsValues3, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos3, OutOfNum, searchGrid_alter1, [1 0 1 1], PF, 'SearchOptions',options);
    elseif exitflag == -2
        
        fprintf('\n -2 scenario: Similar to scenario -1 but without intemediate point.\n\n');
        [paramsValues3, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos3, OutOfNum, searchGrid_alter2, [1 0 1 1], PF, 'searchOptions',options);
    end
    [paramsValues4 LL exitflag output] = PAL_PFML_Fit(StimLevels,NumPos4, OutOfNum, searchGrid, paramsFree, PF,'SearchOptions',options);
    if exitflag == -1
        fprintf('\n -1 scenario: Fix slope\n\n');
        % 2 -> 32
        
        [paramsValues4, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos4, OutOfNum, searchGrid_alter1, [1 0 1 1], PF, 'SearchOptions',options);
    elseif exitflag == -2
        
        fprintf('\n -2 scenario: Similar to scenario -1 but without intemediate point.\n\n');
        [paramsValues4, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos4, OutOfNum, searchGrid_alter2, [1 0 1 1], PF, 'searchOptions',options);
    end
    [paramsValues5 LL exitflag output] = PAL_PFML_Fit(StimLevels,NumPos5, OutOfNum, searchGrid, paramsFree, PF,'SearchOptions',options);
    if exitflag == -1
        fprintf('\n -1 scenario: Fix slope\n\n');
        
        [paramsValues5, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos5, OutOfNum, searchGrid_alter1, [1 0 1 1], PF, 'SearchOptions',options);
    elseif exitflag == -2
        
        fprintf('\n -2 scenario: Similar to scenario -1 but without intemediate point.\n\n');
        [paramsValues5, LL, exitflag, output] = PAL_PFML_Fit(StimLevels, NumPos5, OutOfNum, searchGrid_alter2, [1 0 1 1], PF, 'searchOptions',options);
    end
    
    alpha1(sub) = paramsValues1(1);
    alpha2(sub) = paramsValues2(1);
    alpha3(sub) = paramsValues3(1);
    alpha4(sub) = paramsValues4(1);
    alpha5(sub) = paramsValues5(1);
    
    StimLevelsFine = [10:(100)./1000:100]';
    
    Fit1(:,sub) = PF(paramsValues1, StimLevelsFine);
    Fit2(:,sub) = PF(paramsValues2, StimLevelsFine);
    Fit3(:,sub) = PF(paramsValues3, StimLevelsFine);
    Fit4(:,sub) = PF(paramsValues4, StimLevelsFine);
    Fit5(:,sub) = PF(paramsValues5, StimLevelsFine);
        figure(sub)
        a1 = errorbar(StimLevels,NumPos1./OutOfNum,std(ND)/sqrt(nSub),'ko','MarkerSize',10,'LineWidth',2)
        hold on;
        a2 = plot(StimLevelsFine,Fit1(:,sub),'k-','LineWidth',2);
        hold on;
        b1 = errorbar(StimLevels,NumPos2./OutOfNum,std(AFc_re)/sqrt(nSub),'r*','MarkerSize',10,'LineWidth',2)
        hold on;
        b2 = plot(StimLevelsFine,Fit4(:,sub),'r-','LineWidth',2);
        hold on;
        c1 = errorbar(StimLevels,NumPos3./OutOfNum,std(AFt_re)/sqrt(nSub),'r^','MarkerSize',10,'LineWidth',2)
        hold on;
        c2 = plot(StimLevelsFine,Fit5(:,sub),'r--','LineWidth',2);
        hold on;
        plot(StimLevelsFine,0.5*ones(1,length(StimLevelsFine)),'k-.')
        ylim([0 1]);
        yticks([0 0.25 0.5 0.75 1]);
end
close all
StimLevelsFine = [10:(100)./1000:100]';
StimLevels = stimuli;
OutOfNum =1*28*ones(1,6); % 5 is num of subj
for sub = 1:nSub %28
    
    figure(1)
    subplot(7,8,2*sub-1)
    plot(StimLevelsFine,Fit1(:,sub),'k-','LineWidth',2);
    hold on;
    scatter(StimLevels,NumPos1./OutOfNum,'ko','LineWidth',2)
    hold on;
    plot(StimLevelsFine,Fit2(:,sub),'r-','LineWidth',2);
    hold on;
    scatter(StimLevels,NumPos2./OutOfNum,'r*','LineWidth',2)
    hold on;
    plot(StimLevelsFine,Fit3(:,sub),'r--','LineWidth',2);
    hold on;
    scatter(StimLevels,NumPos3./OutOfNum,'r^','LineWidth',2)
    hold off;
    subplot(7,8,2*sub)
    plot(StimLevelsFine,Fit1(:,sub),'k-','LineWidth',2);
        hold on;
    scatter(StimLevels,NumPos1./OutOfNum,'ko','LineWidth',2)
    hold on;
    plot(StimLevelsFine,Fit4(:,sub),'b-','LineWidth',2);
        hold on;
    scatter(StimLevels,NumPos4./OutOfNum,'b*','LineWidth',2)
    hold on
    plot(StimLevelsFine,Fit5(:,sub),'b--','LineWidth',2);
        hold on;
    scatter(StimLevels,NumPos5./OutOfNum,'b^','LineWidth',2)
    hold off;
end
