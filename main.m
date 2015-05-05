% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>

function main(cmd)
  % MAIN Entry points for the household storage model
  %    MAIN(cmd) runs the model in the configuration given by cmd; valid values
  %    are 'mc', 'single' and 'prices'.

  globals
  switch cmd
    case 'mc'
      % Run a Monte Carlo simulation with 500 draws, and plot a histogram
      montecarlo(500)
  
    case 'single'
      % Run a single simulation, saving the plots
      household(true,1)

    case 'prices'
      % Generate a plot contrasting different price aggregation levels
      P = price();
      P1 = agg_price(P, 1, 1);
      P2 = agg_price(P, 4, 1);
      P3 = agg_price(P, 6, 4);
      P4 = agg_price(P, 24, 1);
      x = 1:size(P, 2);
      global N_hours;
      hours = 1:N_hours;
      [x1, y1] = stairs((hours' - 1) * 60, P1);
      [x2, y2] = stairs((hours' - 1) * 60, P2);
      [x3, y3] = stairs((hours' - 1) * 60, P3);
      [x4, y4] = stairs((hours' - 1) * 60, P4);

      H = newfig();
      plot(x, P)
      plot(x1, y1, x2, y2, x3, y3, x4, y4, 'LineWidth', 3);
      savefig_(H, 'price_example');
  end
end


function globals
  % GLOBALS  Set global parameters for the household problem.

  global N_days N_hours mu_d sigma_d k_w lambda_w V_cutin V_rated V_cutout ...
    G_max Fontsize

  % Time dimension
  N_days = 7;
  N_hours = 24 * N_days;
  % Normal distribution for the random part of demand
  mu_d = 0;
  sigma_d = 13;
  % Weibull distribution of wind speed
  k_w = 2;
  lambda_w = 8;
  % Engineering parameters for the wind turbine
  V_cutin = 3;
  V_rated = 12;
  V_cutout = 25;
  G_max = 3.8;
  % Style of plots
  Fontsize = 20;
end


function montecarlo(N)
  % MONTECARLO Monte Carlo simulation of the households.
  number_batteries = [1 2 3 4 5];

  totalcost = zeros([length(number_batteries) N]);
  excess = zeros([length(number_batteries) N]);
  total_basic_cost = zeros([length(number_batteries) N]);
  total_renew_cost = zeros([length(number_batteries) N]);
  cost_mean = zeros([N 3]);
  cost_variance = zeros([N 3]);
  for i = 1:length(number_batteries)
    for draw = 1:N
      [totalcost(i,draw), excess(i,draw), total_basic_cost(i,draw), ...
        total_renew_cost(i,draw)] = household([],number_batteries(i));
    end

    cost_mean(i,1) = mean(total_basic_cost(i,:));
    cost_mean(i,2) = mean(total_renew_cost(i,:));
    cost_mean(i,3) = mean(totalcost(i,:));
    cost_variance(i,1) = var(total_basic_cost(i,:));
    cost_variance(i,2) = var(total_renew_cost(i,:));
    cost_variance(i,3) = var(totalcost(i,:));
  end
    
  totalcost_sort = sort(totalcost,2);
  excess_sort = sort(excess,2);
  total_basic_cost_sort = sort(total_basic_cost,2);
  total_renew_cost_sort = sort(total_renew_cost,2);
      
  renewline = sort(total_renew_cost(:));
  renewline = renewline';
  basicline = sort(total_basic_cost(:));
  basicline = basicline';

  Battery_annuity = 3.4;
  Batt_ann_matrix = Battery_annuity * repmat(number_batteries',1,N);
  X = 1/N:1/N:1;
  X_diff = 1/(N-1):1/(N-1):1;
  Y = 1/(N*i):1/(N*i):1;
  Y_diff = 1/(N*i-1):1/(N*i-1):1;
  save('test.mat');

  H = newfig();
  histogram(totalcost)
  savefig_(H, 'costs_mc');
  
  H = newfig();
  histogram(excess)
  savefig_(H, 'excess_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline, Y, renewline, Y, totalcost_sort, X, 'LineWidth', 4);
  legend({'Cost without renewables', 'Cost with only renewables', ...
         'Cost with 1 Battery', 'Cost with 2 Batteries', ...
         'Cost with 3 Batteries', 'Cost with 4 Batteries', ...
         'Cost with 5 Batteries'}, 'Location', 'NorthEast');
  savefig_(H,'cdf_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline(1:N*i-1), diff(Y) ./ diff(basicline), ...
       renewline(1:N*i-1), diff(Y) ./ diff(renewline), 'LineWidth', 4);
  plot(totalcost_sort(1,1:N-1), diff(X) ./ diff(totalcost_sort(1,:)), ...
       'LineWidth', 4);
  legend({'Cost without renewables', 'Cost with only renewables', ...
          'Cost with 1 Battery' }, 'Location', 'NorthEast');
  savefig_(H, 'pdf_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline, Y, renewline, Y, 'LineWidth', 4);
  plot(totalcost_sort + Batt_ann_matrix, X, 'LineWidth', 4);
  legend({'Cost without renewables', 'Cost with only renewables', ...
          'Cost with 1 Battery', 'Cost with 2 Batteries', ...
          'Cost with 3 Batteries', 'Cost with 4 Batteries', ...
          'Cost with 5 Batteries'}, 'Location', 'NorthEast');
  savefig_(H, 'cdf_mc_annuity');
end


function [totalcost, excess, total_basic_cost, total_renew_cost]...
    = household(save_plots, number_batteries)
  % HOUSEHOLD  Simulate the household's energy storage situation.
  %   totalcost = household()
  %   totalcost = household(save_plots)
  %     Save files 'power.svg' and 'netdemand.svg' if save_plots is true
  %     (default: false).
  global N_hours mu_d sigma_d lambda_w k_w V_cutin V_rated V_cutout G_max;
  
  if nargin < 1
    save_plots = false;
  end
  
  hours = 1:N_hours;

  % Draw from the distributions
  D = demand(mu_d, sigma_d);
  [G, ~] = generation_ordered(lambda_w, k_w, V_cutin, V_rated, V_cutout, G_max);
  P = agg_price(price());

  chargingcap = .81;
  dischargingcap = .81;
  energycap = .81;
  % Compute net demand
  netdemand = D - G;
  overgeneration = zeros(1,length(netdemand));
  negativedemand = zeros(1, length(netdemand));
  overgenstep = overgeneration;
  % Creates an hourly matrix of when energy is available for storage.
  overgenstep(find(netdemand<0)) = netdemand(netdemand<0);
  overgenstep = abs(overgenstep);
  negativedemand(find(netdemand>0)) = netdemand(netdemand>0);
  overgeneration(find(overgenstep<chargingcap)) = overgenstep(overgenstep < ...
                                                              chargingcap);
  overgeneration(find(overgenstep>chargingcap)) = chargingcap;
  [discharged, stored] = optimized_behavior(overgeneration, P, ...
      negativedemand,  dischargingcap, number_batteries*energycap);
  % Integrate negative-demand hours -> battery storage
  excess = -sum(max(0, netdemand));
  
  % Compute electricity cost for no renewables
  basic_cost = D .* P;
  total_basic_cost = sum(basic_cost);
  %compute electricity cost with renewables non storage
  renew_cost = max(0, netdemand) .* P;
  total_renew_cost = sum(renew_cost);
 
  %compute electricity cost with storage
  cost(1:N_hours) = max(0, netdemand) .* P - discharged(1:N_hours)'.*P;
  totalcost = sum(cost);
  save('test.mat');

  if logical(save_plots)
    H = newfig();
    xlabel('Time [hour]');
    ylabel('Power [kW]');
    plot(hours(1:60), D(1:60), 'b', ...
         hours(1:60), G(1:60), 'g', ...
         hours(1:60), netdemand(1:60), 'r', ...
         hours(1:60), zeros([1 60]), 'k:', 'LineWidth', 4);
    legend('Demand', 'Generation', 'Net Demand');
    savefig_(H, 'NetDemand_lines');
    
    H = newfig();
    xlabel('Time [hour]');
    ylabel('Energy [kW·h]');
    plot(hours, stored, 'b', ...
         hours, overgeneration, 'r', ...
         hours, ones([1 N_hours]) * energycap * number_batteries, 'k:', ...
         'Linewidth', 4);
    legend('Storage', 'Over Generation', 'Energy Capacity');
    savefig_(H, 'Storage_Use_WithGen');
    
    H = newfig();
    xlabel('Time [hour]');
    ylabel('Energy [kW·h]');
    plot(hours, stored, 'b', ...
         hours, ones([1 N_hours]) * energycap * number_batteries, 'k:', ...
         'LineWidth', 4);
    legend('Storage', 'Energy Capacity');
    savefig_(H, 'Storage_Use');
    
    H = newfig();
    bin_width = 3;
    xlabel('Demand [kW]');
    histogram(D, 'BinWidth', bin_width);
    histogram(netdemand, 'BinWidth', bin_width);
    legend('Gross', 'Net');
    savefig_(H, 'NetDemand_hist');
  end
end


function [discharged, stored] = optimized_behavior(overgeneration, prices, ...
                                 negativedemand, dischargingcap, energycap)
  % OPTIMIZED_BEHAVIOUR Performs the linear optimization.
  global N_hours
  
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
  max_power(N_hours+1:2*N_hours) = overgeneration;
  options = optimset('LargeScale', 'on', 'Display', 'off', 'TolFun', 1e-6);
  discharged = linprog(f, A, b, [], [], zeros(1, 2 * N_hours), max_power, [], ...
                       options);
  stored = cumsum(discharged(1+N_hours:2*N_hours)) - ...
           cumsum(discharged(1:N_hours));
end
