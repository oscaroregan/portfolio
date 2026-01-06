function [x_new, stageCost, unfeas, shaftPwr, shaftTrq, ...
          emElPwr, emSpd, emTrq, emMaxTrq, battLoss, ...
          battOutPwr, battCurr, battNewVoltage, ENG] = ...
          hev_car(x, u, w, vpa)
% HEV_CAR  Parallel hybrid electric vehicle model.
%
%   x{1} : battery SOC
%   u{1} : engine torque fraction (0..1)
%   w{1} : vehicle speed [m/s]
%   w{2} : vehicle acceleration [m/s^2]
%
%   vpa.batt, vpa.em, vpa.eng, vpa.gb, vpa.fd, vpa.veh, vpa.dcdc

%% ---- Default outputs (prevents MATLAB "not assigned" errors) ----
x_new          = x;
stageCost      = 0;
unfeas         = false;
shaftPwr       = 0;
shaftTrq       = 0;
emElPwr        = 0;
emSpd          = 0;
emTrq          = 0;
emMaxTrq       = 0;
battLoss       = 0;
battOutPwr     = 0;
battCurr       = 0;
battNewVoltage = 0;

ENG = struct('Trq',0,'Spd',0,'Pwr',0,'FuelRate',0);

%% -------- TIME STEP --------
dt = 1;

%% -------- VEHICLE DYNAMICS --------
vehSpeed = w{1};
vehAcc   = w{2};

wheelSpd = vehSpeed ./ vpa.veh.wh_radius;
wheelAcc = vehAcc   ./ vpa.veh.wh_radius;

rolling_friction = vpa.veh.mass .* vpa.veh.gravity .* ...
                  (vpa.veh.first_rrc + vpa.veh.second_rrc.*vehSpeed);

aeroForce      = vpa.veh.aero_coeff .* vehSpeed.^2;
inertialForce  = vpa.veh.mass .* vehAcc;

vehForce = (wheelSpd ~= 0) .* (rolling_friction + aeroForce + inertialForce);

wheelTrq = vehForce .* vpa.veh.wh_radius + vpa.veh.axle_loss .* (wheelSpd ~= 0);

%% -------- FINAL DRIVE --------
fdSpd = vpa.fd.spdRatio .* wheelSpd;
fdAcc = vpa.fd.spdRatio .* wheelAcc;

fdTrq = wheelTrq ./ vpa.fd.spdRatio;

%% -------- GEARBOX (2-speed, ADVISOR-style) --------

gb = vpa.gb;          % gearbox struct from vpa_init_hev
vehSpeed = w{1};      % [m/s]

% Simple speed-based “shifting”: 
% below spd_thr -> 1st gear, above spd_thr -> 2nd gear
if vehSpeed > gb.spd_thr
    gear_idx = 3;     % 2nd gear: gb.ratio.map(3) = 1.0
else
    gear_idx = 2;     % 1st gear: gb.ratio.map(2) = 1.86
end

% Active gear ratio
gbRatio = gb.ratio.map(gear_idx);   % scalar

% Efficiency – just use overall max for now
gbEff = gb.eff_max;   % or e.g. 0.97 if you want a fixed value

% Shaft speed & acceleration
shaftSpd = gbRatio .* fdSpd;        % [rad/s]
shaftAcc = gbRatio .* fdAcc;        % [rad/s^2]

% Torque into gearbox from final drive
fdTrqIn = fdTrq;

% Gearbox torque losses (simple constant-efficiency approximation)
gbLossTrq = (fdTrqIn>0)  .* (1-gbEff) .* fdTrqIn ./ (gbEff * gbRatio) + ...
            (fdTrqIn<=0).* (1-gbEff) .* fdTrqIn ./ gbRatio;

% Output shaft torque (into engine+motor shaft)
shaftTrq = fdTrqIn ./ gbRatio + gbLossTrq + gb.inertia .* shaftAcc;

% Shaft power
shaftPwr = shaftTrq .* shaftSpd;


