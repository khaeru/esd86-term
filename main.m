% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>
%
% TODO add market-to-household price transformation rules

% Household Storage Requirements

function main(cmd)
  globals
  switch cmd
    % Run a Monte Carlo simulation with 500 draws, and plot a histogram
    case 'mc'
      montecarlo(500)
  
    % Run a single simulation, saving the plots
    case 'single'
      household(true,1)
  end
end


function globals
  % GLOBALS  Set global parameters for the household problem
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
  %Style
  Fontsize = 20;
end


function montecarlo(N)
global Fontsize
  % Monte Carlo simulation of the households
 
  number_batteries = [1 2 3 4 5];
X = 1/N:1/N:1;
  totalcost = zeros([length(number_batteries) N]);
  excess = zeros([length(number_batteries) N]);
  total_basic_cost = zeros([length(number_batteries) N]);
  total_renew_cost = zeros([length(number_batteries) N]);
    for i = 1:length(number_batteries)
  for draw = 1:N
    [totalcost(i,draw), excess(i,draw), total_basic_cost(i,draw), ...
        total_renew_cost(i,draw)] = household([],number_batteries(i));
  end
    
totalcost_sort(i,:) = sort(totalcost(i,:));
excess_sort(i,:) = sort(excess(i,:));
total_basic_cost_sort(i,:) = sort(total_basic_cost(i,:));
total_renew_cost_sort(i,:) = sort(total_renew_cost(i,:));
    

Cost_Mean(i,1) = mean(total_basic_cost(i,:));
Cost_Mean(i,2) = mean(total_renew_cost(i,:));
Cost_Mean(i,3) = mean(totalcost(i,:));
Cost_Variance(i,1) = var(total_basic_cost(i,:));
Cost_Variance(i,2) = var(total_renew_cost(i,:));
Cost_Variance(i,3) = var(totalcost(i,:));
    end
    renewline = sort(total_renew_cost(:));
    basicline = sort(total_basic_cost(:));
    Y = 1/(N*i):1/(N*i):(N*i);
  save('test.mat');

  figure('units','normalized','outerposition', [0 0 1 1]);
  histogram(totalcost)
  savefig('costs_mc');
  
  figure('units','normalized','outerposition', [0 0 1 1]);
  histogram(excess)
  savefig('excess_mc');
  
  figure('units','normalized','outerposition', [0 0 1 1]);
  plot(basicline,Y,renewline,Y,totalcost_sort,X,...
      'LineWidth', 4);
  legend({'Cost without renewables', 'Cost with only renewables' 'Cost with 1 Battery' 'Cost with 2 Battery' 'Cost with 3 Battery' 'Cost with 4 Battery' 'Cost with 5 Battery'}, 'Location', 'NorthEast', 'FontSize', Fontsize)
  xlabel('Weekly Electricity Bill ($)', 'FontSize', Fontsize);
  ylabel('Probability', 'FontSize', Fontsize);
  savefig('cdf_mc');
end


