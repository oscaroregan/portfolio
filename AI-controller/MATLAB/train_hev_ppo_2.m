% train_hev_ppo_continue.m
% Continue training an already-saved PPO agent

clear; clc; close all;
rng(0,"twister"); 

%% =============== OBSERVATION & ACTION SPECS ====================

numObs = 4;
obsInfo = rlNumericSpec([numObs 1], ...
    "Name","obs", ...
    "Description","[SOC; v_norm; a_norm; prevShaftPwr_norm]");

numAct = 1;
actInfo = rlNumericSpec([numAct 1], ...
    "Name","alpha_eng", ...
    "LowerLimit",0, ...
    "UpperLimit",1);

%% =============== ENVIRONMENT HANDLES ===========================

envStepHandle  = @(action,env) hev_env_step(action,env);
envResetHandle = @hev_env_reset;    % or hev_env_reset_normal if you made modes

env = rlFunctionEnv(obsInfo, actInfo, envStepHandle, envResetHandle);

%% =============== LOAD EXISTING AGENT & TWEAK OPTIONS ===========

% Load the *trained* agent from earlier
S = load("agent_normal_2085.mat");  % must contain variable 'agent'
agent = S.saved_agent; 
% Get current PPO options from that agent
agent.AgentOptions.EntropyLossWeight = 0.02;
agent.AgentOptions.ClipFactor        = 0.04;
agent.AgentOptions.ActorOptimizerOptions.LearnRate  = 5e-3;
agent.AgentOptions.CriticOptimizerOptions.LearnRate = 1e-4;

%% =============== TRAINING OPTIONS (PHASE 2) ====================

trainOpts2 = rlTrainingOptions( ...
    MaxEpisodes = 300, ...
    MaxStepsPerEpisode = 600, ...
    StopTrainingCriteria = "EpisodeReward", ...   % or "AverageReward"
    StopTrainingValue = Inf, ...                 % run full MaxEpisodes
    ScoreAveragingWindowLength = 20, ...
    SaveAgentCriteria = "EpisodeReward", ...
    SaveAgentValue    = -Inf, ...
    SaveAgentDirectory = "C:\Users\oscar\OneDrive\Documents\MATLAB\Car Model\savedAgents", ...
    Verbose = true, ...
    Plots = "training-progress");

%% =============== CONTINUE TRAINING ==============================

trainingStats2 = train(agent, env, trainOpts2);
