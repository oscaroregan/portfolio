function [nextObs, reward, isDone, env] = hev_env_step(action, env)
% HEV_ENV_STEP  One RL step for the HEV PPO environment.
%
% Inputs:
%   action : scalar alpha_eng in [0,1] (engine torque fraction)
%   env    : struct with v_mps, a_mps2, k, x, vpa, prevShaftPwr
%
% Outputs:
%   nextObs : [SOC; v_norm; a_norm; prevShaftPwr_norm]
%   reward  : scalar, finite
%   isDone  : logical
%   env     : updated env struct

    %% -------- 1) UNPACK ENV & CURRENT STEP ----------------------------

    k   = env.k;
    vpa = env.vpa;
    x   = env.x;

    % If we've run out of cycle, terminate immediately
    if k >= env.N
        SOC_term = x{1};

        v_last = env.v_mps(end);
        a_last = env.a_mps2(end);
        P_last = env.prevShaftPwr;

        % Normalization constants (same as later)
        v_max = 40;           % m/s  (≈144 km/h) – tune to your cycle
        a_max = 5;            % m/s^2 – tune if needed
        P_max = 5e4;          % W    – tune to typical shaft power

        v_norm = v_last / v_max;
        a_norm = a_last / a_max;
        p_norm = P_last / P_max;

        nextObs = [
            SOC_term;
            v_norm;
            a_norm;
            p_norm
        ];
        reward = 0;
        isDone = true;
        return;
    end

    % Current drive cycle values
    v = env.v_mps(k);
    a = env.a_mps2(k);

    % Control input: engine fraction
    alpha_eng = max(0, min(1, action(1)));   % clip to [0,1]

    u = {alpha_eng};
    w = {v, a};

    %% -------- 2) CALL THE POWERTRAIN MODEL (hev_car) ------------------

    try
        [x_new, stageCost, unfeas, shaftPwr, shaftTrq, ...
         emElPwr, emSpd, emTrq, emMaxTrq, battLoss, ...
         battOutPwr, battCurr, battNewVoltage, ENG] = ...
            hev_car(x, u, w, vpa);

    catch ME
        % If hev_car blows up, give a big negative reward and terminate
        warning("hev_env_step: hev_car threw error: %s", ME.message);

        % Build *normalized* obs here too, for consistency
        SOC_term = x{1};

        v_last = v;
        a_last = a;
        P_last = env.prevShaftPwr;

        v_max = 40;
        a_max = 5;
        P_max = 5e4;

        v_norm = v_last / v_max;
        a_norm = a_last / a_max;
        p_norm = P_last / P_max;

        nextObs = [
            SOC_term;
            v_norm;
            a_norm;
            p_norm
        ];
        reward = -1e6;
        isDone = true;
        return;
    end

    %% -------- 3) COMPUTE REWARD (FUEL + SOC PENALTY) ------------------

    SOC_new      = x_new{1};
    fuelEnergy_J = stageCost;

    % ===== DEBUG BLOCK: LOG FUEL & SOC PER EPISODE =====
    persistent fuelLog socLog stepInEpisode episodeCount

    if isempty(stepInEpisode)
        fuelLog       = zeros(env.N,1);   % max length per episode
        socLog        = zeros(env.N,1);
        stepInEpisode = 0;
        episodeCount  = 0;
    end

    % Increment step counter for this episode (cap at env.N)
    stepInEpisode = min(stepInEpisode + 1, env.N);

    % Store current step data
    fuelLog(stepInEpisode) = fuelEnergy_J;
    socLog(stepInEpisode)  = SOC_new;
    % ===== END DEBUG BLOCK =====

    % Safety guard on fuelEnergy
    if ~isfinite(fuelEnergy_J) || fuelEnergy_J < 0
        fuelEnergy_J = 0;
    end

    % 1) Fuel penalty (scaled using your stats: mean ~1e4 at high alpha)
    fuelScale   = 1e4;                      % from debug (tune if needed)
    fuelPenalty = fuelEnergy_J / fuelScale; % typical ~0–2 per step

    % 2) SOC tracking around 0.70
    socTarget  = 0.70;
    socWeight  = 300;                       % try 300–500, tune as needed
    socPenalty = socWeight * (SOC_new - socTarget)^2;

    % 3) Infeasibility penalty (moderate)
    infeasPenalty = 0;
    if any(unfeas(:))
        infeasPenalty = 5;                  % small but noticeable
    end

    % Total cost and reward
    totalCost = fuelPenalty + socPenalty + infeasPenalty;

    if ~isfinite(totalCost)
        totalCost = 10;                     % safe fallback
    end

    reward = -totalCost;                    % NO extra scaling

       % ---- DEBUG: track reward range over episode ----
    persistent rMin rMax
    if isempty(rMin)
        rMin = inf; 
        rMax = -inf;
    end
    
    rMin = min(rMin, reward);
    rMax = max(rMax, reward);


    %% -------- 4) ADVANCE ENV STATE ------------------------------------

    env.x = x_new;
    env.prevShaftPwr = shaftPwr;
    env.k = k + 1;

    % Episode termination conditions
    isDone = false;

    % Terminate at end of drive cycle
    if env.k >= env.N
        isDone = true;
    end

    % Also terminate if SOC leaves safe bounds
    if SOC_new < 0.2 || SOC_new > 0.95
        isDone = true;
    end

     % ===== DEBUG: IF EPISODE ENDED, PRINT FUEL/SOC + REWARD STATS =====
    if isDone
        episodeCount = episodeCount + 1;
        stepsThisEp  = stepInEpisode;

        validFuel = fuelLog(1:stepsThisEp);
        validSOC  = socLog(1:stepsThisEp);

        fprintf('\n[DEBUG hev_env_step] Episode %d finished\n', episodeCount);
        fprintf('  Steps: %d\n', stepsThisEp);
        fprintf('  fuelEnergy_J: mean = %.3e, max = %.3e, min = %.3e\n', ...
            mean(validFuel), max(validFuel), min(validFuel));
        fprintf('  SOC_new:      mean = %.3f, max = %.3f, min = %.3f\n', ...
            mean(validSOC), max(validSOC), min(validSOC));

         % ---- reward range debug (NO second persistent) ----
    fprintf('  Reward range: [%.3f, %.3f], mid ≈ %.3f\n\n', ...
        rMin, rMax, 0.5*(rMin + rMax));
    rMin = inf; 
    rMax = -inf;
    % ------------------

        stepInEpisode = 0;
    end

    %% -------- 5) BUILD NEXT OBSERVATION (NORMALIZED) ------------------

    if env.k <= env.N
        v_next = env.v_mps(env.k);
        a_next = env.a_mps2(env.k);
    else
        v_next = env.v_mps(end);
        a_next = env.a_mps2(end);
    end

    % Same normalization constants as above
    v_max = 40;          % m/s
    a_max = 5;           % m/s^2
    P_max = 5e4;         % W

    v_norm = v_next / v_max;
    a_norm = a_next / a_max;
    p_norm = env.prevShaftPwr / P_max;

    nextObs = [
        SOC_new;
        v_norm;
        a_norm;
        p_norm
    ];
end
