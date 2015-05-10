function [discharged, stored] = optimized_behavior(overgeneration, prices, ...
                                 negativedemand, dischargingcap, energycap)
  % OPTIMIZED_BEHAVIOR Performs the linear optimization.
  global N_hours Efficiency
  
  %overgenmatrix = ones(N_hours);
  %overgenmatrix(1,1:N_hours) = overgenmatrix(1,1:N_hours) .* overgeneration;
  % 1st half discharge second half charge, the charging is free.
  f = zeros(2 * N_hours, 1); 
  f(1:N_hours) = -prices;  % Discharging

  A = zeros(2 * N_hours, 2 * N_hours);
  A(1:N_hours,1:N_hours) = -tril(ones(N_hours));  % Discharging cap
  A(1:N_hours,(1+N_hours):(2*N_hours)) = tril(ones(N_hours));  % Charging cap
  % Discharging floor
  A((1+N_hours):(2*N_hours),1:N_hours) = tril(ones(N_hours));
  %  Charging floor
  A((1+N_hours):(2*N_hours),(1+N_hours):(2*N_hours)) = -tril(ones(N_hours)); 
  b = [energycap * ones(N_hours, 1); zeros(N_hours, 1)];
  max_power = zeros([1 2*N_hours]);
  max_power(1:N_hours) = min(negativedemand(1:N_hours), dischargingcap);
  max_power(N_hours+1:2*N_hours) = overgeneration*Efficiency;
  options = optimset('LargeScale', 'on', 'Display', 'off', 'TolFun', 1e-6);
  discharged = linprog(f, A, b, [], [], zeros(1, 2 * N_hours), max_power, [], ...
                       options);
  stored = cumsum(discharged(1+N_hours:2*N_hours)) - ...
           cumsum(discharged(1:N_hours));
end
