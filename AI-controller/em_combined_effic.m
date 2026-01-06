classdef em_combined_effic
    % default motor: PowerPhase 150 Data sheet. Unique Mobility, Continuous Power = 100kW, Peak Power = 150kW

    properties
        em_type = 'UQM PowerPhase 150 PMSM';
        inertia    		    = 0.02; 
        coeff_regen 	    = 1;
        volt_min			= 240; % (V), minimum voltage allowed by the controller and motor
        time_response	    = 0.05; 
        t_max_trq           = 250; % Time the motor can remain at max torque
        motor_mass          = 91;   %kg
        controller_mass     = 15.9; %kg
        curr_max    		= 500; % (A), maximum current allowed by the controller and motor
        spd_base			= 1000 *2*pi/60;% rad/s
        trq_idx1_spd      = [0:100:5000 5050 5100 5150]*2*pi/60;
        trq_cont_map 	    = [400 400 400 400 400 400 400 400 400 400 400 396 392 388 384 380 376 372 368 364 360  ...
                                356.5 353 349.5 346 342.5 339 335.5 332 328.5 325 318.5 312 305.5 299 292.5 286 279.5 273 266.5 260 ...
                                251.5 243 234.5 226 217.5 209 200.5 192 183.5 175 0 0 0]; % (N*m)
        trq_max_map      	= [650 650 650 650 650 650 650 650 650 650 650 640 630 619 608 597 ...
                                587 577 567 557 546 535 524 513 502 490 482 474 466 458 450  441 432 423 414 405 396 387 378 369 360 ...
                                352 344 336 328 320 313 306 299 292 285 0 0 0];
        % efficiency mapfv
        eff_trq_idx1_spd 		= [0:250:4500]*2*pi/60;
        eff_trq_idx2_trq 	    = [0:25:650];
        eff_trq_map		    = 0.01*[
                           64.6 64.6  74.1   76.4   75.8   76.5   75.9   74.9   74.4   73.5   72.7   72.6   71.7   70.4   69.8   68.4   67.6   66.8   65.6   65.1   64.1 63.6   62.1   61.5   60.6   62.0   60.7
                           64.6 64.6  74.1   76.4   75.8   76.5   75.9   74.9   74.4   73.5   72.7   72.6   71.7   70.4   69.8   68.4   67.6   66.8   65.6   65.1   64.1 63.6   62.1   61.5   60.6   62.0   60.7
                           63.6 63.6  77.2   80.1   81.7   82.8   83.1   82.9   82.8   82.3   82.1   82.2   81.6   80.8   80.5   79.6   79.1   78.6   77.7   77.5   76.8 76.0   74.5   74.6   74.2   75.0   74.1
                           62.3 62.3  78.0   82.1   83.6   85.2   85.8   86.0   85.9   86.1   85.2   85.9   85.7   84.9   84.7   84.2   83.9   83.6   83.1   82.4   82.2 81.7   81.0   80.5   80.6   81.0   80.2
                           63.8 63.8  78.2   82.7   85.2   86.2   87.1   87.7   87.7   87.9   87.8   87.9   86.2   87.3   87.3   87.2   86.8   86.4   86.3   85.8   85.5 85.2   84.8   84.6   84.1   84.6   83.9
                           65.1 65.1  79.0   83.6   86.2   87.3   88.1   88.6   88.4   89.3   88.4   89.2   89.3   89.4   89.4   88.9   88.9   88.3   88.3   87.8   87.9 87.4   87.2   87.9   87.0   87.1   88.0
                           65.9 65.9  80.1   84.1   85.7   88.3   88.8   89.6   90.2   90.3   90.6   89.9   90.9   90.5   90.3   90.2   90.1   89.9   89.2   89.8   89.9 89.4   89.4   89.1   89.0   89.1   89.2
                           66.0 66.0  80.6   85.3   85.9   88.2   89.9   89.2   91.1   91.5   91.1   91.4   91.4   91.2   91.2   91.3   91.1   91.1   91.4   91.3   91.0 91.6   91.4   90.3   90.1   91.2   91.4
                           66.3 66.3  80.3   85.8   87.6   89.2   90.4   91.4   91.6   92.2   92.1   92.2   92.2   92.4   92.4   92.4   92.7   92.8   92.9   92.9   92.8 92.9   92.5   92.3   92.2   92.1   91.6
                           64.4 64.4  80.6   85.4   87.4   89.4   90.9   91.2   91.7   91.8   92.1   92.4   92.9   93.0   93.0   93.1   93.1   93.1   93.2   93.0   93.1 93.0   92.2   92.1   92.1   91.8   91.8
                           64.6 64.6  77.4   84.7   86.3   89.7   90.8   91.8   92.2   92.8   93.4   93.9   93.5   94.3   93.1   93.2   95.3   95.2   95.2   95.0   95.2 95.1   94.6   94.9   94.9   94.9   94.9
                           64.5 64.5  79.2   85.3   86.7   89.3   90.9   91.8   93.0   94.0   94.6   94.5   94.7   95.0   95.1   95.4   95.4   95.5   95.4   95.0   95.2 95.2   95.2   95.2   95.2   95.2   95.2
                           63.4 63.4  78.7   84.8   87.5   90.0   91.4   92.3   92.9   94.4   94.9   94.2   95.2   95.0   95.4   95.3   95.5   95.5   95.0   95.0   95.0 95.0   95.0   95.0   95.0   95.0   95.0
                           63.9 63.9  78.7   84.6   88.0   89.9   91.4   91.9   93.4   94.5   94.8   94.9   94.8   95.3   95.0   95.5   95.3   95.1   94.9   94.9   94.9 94.9   94.9   94.9   94.9   94.9   94.9
                           63.5 63.5  78.1   84.2   87.7   89.9   91.5   92.8   93.4   93.4   94.6   94.4   94.7   93.9   94.8   95.0   95.1   95.0   95.0   95.0   95.0 95.0   95.0   95.0   95.0   95.0   95.0
                           61.4 61.4  77.3   84.3   87.8   89.8   91.3   92.2   93.5   94.3   94.1   93.8   94.6   95.0   94.4   94.2   94.2   94.2   94.2   94.2   94.2 94.2   94.2   94.2   94.2   94.2   94.2
                           61.0 61.0  77.0   83.5   86.7   89.7   91.0   92.0   93.1   93.2   93.9   93.8   93.6   93.3   93.5   93.8   93.8   93.8   93.8   93.8   93.8 93.8   93.8   93.8   93.8   93.8   93.8
                           60.7 60.7  76.0   83.3   86.5   89.5   90.6   91.7   92.6   92.9   93.4   93.5   93.7   93.7   93.8   93.8   93.8   93.8   93.8   93.8   93.8 93.8   93.8   93.8   93.8   93.8   93.8
                           58.9 58.9  75.6   82.7   86.6   88.9   90.6   91.6   92.2   92.8   92.7   93.5   93.6   93.6   93.6   93.6   93.6   93.6   93.6   93.6   93.6 93.6   93.6   93.6   93.6   93.6   93.6];
        % interpolation, run the init to generate the interpolation.
        effMap = 0;
        maxTrq = 0;
        minTrq = 0;
        mass = 0;

    end
    methods
        function obj = init(obj)
            obj.eff_trq_idx1_spd = [-fliplr(obj.eff_trq_idx1_spd(2:end)) obj.eff_trq_idx1_spd];
            obj.eff_trq_idx2_trq = [-fliplr(obj.eff_trq_idx2_trq(2:end)) obj.eff_trq_idx2_trq];
            obj.eff_trq_map      = [rot90(obj.eff_trq_map(2:end,2:end),2) flipud(obj.eff_trq_map(2:end,:));fliplr(obj.eff_trq_map(:,2:end)) obj.eff_trq_map];
            obj.effMap = griddedInterpolant({obj.eff_trq_idx1_spd, obj.eff_trq_idx2_trq}, obj.eff_trq_map);
            idx1_spd = [-fliplr(obj.trq_idx1_spd(2:end)) -eps 0 eps obj.trq_idx1_spd(2:end)];
            map = [fliplr(obj.trq_max_map(2:end))    obj.trq_max_map(2) -obj.trq_max_map(2) -obj.trq_max_map(2) -obj.trq_max_map(2:end)];
            obj.minTrq = griddedInterpolant(idx1_spd, map);
            map = -map;
            obj.maxTrq = griddedInterpolant(idx1_spd, map);
            obj.inertia = obj.inertia;
            obj.mass = obj.motor_mass + obj.controller_mass;
        end

        function obj = scale_pwr(obj,target_pwr_in_kW)
            sr = target_pwr_in_kW/max(obj.trq_max_map.*obj.trq_idx1_spd/1000);  % scale factor
            
            obj.motor_mass = obj.motor_mass * sr;
            obj.controller_mass = obj.controller_mass * sr;
            obj.curr_max = obj.curr_max * sr;
            obj.trq_cont_map = obj.trq_cont_map * sr;
            obj.trq_max_map = obj.trq_max_map * sr;
            obj.eff_trq_idx2_trq = obj.eff_trq_idx2_trq * sr;
        end
        function [inputPWR_kW, infeasible] = calc(obj, spd, trq, shaftAcc)
            % calculate the required power
            % spd: speed in rad/s
            % trq: torque in Nm
            % acc: acceleration in rad/s^2
            % Returns:
            % inputPWR_kW: 输入功率（千瓦）
            % infeasible: 指示操作参数是否不可行的标志
        
            shaftPwr = spd .* trq; % W
            % Electric Machine 
            shaftSpd = spd; % Electric machine 1 speed
            shaftTrq = (shaftSpd > 0) .* trq; % 轴转矩（Nm）
            pwtUnfeas = (shaftPwr < 0 & trq > 0); % 检查动力系统是否可行
        
            % EM
            % Electric motor efficiency
            emSpd = shaftSpd;
            emTrq = shaftTrq; % 电机转矩（Nm）
            emEff = (shaftSpd ~= 0) .* obj.effMap(emSpd, emTrq) + (shaftSpd == 0); % 电机效率
            % Calculate electric power consumption
            emElPwr = (emTrq < 0) .* emSpd .* emTrq .* emEff * 0.5 + (emTrq >= 0) .* emSpd .* emTrq ./ emEff;
            % Limit Torque
            emMaxTrq = obj.maxTrq(emSpd);
            emMinTrq = obj.minTrq(emSpd); % 电机最小转矩（Nm）
            % Constraints
            emUnfeas = (isnan(emEff)) + (emTrq < 0) .* (emTrq < emMinTrq) + ...
                       (emTrq >= 0) .* (emTrq > emMaxTrq);
            % Electric motor drag torque (Nm)
            emResTrq = shaftAcc .* obj.inertia;
            reqPwr = emElPwr + emResTrq .* emSpd; % 所需功率（W）
        
            % 设置返回值
            inputPWR_kW = reqPwr./1000;
            infeasible = (pwtUnfeas | emUnfeas); % 操作参数不可行性判断
        end
    end
end