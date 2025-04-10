vmax = [200,200];%max SPS allowed by stepper and mcu
amax = [2500,2500]; %max SPSPS allowed by stepper and mcu
J = [3000,3000]; %jerk
s = [60,110]; %steps

number_of_profiles = 2;

delay = cell(1,number_of_profiles);

for profile = 1:number_of_profiles 

    va = amax(profile)^2 / J(profile); %max value of speed reached during point-to-point
    sa = 2*amax(profile)^3 / J(profile)^2; %value of stroke if amax reached
    sv_1 = 2*vmax(profile) * sqrt(vmax(profile)/J(profile)); %value of stroke if case 1 and vmax reached 
    sv_2 =  vmax(profile) *((vmax(profile)/amax(profile)) + (amax(profile)/J(profile))); %value of stroke if case 2 and vmax reached 
        
    if(vmax(profile) < va && s(profile) > sa)
        tj = sqrt(vmax(profile)/J(profile));
        tv = s(profile)/vmax(profile);
        ta = tj;
    elseif (vmax(profile) > va && s(profile) < sa)
        tj = (s(profile)/(2*J(profile)))^(1/3);
        ta = tj;
        tv = 2*tj;
    elseif(vmax(profile) < va && s(profile) < sa)
        if (s(profile) > sv_1)
            tj = sqrt(vmax(profile)/J(profile));
            tv = s(profile)/vmax(profile);
            ta = tj;
        else
            tj = (s(profile)/(2*J(profile)))^(1/3);
            ta = tj;
            tv = 2*tj;
        end 
    else
        if (s(profile) > sv_2)
            tj = amax(profile)/J(profile);
            ta = vmax(profile)/amax(profile);
            tv = s(profile)/vmax(profile);
        else
            tj = amax(profile)/J(profile);
            ta = 0.5*(sqrt((4*s(profile)*J(profile)^2 + amax(profile)^3)/(amax(profile)*J(profile)^2)) - amax(profile)/J(profile));
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
    
    a1 = J(profile) * t1;
    v1 = J(profile) * (t1^2) / 2;
    p1 = J(profile) * (t1^3) / 6;
    a2 = a1;
    v2 = v1 + a1 * (t2 - t1);
    p2 = p1 + v1 * (t2 - t1) + a1 * ((t2 - t1)^2) / 2;
    a3 = 0;
    v3 = v2 + a2 * (t3 - t2) - J(profile) * ((t3 - t2)^2) / 2;
    p3 = p2 + v2 * (t3 - t2) + a2 * ((t3 - t2)^2) / 2 - J(profile) * ((t3 - t2)^3) / 6;
    a4 = 0; 
    v4 = v3; 
    p4 = p3 + v3 * (t4 - t3);
    a5 = -a1; 
    v5 = v4 - J(profile) * ((t5 - t4)^2) / 2; 
    p5 = p4 + v4 * (t5 - t4) - J(profile) * ((t5 - t4)^3) / 6;
    a6 = a5; 
    v6 = v5 - amax(profile) * (t6 - t5); 
    p6 = p5 + v5 * (t6 - t5) + a5 * ((t6 - t5)^2) / 2;

    i = 1;  
    k = 0.0001;
    v = NaN(1,round(t7/k));
    p = NaN(1,round(t7/k));

    for  t = 0:k:t7
        if (t >= 0 && t < t1)
            v(i) = J(profile) * (t^2) / 2;
            p(i) = J(profile) * (t^3) / 6;
        elseif (t >= t1 && t < t2)
            v(i) = v1 + a1 * (t - t1);
            p(i) = p1 + v1 * (t - t1) + a1 * ((t - t1)^2) / 2;
        elseif (t>= t2 && t < t3)
            v(i) = v2 + a2 * (t - t2) - J(profile) * ((t - t2)^2) / 2;
            p(i) = p2 + v2 * (t - t2) + a2 * ((t - t2)^2) / 2 - J(profile) * ((t - t2)^3) / 6;
        elseif (t >= t3 && t < t4)
            v(i) = v3;
            p(i) = p3 + v3 * (t - t3);
        elseif (t >= t4 && t < t5)
            v(i) = v4 - J(profile) * ((t - t4)^2) / 2;
            p(i) = p4 + v4 * (t - t4) - J(profile) * ((t - t4)^3) / 6;
        elseif (t >= t5 && t < t6)
            v(i) = v5 - amax(profile) * (t - t5);
            p(i) = p5 + v5 * (t - t5) + a5 * ((t - t5)^2) / 2;
        elseif (t >= t6 && t < t7)
            v(i) = v6 + a6 * (t - t6) + J(profile) * ((t - t6)^2) / 2;
            p(i) = p6 + v6 * (t - t6) + a6 * ((t - t6)^2) / 2 + J(profile) * ((t - t6)^3) / 6;
        end
        i = i + 1;
    end

    t_vec = linspace(0, t7, length(v));

    % Plot velocity for the current profile
    figure(profile);
    plot(t_vec, v, 'LineWidth', 1.5);
    title(sprintf('Velocity Profile %d', profile));
    xlabel('Time [s]');
    ylabel('Velocity [steps/s]');
    grid on;
    
    index = 1; % Initialize index
    previous_index = 1; % Start from the first index
    final_delay = 0;
    delay_index = 1;

    for position = 1:s(profile)-5 %half stepped
        % Find the index of the closest value in p to 'position'
        [~, index] = min(abs(p - position));
        
        if(position > 5)
        % Compute delay as the difference between current and previous indices
        delay{profile}(delay_index) = index - previous_index;
        final_delay = final_delay + (index - previous_index);
        delay_index = delay_index + 1;
        end
        % Update previous index for the next iteration
        previous_index = index;
    end 
end

% Find the maximum length among all delay profiles
max_length = max(cellfun(@length, delay));

% Open a new file to write the C array
fileID = fopen('delay_profile.h', 'w');

% Write the C array to the file
fprintf(fileID, 'const float delay_profile[%d][%d] = {\n', number_of_profiles, max_length);
for profile = 1:number_of_profiles
    % Pad the array with zeros if it's shorter than max_length
    padded_delay = [delay{profile}, zeros(1, max_length - length(delay{profile}))];

    fprintf(fileID, '    {');
    fprintf(fileID, '%f, ', padded_delay(1:end-1));
    fprintf(fileID, '%f},\n', padded_delay(end));
end
fprintf(fileID, '};\n');
fclose(fileID);
