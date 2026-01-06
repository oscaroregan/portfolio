% train_hev_ppo.m
% Main script to train PPO on hev_car torque split

%% =============== OBSERVATION & ACTION SPECS ====================
clear; clc; close all;
rng(0,"twister"); 

% obs = [ SOC; v_mps; a_mps2; prevShaftPwr ]
numObs = 4;

obsInfo = rlNumericSpec([numObs 1], ...
    "Name","obs", ...
    "Description","[SOC; v_mps; a_mps2; prevShaftPwr]");

% action = alpha_eng in [0,1] (engine torque fraction)
numAct = 1;
actInfo = rlNumericSpec([numAct 1], ...
    "Name","alpha_eng", ...
    "LowerLimit",0, ...
    "UpperLimit",1);

%% =============== ENVIRONMENT HANDLES ===========================

envStepHandle  = @(action,env) hev_env_step(action,env);
envResetHandle = @hev_env_reset;

env = rlFunctionEnv(obsInfo, actInfo, envStepHandle, envResetHandle);

%% =============== ACTOR NETWORK (GAUSSIAN) =====================

% Shared observation path
obsPath = [
    featureInputLayer(numObs, "Normalization","none", "Name","obs")
    fullyConnectedLayer(64, "Name","fc1")
    reluLayer("Name","relu1")
    fullyConnectedLayer(64, "Name","fc2")
    reluLayer("Name","relu2")
];

% Mean branch
meanPath = [
    fullyConnectedLayer(numAct, "Name","mean_fc")
    tanhLayer("Name","mean_tanh")   % [-1,1] internally; mapped into [0,1] by actInfo
];

% Std branch (positive)
stdPath = [
    fullyConnectedLayer(numAct, "Name","std_fc")
    softplusLayer("Name","std_softplus")   % >0
];

% Build layer graph with two heads
lgraph = layerGraph(obsPath);
lgraph = addLayers(lgraph, meanPath);
lgraph = addLayers(lgraph, stdPath);

% Connect shared path to both heads
lgraph = connectLayers(lgraph, "relu2", "mean_fc");
lgraph = connectLayers(lgraph, "relu2", "std_fc");

actorNetwork = dlnetwork(lgraph);

actor = rlContinuousGaussianActor( ...
    actorNetwork, obsInfo, actInfo, ...
    "ActionMeanOutputNames","mean_tanh", ...
    "ActionStandardDeviationOutputNames","std_softplus");

%% =============== CRITIC NETWORK (STATE VALUE) =================

criticLayers = [
    featureInputLayer(numObs, "Normalization","none", "Name","obs")
    fullyConnectedLayer(64, "Name","c_fc1")
    reluLayer("Name","c_relu1")
    fullyConnectedLayer(64, "Name","c_fc2")
    reluLayer("Name","c_relu2")
    fullyConnectedLayer(1, "Name","value")   % V(s)
];

criticNetwork = dlnetwork(layerGraph(criticLayers));

critic = rlValueFunction(criticNetwork, obsInfo, ...
    "ObservationInputNames","obs");

%% =============== PPO AGENT OPTIONS ========================%%
agentOpts = rlPPOAgentOptions( ...
    ExperienceHorizon = 512, ...
    MiniBatchSize     = 64, ...
    NumEpoch          = 5, ...        % more passes per batch
    ClipFactor        = 0.25, ...      % smaller => gentler updates
    EntropyLossWeight = 0.04, ...    % smaller => less random once learning
    AdvantageEstimateMethod = "gae", ...
    GAEFactor         = 0.95, ...
    SampleTime        = 1, ...
    DiscountFactor    = 0.99, ...
    ActorOptimizerOptions  = rlOptimizerOptions( ...
        "LearnRate",1e-3, "GradientThreshold",1), ...  % more cautious
    CriticOptimizerOptions = rlOptimizerOptions( ...
        "LearnRate",5e-5, "GradientThreshold",1) ...   % also a bit smaller
);
agent = rlPPOAgent(actor, critic, agentOpts);

%% =============== TRAINING OPTIONS =============================

trainOpts = rlTrainingOptions( ...
    MaxEpisodes = 10000, ...
    MaxStepsPerEpisode = 600, ...
    StopTrainingCriteria = "AverageReward", ...
    StopTrainingValue = -1000, ...           % whatever target you want
    ScoreAveragingWindowLength = 20, ...
    SaveAgentCriteria = "EpisodeReward", ... % <-- NEW
    SaveAgentValue    = -Inf, ...            % save whenever we see a new best
    SaveAgentDirectory = "C:\Users\oscar\OneDrive\Documents\MATLAB\Car Model\savedAgents", ...  % folder to write .mat files into
    Verbose = true, ...
    Plots = "training-progress");

trainingStats = train(agent, env, trainOpts);
