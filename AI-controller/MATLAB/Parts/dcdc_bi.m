classdef dcdc_bi
    properties
        technology = 'None'; % the default bi-directional dcdc is scale up from a 100kW Boost Power Converter (passive cooling 50kW, active cooling 100kW)
        manfacture = 'turbopowersystems';
        ref = 'https://www.turbopowersystems.com/wp-content/uploads/2021/06/TPS-Next-Gen-DC-DC-Power-Converter-Module.pdf';
        powerIdx = [3500.0 7039.7 10286.0 14018.8 17205.9 20010.0 23253.0 26625.6 30021.9 33359.5 36608.8 40092.1 43643.7 46512.0 49550.8]; % W
        voltageIdx = 0;
        efficiencyMap = [0.8730 0.9106 0.9242 0.9442 0.9417 0.9499 0.9520 0.9538 0.9539 0.9566 0.9546 0.9552 0.9538 0.9480 0.9502];
        mass = 66; % kgs
        powerMax = 0;
        eff = 0;
    end

    methods
        function obj = init(obj)
            obj.powerMax = max(obj.powerIdx);
            obj.mass = obj.powerMax ./ 15.7/1000 + 20;  % 15.7 kW/kg, 31.4 kW/L, enclosure and cooling are to take into account
            % ref: Power-Dense Bi-Directional DC–DC Converters With High-Performance Inductors
            poweridx = [0,obj.powerIdx];
            map = [obj.efficiencyMap(1), obj.efficiencyMap];
            obj.eff = griddedInterpolant(poweridx,map,'linear','none'); % TODO: add one more dimension, voltage!
        end
        function [pwr_in, loss, infeasible] = pwr_calculation(obj, voltage_in, pwr_out)
            %%
            % This function calcualte  the dcdc power and loss
            % voltage_in:   the input voltage; V
            % pwr_in    :   DCDC input power, posotive means it is
            %               receiving power; W

            efficiency = obj.eff(abs(pwr_out));
            pwr_in = zeros(size(pwr_out));
            pwr_in(pwr_out>0) = pwr_out(pwr_out>0)  ./ efficiency(pwr_out>0);
            pwr_in(pwr_out<=0) = pwr_out(pwr_out<=0) .* efficiency(pwr_out<=0);
            
            loss = abs(pwr_in - pwr_out);
            infeasible = zeros(size(pwr_out));
            infeasible(abs(pwr_in)>obj.powerMax) = true;

            %% TODO: add one more dimension, voltage!
            % pwr_out   :   DCDC out put power, posotive means it is provinding
            %               power; W
        end
    end
end
