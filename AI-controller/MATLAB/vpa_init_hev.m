function vpa = vpa_init_hev(vpa)
% VPA_INIT_HEC  Initialize vehicle, gearbox, final drive for a
%               performance-oriented parallel HEV.

%% Gearbox: single-speed, fairly short ratio, good efficiency

gb.technology        = '2 DM';
gb.inertia   		= 0.003;			% kg m^2
gb.mass  				= 75.0;				%kg
gb.spd_thr  			= 10;
gb.nb_ratio            = 2;
gb.ratio.idx1_gear          = [0,1,2];
gb.ratio.map           = [0, 1.86, 1];

gb.eff_trq_idx1_trq =    [51.40,52.40,104.7,157.1,209.4,261.8,314.2,366.5,418.9,471.2,523.6];
gb.trq_in_max = max(gb.eff_trq_idx1_trq);

% input trq in Nm
gb.eff_trq.idx2_spd = [	0.500,6.000,33.90,67.80,101.7,135.6,169.5,203.4,237.3,271.2,305.1,339];% input speeds in rd/s

gb.eff_trq_ratio1.map = ...		% Gear1 Efficiencies
[   0.8282    0.8282    0.9114    0.9171    0.9190    0.9190    0.9190    0.9181    0.9171    0.9162    0.9152    0.9143
    0.8282    0.8282    0.9114    0.9171    0.9190    0.9190    0.9190    0.9181    0.9171    0.9162    0.9152    0.9143
    0.8301    0.8301    0.9114    0.9181    0.9190    0.9190    0.9190    0.9181    0.9171    0.9162    0.9152    0.9143
    0.8320    0.8320    0.9123    0.9181    0.9190    0.9190    0.9190    0.9181    0.9171    0.9162    0.9152    0.9143
    0.8339    0.8339    0.9123    0.9181    0.9190    0.9190    0.9190    0.9181    0.9171    0.9171    0.9162    0.9152
    0.8358    0.8358    0.9133    0.9181    0.9200    0.9200    0.9190    0.9181    0.9181    0.9171    0.9162    0.9152
    0.8378    0.8378    0.9133    0.9190    0.9200    0.9200    0.9190    0.9190    0.9181    0.9171    0.9162    0.9152
    0.8397    0.8397    0.9133    0.9190    0.9200    0.9200    0.9190    0.9190    0.9181    0.9171    0.9162    0.9152
    0.8416    0.8416    0.9143    0.9190    0.9200    0.9200    0.9200    0.9190    0.9181    0.9171    0.9162    0.9152
    0.8435    0.8435    0.9143    0.9190    0.9200    0.9200    0.9200    0.9190    0.9181    0.9171    0.9162    0.9152
    0.8454    0.8454    0.9143    0.9200    0.9210    0.9200    0.9200    0.9190    0.9181    0.9171    0.9162    0.9152];

gb.eff_trq_ratio2.map = ...		% Gear2 Efficiencies
[   0.8285    0.8285    0.9391    0.9470    0.9480    0.9480    0.9470    0.9460    0.9451    0.9441    0.9421    0.9411
    0.8285    0.8285    0.9391    0.9470    0.9480    0.9480    0.9470    0.9460    0.9451    0.9441    0.9421    0.9411
    0.8295    0.8295    0.9391    0.9470    0.9480    0.9480    0.9470    0.9460    0.9451    0.9441    0.9421    0.9411
    0.8305    0.8305    0.9391    0.9470    0.9480    0.9480    0.9480    0.9470    0.9451    0.9441    0.9421    0.9411
    0.8315    0.8315    0.9391    0.9470    0.9490    0.9490    0.9480    0.9470    0.9451    0.9441    0.9431    0.9411
    0.8325    0.8325    0.9401    0.9470    0.9490    0.9490    0.9480    0.9470    0.9460    0.9441    0.9431    0.9411
    0.8335    0.8335    0.9401    0.9480    0.9490    0.9490    0.9480    0.9470    0.9460    0.9441    0.9431    0.9411
    0.8345    0.8345    0.9401    0.9480    0.9490    0.9490    0.9480    0.9470    0.9460    0.9441    0.9431    0.9411
    0.8354    0.8354    0.9401    0.9480    0.9490    0.9490    0.9480    0.9470    0.9460    0.9451    0.9431    0.9421
    0.8364    0.8364    0.9401    0.9480    0.9490    0.9490    0.9480    0.9470    0.9460    0.9451    0.9431    0.9421
    0.8374    0.8374    0.9411    0.9480    0.9500    0.9490    0.9490    0.9470    0.9460    0.9451    0.9431    0.9421]; 

