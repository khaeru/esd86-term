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
  
  % Draw from the distributions
  D = demand(mu_d, sigma_d);
  V = wind(lambda_w, k_w, 'simple');
  G = generation(V);
  P = agg_price(price());
  
  % Compute net demand
  netdemand = D - G;
  % Creates an hourly matrix of when energy is available for storage.
  overgen = max(0, -netdemand);
  % Demand unmet by generation
  unmet = max(0, netdemand);

  [charge, stored, savings] = optimized_behavior(overgen, P, unmet, ...
                                                 number_batteries * e_max);
                                               
  % Integrate negative-demand hours -> battery storage
  excess = -sum(unmet);
  
  % Compute electricity cost for no renewables
  basic_cost = D .* P;
  total_basic_cost = sum(basic_cost);
  
  % Compute electricity cost with renewables non storage
  renew_cost = unmet .* P;
  total_renew_cost = sum(renew_cost);
 
  % Compute electricity cost with storage
  totalcost = total_renew_cost - savings;

  %save('test.mat');
  
  if logical(save_plots)
    hours = 1:N_hours;

    H = newfig();
    xlabel('Time (hour)');
    ylabel('Power (kW)');
    plot(hours, D, 'b', ...
         hours, -G, 'g', ...
         hours, netdemand, 'r', ...
         hours, -min(overgen, c_in), 'y', ...
         hours, -charge, 'k.', ...
         'LineWidth', 2, 'MarkerSize', 15);
    legend('Demand', 'Generation', 'Net Demand', 'Available for storage', ...
           'Stored/discharged', 'Location', 'Best');
    % Only display three days, less spiky
    xlim([0 72]);
    % Reference lines
    plot([1 N_hours], [0 0], 'k:', ...
         [1 N_hours], -c_in * [1 1], 'k:', ...
         [1 N_hours], c_out * [1 1], 'k:');
    savefig_(H, strcat('power', num2str(number_batteries)));
        
    H = newfig();
    xlabel('Time (hour)');
    ylabel('Energy (kW·h)');
    plot(hours, stored, 'b', ...
         hours(overgen > 0), min(overgen(overgen > 0), c_in), 'y.', ...
         hours(charge > 0), charge(charge > 0), 'k.', ...
         'Linewidth', 4, 'MarkerSize', 30);
    legend('Battery state of charge', 'Energy available for storage', ...
           'Energy stored');
    % Reference line
    plot([1 N_hours], e_max * number_batteries * [1 1], 'k:');
    xlim([0 72]);
    savefig_(H, strcat('storage_use_withgen', num2str(number_batteries)));
    
%     % currently unused
%     H = newfig();
%     xlabel('Time (hour)');
%     ylabel('Energy (kW·h)');
%     plot(hours, stored, 'b', 'LineWidth', 4);
%     legend('Storage');
%     % Reference line
%     plot([1 N_hours], e_max * number_batteries * [1 1], 'k:');
%     xlim([0 72]);
%     savefig_(H, strcat('storage_use', num2str(number_batteries)));
  end
end
