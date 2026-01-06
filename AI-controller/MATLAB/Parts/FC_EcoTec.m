function eng = FC_EcoTec()
% ==============================================================================
%  GM EcoTec 2.4L LE9 Engine (Modified for HEV Simulation)
%  This version outputs a clean 'eng' struct with interpolation functions.
% ==============================================================================

% -------------------------
% LOAD ORIGINAL ADVISOR DATA
% -------------------------

% Basic info
fc_description='GM EcoTec 2.4L LE9 Engine';
fc_fuel_type='Gasoline';
fc_disp=1.9; 
disp(['Data loaded: FC_EcoTec.m - ',fc_description]);

% SPEED RANGE (rad/s)
fc_map_spd=[0.5:0.5:6]*1000*2*pi/60; 

% TORQUE RANGE (Nm)
fc_map_trq=[1:11]*15.6; 

% -------------------------
% FUEL MAP (µg/Ws)
% -------------------------

fc_fuel_map_ugpWs=0.7*[...
170   170   170   165   155   145   130   145   150   190   210   210
123   112   113   110   106   101   94.5  99    109   128   142   147
103   93.5  96    93    89    86.5  80    88.2  97.6  105   117   120
92    85.5  85    83.5  79    77.5  78    84.5  88    92.5  101.5 104
85    79    78    76.5  74    73    77    78.5  81.5  85    91    93
87    79.5  73    72    68.5  71    74.3  76.5  77.5  79    82    87
84    78.5  70.7  68    68    69    72    73    75.5  78.7  83    83
90    79    68.5  68    68    68    69    70.5  75    77.5  82    82
80    80    70    69    68    68    69    73    75.8  78.6  81    81
80    80    80    73    71    72    73    74    76.5  79    80.5  80
80    80    80    80    80    80    80    80    80    80    80    80];

% Transpose to match [speed x torque]
fc_fuel_map_ugpWs = fc_fuel_map_ugpWs';

% -------------------------
% Compute fuel map (g/s)
% -------------------------
[T,w] = meshgrid(fc_map_trq, fc_map_spd); 
fc_map_kW = T.*w/1000;
fc_fuel_map = fc_fuel_map_ugpWs/1000000 .* fc_map_kW * 1000;  % g/s

% -------------------------
% Torque Limits
% -------------------------
fc_max_trq=[7.2 8.6 9.4 10.15 10.6 10.4 10.2 10.25 10.6 10.55 10.3 9.7]*15.6;

fc_ct_trq = 4.448/3.281*(-fc_disp)*61.02/24 * ...
   (9*(fc_map_spd/max(fc_map_spd)).^2 + 14*(fc_map_spd/max(fc_map_spd)));

% -------------------------
% Engine Mass, Inertia, LHV
% -------------------------
fc_base_mass=110;
fc_acc_mass =20;
fc_fuel_mass=70;
fc_mass = fc_base_mass+fc_acc_mass+fc_fuel_mass;
fc_inertia = 0.1;     % approx
fc_fuel_lhv = 42.6e6; % J/kg (42.6 kJ/g)

% -------------------------
% PACKAGE INTO eng STRUCT
% -------------------------

eng.map_spd = fc_map_spd(:);        % [rad/s]
eng.map_trq = fc_map_trq(:)';       % [Nm]
eng.fuel_map = fc_fuel_map;         % [g/s]

eng.max_trq_vec = fc_max_trq(:);    % [Nm]
eng.min_trq_vec = -fc_ct_trq(:);    % negative drag torque

eng.inertia = fc_inertia;
eng.mass    = fc_mass;
eng.LHV     = fc_fuel_lhv;

% Function handles for HEV model
eng.maxTrq = @(w) interp1(eng.map_spd, eng.max_trq_vec, abs(w), 'linear','extrap');
eng.minTrq = @(w) interp1(eng.map_spd, eng.min_trq_vec, abs(w), 'linear','extrap');

eng.fuelRate = @(w,T) localFuelRate(eng, w, T);  % returns kg/s

end


% ==============================================================================
% Local fuel-rate interpolant (speed, torque) → kg/s
% ==============================================================================
function fr = localFuelRate(eng, w, T)
    wq = abs(w);
    Tq = max(T, 0);   % no fuel consumption for negative torque

    % Interpolate g/s → convert to kg/s
    g_per_s = interpn(eng.map_spd, eng.map_trq, eng.fuel_map, ...
                      wq, Tq, 'linear', 0);

    fr = g_per_s / 1000;  % convert to kg/s
end