%% -------- PARALLEL TORQUE SPLIT --------
posTrqReq = max(shaftTrq, 0);
negTrqReq = min(shaftTrq, 0);

alpha_eng = 0;
if numel(u)>=1
    alpha_eng = min(max(u{1},0),1);
end

engTrq = (shaftSpd>0).* (alpha_eng .* posTrqReq);
emTrq  = (shaftSpd>0).* ((1-alpha_eng).*posTrqReq + negTrqReq);

pwtUnfeas = (shaftPwr<0 & emTrq>0);

%% -------- ENGINE MODEL --------
engSpd = shaftSpd;

engMaxTrq = vpa.eng.maxTrq(engSpd);
engMinTrq = vpa.eng.minTrq(engSpd);

engUnfeas = (engTrq < engMinTrq) | (engTrq > engMaxTrq);

engPwr = engTrq .* engSpd;
engFuelRate = vpa.eng.fuelRate(engSpd, engTrq); % kg/s

% Pack engine outputs (fixes your simulation loop)
ENG.Trq      = engTrq;
ENG.Spd      = engSpd;
ENG.Pwr      = engPwr;
ENG.FuelRate = engFuelRate;

%% -------- ELECTRIC MOTOR --------
emSpd = shaftSpd;

emEff = (emSpd~=0).*vpa.em.effMap(emSpd,emTrq) + (emSpd==0);

emMaxTrq = vpa.em.maxTrq(emSpd);
emMinTrq = vpa.em.minTrq(emSpd);

emUnfeas = isnan(emEff) | ...
           ((emTrq<0)&(emTrq<emMinTrq)) | ((emTrq>=0)&(emTrq>emMaxTrq));

emResTrq = shaftAcc .* vpa.em.inertia;

emMechPwr = emTrq .* emSpd;
emElPwr = (emTrq<0).*(emMechPwr.*emEff) + ...
          (emTrq>=0).*(emMechPwr./emEff);

reqPwr = emElPwr + emResTrq .* emSpd;

propPwr  = (shaftSpd>0).*(reqPwr>0).*reqPwr;
brakePwr = (shaftSpd>0).*(reqPwr<=0).*reqPwr;

accessoryPwr = 700;

reqPwr = propPwr + brakePwr + accessoryPwr;

%% -------- BATTERY & DCDC --------
dcdcReqPwr = reqPwr;

[battReqPwr, dcdcLoss, dcdcUnFeas] = vpa.dcdc.pwr_calculation(0,dcdcReqPwr);

battColEff = (battReqPwr>0) + (battReqPwr<=0).*vpa.batt.coulombic_eff;

battR = (battReqPwr>0).*vpa.batt.dischrgRes(x{1}) + ...
        (battReqPwr<=0).*vpa.batt.chrgRes(x{1});

battOcvVoltage = vpa.batt.ocv(x{1});

disc = battOcvVoltage.^2 - 4.*battR.*battReqPwr;
disc(disc<0)=0;

battCurr = battColEff .* (battOcvVoltage - sqrt(disc)) ./ (2.*battR);
battCurr = real(battCurr);

battNewVoltage = battOcvVoltage - abs(battCurr.*battR);
battOutPwr     = battNewVoltage .* battCurr;

maxChrgBattCurr = (battReqPwr<=0).*vpa.batt.minCurr(x{1});
maxBattDisPwr   = (battReqPwr>0).*vpa.batt.maxPwr(x{1});

x_new{1} = x{1} - battCurr ./ (vpa.batt.cap * 3600) .* dt;

battUnfeas = (battReqPwr<=0).*(battCurr < maxChrgBattCurr) + ...
             (battReqPwr>0) .*(battReqPwr > maxBattDisPwr);

%% -------- STAGE COST --------
battLoss = battCurr.^2 .* battR;
stageCost = engFuelRate * vpa.eng.LHV;   % J/s

%% -------- INFEASIBILITY --------
unfeas = logical(pwtUnfeas | emUnfeas | battUnfeas | dcdcUnFeas | engUnfeas);

if x_new{1} < 0.15 || x_new{1} > 0.95
    unfeas = true;
end

end
