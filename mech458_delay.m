vmax = [1000,1000];%max SPS allowed by stepper and mcu
amax = [150000,150000]; %max SPSPS allowed by stepper and mcu
J = [150000,150000]; %jerk
s = [50,100]; %steps

number_of_profiles = 2;

delay = cell(1,number_of_profiles);
velocity_threshold = 50; % Velocity threshold for trimming

for p = 1:number_of_profiles 

    va = amax(p)^2 / J(p); %max value of speed reached during point-to-point
    sa = 2*amax(p)^3 / J(p)^2; %value of stroke if amax reached
    sv_1 = 2*vmax(p) * sqrt(vmax(p)/J(p)); %value of stoke if case 1 and vmax reached 
    sv_2 =  vmax(p) *((vmax(p)/amax(p)) + (amax(p)/J(p)));%value of stoke if case 2 and vmax reached 
        
    if(vmax(p) < va && s(p) > sa)
        tj = sqrt(vmax(p)/J(p));
        tv = s(p)/vmax(p);
        ta = tj;
    elseif (vmax(p) > va && s(p) < sa)
        tj = (s(p)/(2*J(p)))^(1/3);
        ta = tj;
        tv = 2*tj;
    elseif(vmax(p) < va && s(p) < sa)
        if (s(p) > sv_1)
            tj = sqrt(vmax(p)/J(p));
            tv = s(p)/vmax(p);
            ta = tj;
        else
            tj = (s(p)/(2*J(p)))^(1/3);
            ta = tj;
            tv = 2*tj;
        end 
    else
        if (s(p) > sv_2)
            tj = amax(p)/J(p);
            ta = vmax(p)/amax(p);
            tv = s(p)/vmax(p);
        else
            tj = amax(p)/J(p);
            ta = 0.5*(sqrt((4*s(p)*J(p)^2 + amax(p)^3)/(amax(p)*J(p)^2)) - amax(p)/J(p));
            tv = ta + tj;
        end 
    end
    
    t1 = tj;
    t2 = ta;
    t3 = tj + ta;
    t4 = tv;
    t5 = tj + tv;
    t6 = tv + ta;
    t7 = tv + ta + tj;
    
    a1 = J(p) * t1;
    v1 = J(p) * (t1^2) / 2;
    a2 = a1;
    v2 = v1 + a1 * (t2 - t1);
    a3 = 0;
    v3 = v2 + a2 * (t3 - t2) - J(p) * ((t3 - t2)^2) / 2;
    a4 = 0; 
    v4 = v3; 
    a5 = -a1; 
    v5 = v4 - J(p) * ((t5 - t4)^2) / 2; 
    a6 = a5; 
    v6 = v5 - amax(p) * (t6 - t5); 

    v = NaN(1,1000);
    i = 1;  
    k = 0.001;

    for  t = 0:k:t7
        if (t >= 0 && t < t1)
            v(i) = J(p) * (t^2) / 2;
        elseif (t >= t1 && t < t2)
            v(i) = v1 + a1 * (t - t1);
        elseif (t>= t2 && t < t3)
            v(i) = v2 + a2 * (t - t2) - J(p) * ((t - t2)^2) / 2;
        elseif (t >= t3 && t < t4)
            v(i) = v3;
        elseif (t >= t4 && t < t5)
            v(i) = v4 - J(p) * ((t - t4)^2) / 2;
        elseif (t >= t5 && t < t6)
            v(i) = v5 - amax(p) * (t - t5);
        elseif (t >= t6 && t < t7)
            v(i) = v6 + a6 * (t - t6) + J(p) * ((t - t6)^2) / 2;
        end
        i = i + 1;
    end
     % Trim the velocity profile to remove values < 200
    valid_indices = find(v >= velocity_threshold); % Find indices where velocity >= 200
    if isempty(valid_indices)
        error('No values >= %d found in velocity array for profile %d.', velocity_threshold, p);
    end
    v_trimmed = v(valid_indices(1):valid_indices(end)); % Trim the velocity profile

    % Convert the trimmed velocity profile to delays
    delays = 10000 ./ v_trimmed; % Convert velocity (SPS) to delay (microseconds)
    delays(isinf(delays)) = 0; % Handle infinite delays (if v = 0)

    % Store delays in the cell array
    delay{p} = delays;
end

% Open a new file to write the C array
fileID = fopen('delay_profile.h', 'w');

% Write the C array to the file
fprintf(fileID, 'const float delay_profile[%d][%d] = {\n', number_of_profiles, length(delay{1}));
for p = 1:number_of_profiles
    fprintf(fileID, '    {');
    fprintf(fileID, '%f, ', delay{p}(1:end-1));
    fprintf(fileID, '%f},\n', delay{p}(end));
end
fprintf(fileID, '};\n');
fclose(fileID);