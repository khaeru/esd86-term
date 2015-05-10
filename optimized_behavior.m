function [charge, stored, savings] = optimized_behavior(gen, prices, demand, ...
                                                        cap)
  % OPTIMIZED_BEHAVIOR Performs the linear optimization.
  %    [charge, stored, savings] = OPTIMIZED_BEHAVIOR(gen, prices, demand, cap)
  %    determines the rate of charge ('charge' > 0) or discharge ('charge' < 0) 
  %    of an energy storage system in order to minimize the cost of electricity,
  %    according to 'prices' for each period. The storage has a capacity of
  %    'cap', and can be charged at a rate up to 'c_in' (global variable) or
  %    'gen', whichever is smaller. It can be discharged at a rate of 'c_out'
  %    (global variable) or 'demand', whichever is smaller. OPTIMIZED_BEHAVIOR
  %    also returns the total amount of energy 'stored' in each period, and
  %    the 'savings' due to use of storage.
  global N_hours Efficiency c_in c_out
 
  % Formulated as:  min f'*x  s.t.  A*x <= b  ,  0 <= x <= max_power
  %
  % The problem size is 2 × N_hours. x(1:N_hours) is positive to *discharge* the
  % battery; x(N_hours+1:end) is positive to *charge* the battery.
  
  % f -- cost function. Discharging the battery has a *negative* cost (savings)
  % equal to the price in that hour:
  f = zeros(2 * N_hours, 1); 
  f(1:N_hours) = -prices;

  A = zeros(2 * N_hours);
  % Discharging cap
  A(1:N_hours,1:N_hours) = -tril(ones(N_hours));
  % Charging cap
  A(1:N_hours,(1+N_hours):(2*N_hours)) = tril(ones(N_hours));
  % Discharging floor
  A((1+N_hours):(2*N_hours),1:N_hours) = tril(ones(N_hours));
  %  Charging floor
  A((1+N_hours):(2*N_hours),(1+N_hours):(2*N_hours)) = -tril(ones(N_hours)); 

  b = [cap * ones(N_hours, 1); zeros(N_hours, 1)];

  % Cannot have a negative discharge or charge rate
  min_power = zeros([1 2 * N_hours]);

  % Maximum discharge and charge rates
  max_power = zeros([1 2 * N_hours]);
  % Maximum discharge rate: either the engineering limit of the battery, or
  % the demand, whichever is smaller.
  max_power(1:N_hours) = min(demand, c_out);
  % Maximum charge rate: either the engineering limit of the battery, or the
  % amount of generation available for charging, whicheve is smaller.
  max_power(N_hours+1:2*N_hours) = min(gen, c_in) * Efficiency;
  
  % Optimize x
  options = optimset('LargeScale', 'on', 'Display', 'off', 'TolFun', 1e-6);
  [x, cost] = linprog(f, A, b, [], [], min_power, max_power, [], options);

  savings = -cost;

  % Combine back into a vector of length N_hours
  charge = -x(1:N_hours) + x(N_hours+1:2*N_hours);
    
  % Compute the amount of energy stored.
  stored = cumsum(charge);
end