function [totalcost, excess, total_basic_cost, total_renew_cost]...
    = household(save_plots, number_batteries)
  % HOUSEHOLD  Simulate the household's energy storage situation.
  %   totalcost = household()
  %   totalcost = household(save_plots)
  %     Save files 'power.svg' and 'netdemand.svg' if save_plots is true
  %     (default: false).
  global N_hours mu_d sigma_d lambda_w k_w V_cutin V_rated V_cutout G_max ...
    Fontsize
  
  if nargin < 1
    save_plots = false;
  end
  
  hours = 1:N_hours;

  % Draw from the distributions
  D = demand(mu_d, sigma_d);
  [G, ~] = generation(lambda_w, k_w, V_cutin, V_rated, V_cutout, G_max);
  [P, ~] = price();

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
  [discharged stored] = optimized_behavior(overgeneration, P, ...
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
  save('test.mat')

  if logical(save_plots)
    figure('units','normalized','outerposition', [0 0 1 1]);
    plot(hours(1:60), D(1:60), 'b', hours(1:60), G(1:60), 'g', hours(1:60), netdemand(1:60), 'r', 'Linewidth', 4);
    hold on
    plot(hours(1:60), zeros([1 60]), 'LineWidth', 4, 'LineStyle', ':', 'Color', 'k');
    xlabel('Time (hours)', 'FontSize', Fontsize)
    ylabel('Power (kW)', 'FontSize', Fontsize)
    legend({'Demand' 'Generation' 'Net Demand'}, 'FontSize', Fontsize)
    savefig('NetDemand_lines');
    hold off
    
    figure('units','normalized','outerposition', [0 0 1 1]);
    plot(hours, stored, 'b', hours, overgeneration, 'r', 'Linewidth', 4);
    hold on
    plot(hours, ones([1 N_hours])*energycap*number_batteries, 'LineStyle', ':', 'Color', 'k', 'LineWidth', 4);
    hold off
    xlabel('Time (hours)', 'FontSize', Fontsize)
    ylabel('Energy (kWh)', 'FontSize', Fontsize)
    legend({'Storage' 'Over Generation' 'Energy Capacity'}, 'FontSize', Fontsize)
    savefig('Storage_Use_WithGen');
    
    figure('units','normalized','outerposition', [0 0 1 1]);
    plot(hours, stored, 'b',  'Linewidth', 4);
    hold on
    plot(hours, ones([1 N_hours])*energycap*number_batteries, 'LineStyle', ':', 'Color', 'k', 'LineWidth', 4);
    hold off
    xlabel('Time (hours)', 'FontSize', Fontsize)
    ylabel('Energy (kWh)', 'FontSize', Fontsize)
    legend({'Storage'  'Energy Capacity'}, 'FontSize', Fontsize)
    savefig('Storage_Use');
    
    figure('units','normalized','outerposition', [0 0 1 1]);
    bin_width = 3;
    histogram(D, 'BinWidth', bin_width)
    hold(gca, 'on');
    histogram(netdemand, 'BinWidth', bin_width)
    xlabel('Demand [kW]', 'FontSize', Fontsize)
    legend({'Gross'  'Net'}, 'FontSize', Fontsize)
    savefig('NetDemand_hist');

    save('test.mat')
  end
end


function [discharged stored] = optimized_behavior(overgeneration, prices, ...
                                 negativedemand, dischargingcap, energycap)
  % OPTIMIZED_BEHAVIOUR Performs the linear optimization.
global N_hours
  
  overgenmatrix = ones(N_hours);
  overgenmatrix(1,1:N_hours) = overgenmatrix(1,1:N_hours) .* overgeneration;
   %1st half discharge second half charge, the charging is free.
  f = zeros(2 * N_hours, 1); 
  f(1:N_hours) = -prices;  % Discharging

  A = zeros(2 * N_hours, 2 * N_hours);
  A(1:N_hours,1:N_hours) = -tril(ones(N_hours));  % Discharging cap
  A(1:N_hours,(1+N_hours):(2*N_hours)) = tril(ones(N_hours));  % Charging cap
  A((1+N_hours):(2*N_hours),1:N_hours) = tril(ones(N_hours));  % Discharging floor
  %  Charging floor
  A((1+N_hours):(2*N_hours),(1+N_hours):(2*N_hours)) = -tril(ones(N_hours)); 
  b = [energycap * ones(N_hours, 1); zeros(N_hours, 1)];
max_power = zeros([1 2*N_hours]);
  max_power(1:N_hours) = min(negativedemand(1:N_hours), dischargingcap);
  max_power(N_hours+1:2*N_hours) = overgeneration;
  options = optimset('LargeScale', 'on', 'Display', 'off', 'TolFun', 1e-6);
  discharged = linprog(f, A, b, [], [], zeros(1, 2 * N_hours), max_power, [], ...
                       options);
  stored = zeros([1 N_hours]);
  stored = cumsum(discharged(1+N_hours:2*N_hours)) - cumsum(discharged(1:N_hours));
end