function [totalcost, excess, total_basic_cost, total_renew_cost]...
    = household(number_batteries, save_plots)
  % HOUSEHOLD  Simulate the household's energy storage situation.
  %   totalcost = household()
  %   totalcost = household(save_plots)
  %     Save files 'power.svg' and 'netdemand.svg' if save_plots is true
  %     (default: false).
  global N_hours mu_d sigma_d lambda_w k_w e_max c_in c_out
  
  if nargin < 2
    save_plots = false;
  end
  
  hours = 1:N_hours;

  % Draw from the distributions
  D = demand(mu_d, sigma_d);
  V = wind(lambda_w, k_w, 'simple');
  G = generation(V);
  P = agg_price(price());
  
  % Compute net demand
  netdemand = D - G;

  % Creates an hourly matrix of when energy is available for storage.
  overgeneration = max(0, -netdemand);
  overgeneration(overgeneration > c_in) = c_in;

  % Demand unmet by generation
  negativedemand = max(0, netdemand);

  [discharged, stored] = optimized_behavior(overgeneration, P, ...
                                            negativedemand, c_out, ...
                                            number_batteries * e_max);

  % Integrate negative-demand hours -> battery storage
  excess = -sum(max(0, netdemand));
  
  % Compute electricity cost for no renewables
  basic_cost = D .* P;
  total_basic_cost = sum(basic_cost);
  
  % Compute electricity cost with renewables non storage
  renew_cost = max(0, netdemand) .* P;
  total_renew_cost = sum(renew_cost);
 
  % Compute electricity cost with storage
  cost(1:N_hours) = max(0, netdemand) .* P - discharged(1:N_hours)'.*P;
  totalcost = sum(cost);

  %save('test.mat');

  if logical(save_plots)
    H = newfig();
    xlabel('Time (hour)');
    ylabel('Power (kW)');
    plot(hours(1:60), D(1:60), 'b', ...
         hours(1:60), G(1:60), 'g', ...
         hours(1:60), netdemand(1:60), 'r', ...
         hours(1:60), zeros([1 60]), 'k:', 'LineWidth', 4);
    legend('Demand', 'Generation', 'Net Demand');
    savefig_(H, 'netdemand_lines');
    
    H = newfig();
    xlabel('Time (hour)');
    ylabel('Energy (kW·h)');
    plot(hours, stored, 'b', ...
         hours, overgeneration, 'r', ...
         hours, ones([1 N_hours]) * e_max * number_batteries, 'k:', ...
         'Linewidth', 4);
    legend('Storage', 'Over Generation', 'Energy Capacity');
    savefig_(H, 'storage_use_withgen');
    
    H = newfig();
    xlabel('Time (hour)');
    ylabel('Energy (kW·h)');
    plot(hours, stored, 'b', ...
         hours, ones([1 N_hours]) * e_max * number_batteries, 'k:', ...
         'LineWidth', 4);
    legend('Storage', 'Energy Capacity');
    savefig_(H, 'storage_use');
  end
end
