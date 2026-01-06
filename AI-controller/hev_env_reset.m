function [obs0, env] = hev_env_reset()
% HEV_ENV_RESET  Reset function for the HEV PPO environment.
% Returns:
%   obs0 : 4x1 initial observation [SOC; v_norm; a_norm; prevShaftPwr_norm]
%   env  : struct holding drive-cycle data, index k, and powertrain objects

    %% -------- 1) DEFINE A SIMPLE DRIVE CYCLE --------------------------
    % You can replace this block later with your own v(t).

    dt   = 1;             % [s] sample time
    tEnd = 600;           % [s] total duration
    env.t = (0:dt:tEnd)'; % column vector
    N     = numel(env.t);
    env.N = N;

    v_mps = zeros(N,1);

    for k = 1:N
        t = env.t(k);

        if t <= 60
            % 0 → 20 m/s in 60 s
            v_mps(k) = (t/60)*20;
        elseif t <= 300
            % cruise at 20 m/s
            v_mps(k) = 20;
        elseif t <= 360
            % brake back to 0 in 60 s
            v_mps(k) = max(0, 20 - (t-300)/60*20);
        else
            % standstill
            v_mps(k) = 0;
        end
    end

    env.v_mps  = v_mps;
    env.a_mps2 = [0; diff(v_mps)/dt];

    %% -------- 2) BUILD POWERTRAIN (vpa) -------------------------------

    % --- Engine from your EcoTec file ---
    eng = FC_EcoTec();   % must return a struct with maps

    % Make sure LHV exists [J/kg] for reward calculation
    if ~isfield(eng,"LHV")
        if isfield(eng,"fc_fuel_lhv")
            eng.LHV = eng.fc_fuel_lhv;   % from the data file
        else
            eng.LHV = 42.6e6;            % fallback: gasoline typical
        end
    end

    % --- Battery pack (Li-ion) ---
    batt = battery_rint;
    batt.series_parallel_config = [96, 8];   % adjust if you changed it
    batt = batt.init;

    % --- Electric motor ---
    em = em_combined_effic;
    em = em.init;

    % --- DC/DC converter ---
    dcdc = dcdc_bi;
    dcdc = dcdc.init;

    % Collect basic components
    vpa = struct( ...
        "eng",  eng, ...
        "batt", batt, ...
        "em",   em, ...
        "dcdc", dcdc );

    % Add gearbox, final drive, and vehicle body
    vpa = vpa_init_hev(vpa);

    env.vpa = vpa;

    %% -------- 3) INITIAL STATE & INDEX --------------------------------

    SOC0 = 0.7;           % start at 70% SOC
    env.x = {SOC0};       % state is a cell (to match hev_car)
    env.prevShaftPwr = 0; % W, used as part of observation

    env.k = 1;            % current time index for hev_env_step

    % Build initial observation (NORMALIZED to match hev_env_step)
    v0 = env.v_mps(env.k);
    a0 = env.a_mps2(env.k);

    % Normalization constants (must match hev_env_step)
    v_max = 40;           % m/s  (≈144 km/h)
    a_max = 5;            % m/s^2
    P_max = 5e4;          % W    (50 kW)

    v_norm = v0 / v_max;
    a_norm = a0 / a_max;
    p_norm = env.prevShaftPwr / P_max;

    % obs = [SOC; v_norm; a_norm; prevShaftPwr_norm]
    obs0 = [
        SOC0;
        v_norm;
        a_norm;
        p_norm
    ];
end
