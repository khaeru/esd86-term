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
      household(true)
  end
end


function globals
  % GLOBALS  Set global parameters for the household problem
  global N_days N_hours mu_d sigma_d k_w lambda_w V_cutin V_rated V_cutout ...
    G_max mu_p sigma_p
  % Time dimension
  N_days = 7;
  N_hours = 24 * N_days;
  % Normal distribution for the random part of demand
  mu_d = 0;
  sigma_d = 1;
  % Weibull distribution of wind speed
  k_w = 2;
  lambda_w = 8;
  % Engineering parameters for the wind turbine
  V_cutin = 3;
  V_rated = 12;
  V_cutout = 25;
  G_max = 3.8;
  % Normal distribution for the random part of prices  
  mu_p = 0;
  sigma_p = 1;
end


function montecarlo(N)
  % Monte Carlo simulation of the households
  totalcost = zeros([1 N]);
  excess = zeros([1 N]);
  total_basic_cost = zeros([1 N]);
  total_renew_cost = zeros([1 N]);
  for draw = 1:N
    [totalcost(draw), excess(draw), total_basic_cost(draw), ...
        total_renew_cost(draw)] = household();
  end
totalcost_sort = sort(totalcost);
excess_sort = sort(excess);
total_basic_cost_sort = sort(total_basic_cost);
total_renew_cost_sort = sort(total_renew_cost);
X = 1:1:N;
  save('test.mat');

  figure;
  histogram(totalcost)
  savefig('costs_mc');
  
  figure;
  histogram(excess)
  savefig('excess_mc');
  
  figure;
  plot(X,totalcost_sort,X,total_basic_cost_sort,X,total_renew_cost_sort);
  savefig('cdf_mc');
end


function [totalcost, excess, total_basic_cost, total_renew_cost]...
    = household(save_plots)
  % HOUSEHOLD  Simulate the household's energy storage situation.
  %   totalcost = household()
  %   totalcost = household(save_plots)
  %     Save files 'power.svg' and 'netdemand.svg' if save_plots is true
  %     (default: false).
  global N_hours mu_d sigma_d lambda_w k_w V_cutin V_rated V_cutout G_max ...
    mu_p sigma_p
  
  if nargin < 1
    save_plots = false;
  end
  
  hours = 1:N_hours;

  % Draw from the distributions
  D = demand(mu_d, sigma_d);
  [G, ~] = generation(lambda_w, k_w, V_cutin, V_rated, V_cutout, G_max);
  P = price(hours, mu_p, sigma_p);
number_batteries = 1;
  chargingcap = 4.4;
  dischargingcap = 4.4;
  energycap = 9.6;
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
  [discharged] = optimized_behavior(overgeneration, P, ...
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
    figure;
    plot(hours, D, 'b', hours, G, 'g', hours, netdemand, 'r');
    xlabel('Hours')
    ylabel('kW')
    legend('Demand', 'Generation', 'Net Demand')
    saveas(gcf, 'power.pdf');

    figure;
    bin_width = 3;
    histogram(D, 'BinWidth', bin_width)
    hold(gca, 'on');
    histogram(netdemand, 'BinWidth', bin_width)
    xlabel('Demand [kW]')
    legend('Gross', 'Net')
    saveas(gcf, 'netdemand.pdf');

    save('test.mat')
  end
end


function [discharged] = optimized_behavior(overgeneration, prices, ...
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
end