%Add zero torque to the torque index 
if min(gb.eff_trq_idx1_trq)>0
    for cpt=1:gb.nb_ratio,
        eval(['gb.eff_trq_ratio',num2str(cpt),'.map = [gb.eff_trq_ratio',num2str(cpt),'.map(1,:);gb.eff_trq_ratio',num2str(cpt),'.map];']); 
    end
    gb.eff_trq_idx1_trq=[0,gb.eff_trq_idx1_trq];
end


for cpt=1:gb.nb_ratio,
    gb.eff_trq.map(:,:,cpt) = eval(['gb.eff_trq_ratio',num2str(cpt),'.map']);%create the 3 dimensions (trq, spd, ratio) map for trq loss
end
% calculate the torque losses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
gb.trq_loss.idx1_trq = gb.eff_trq_idx1_trq;
gb.trq_loss.idx2_spd = gb.eff_trq.idx2_spd;
gb.trq_loss.idx3_gear = gb.ratio.idx1_gear(2:end);
gb.coeff = gb.eff_trq_idx1_trq(:)*ones(1,length(gb.eff_trq.idx2_spd));
for cpt=1:gb.nb_ratio,
    eval(['gb.trq_loss_ratio',num2str(cpt),'.map = (1 - gb.eff_trq_ratio',num2str(cpt),'.map) .* gb.coeff;']);%calculate trq loss per ratio
    gb.trq_loss.map(:,:,cpt) = eval(['gb.trq_loss_ratio',num2str(cpt),'.map']);%create the 3 dimensions (trq, spd, ratio) map for trq loss
    gb.effMapData(:,:,cpt) = eval(['gb.eff_trq_ratio',num2str(cpt),'.map']); %create the 3 dimensions (trq, spd, ratio) map for trq efficiency
end

% calculate the maximum efficiency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for cpt=1:gb.nb_ratio,
   gb.eff(cpt)=max(max(eval(['gb.eff_trq_ratio',num2str(cpt),'.map'])));
end
gb.eff_max=max(gb.eff);
clear cpt
gb.effMap = griddedInterpolant({gb.eff_trq.idx2_spd, gb.eff_trq_idx1_trq, 1:2}, gb.effMapData); % [speed, torque, gear] ---> efficiency
gb.shift_time          = 0.6;

vpa.gb = gb;


%% Final drive

fd.spdRatio = 3.5;      % final drive ratio
fd.loss     = 0;        % [Nm] constant loss (simplified)
fd.inertia  = 0.0;      % [kg m^2]
fd.mass     = 35;       % [kg]

vpa.fd = fd;

%% Vehicle body (sporty compact / sedan)

veh.gravity     = 9.81;    % [m/s^2]
veh.air_density = 1.2;     % [kg/m^3]

% Approx "glider" (body w/o powertrain)
veh.glider_mass = 1200;    % [kg]
veh.cargo_mass  = 80;      % [kg] driver + luggage

veh.CD = 0.29;             % drag coefficient
veh.FA = 2.2;              % frontal area [m^2]

veh.aero_coeff = 0.5 .* veh.air_density .* veh.CD .* veh.FA;

% Rolling resistance
veh.first_rrc  = 0.010;    % [-]
veh.second_rrc = 0.00010;  % [s/m]

% Wheels
veh.wh_radius  = 0.32;     % [m] ~ 17–18" performance tire
tireMass       = 20;       % [kg] per wheel approx
veh.wh_inertia = tireMass * veh.wh_radius^2 / 2;

% Axle loss vs mass (rough scaling)
wh_axle_loss_mass = [0   1000  1500 2000 2500];    % [kg]
wh_axle_loss_trq  = [2    6     10   15   20];     % [Nm]

% Provisional mass before adding components
veh.mass = veh.glider_mass + veh.cargo_mass;
veh.axle_loss = interp1(wh_axle_loss_mass, wh_axle_loss_trq, veh.mass, 'linear', 'extrap');

vpa.veh = veh;

%% Recompute total vehicle mass including all components

listComp = string(fieldnames(vpa));
massTotal = 0;

for k = 1:numel(listComp)
    comp = vpa.(listComp(k));
    if isstruct(comp) && isfield(comp, 'mass')
        massTotal = massTotal + comp.mass;
    elseif isobject(comp) && isprop(comp, 'mass')
        massTotal = massTotal + comp.mass;
    end
end

vpa.veh.mass = massTotal;

% Update axle loss based on final mass
vpa.veh.axle_loss = interp1(wh_axle_loss_mass, wh_axle_loss_trq, ...
                            vpa.veh.mass, 'linear', 'extrap');
end
