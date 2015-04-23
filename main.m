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
    G_max
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
  V_cutin = 2.7;
  V_rated = 11;
  V_cutout = 25;
  G_max = 25;
end


function montecarlo(N)
  % Monte Carlo simulation of the households
  totalcost = zeros([1 N]);
  excess = zeros([1 N]);
  for draw = 1:N
    [totalcost(draw) excess(draw)] = household();
  end
  save('test.mat');
  figure;
  histogram(totalcost)
  saveas(gcf, 'costs_mc.pdf');
  
  figure;
  histogram(excess)
  saveas(excess, 'excess_mc.pdf');
end


function [totalcost, excess] = household(save_plots)
  % HOUSEHOLD  Simulate the household's energy storage situation.
  %   totalcost = household()
  %   totalcost = household(save_plots)
  %     Save files 'power.svg' and 'netdemand.svg' if save_plots is true
  %     (default: false).
  global N_hours mu_d sigma_d lambda_w k_w V_cutin V_rated V_cutout G_max
  
  if nargin < 1
    save_plots = false;
  end
  
  hours = 1:N_hours;
  % Parameters for the normal distribution of the stochastic part of prices  
  pricesmeanerror = 0;
  pricesstddev = 1;

  % Draw from the distributions
  D = demand(mu_d, sigma_d);
  [G, ~] = generation(lambda_w, k_w, V_cutin, V_rated, V_cutout, G_max);
  [prices] = price(hours, pricesmeanerror, pricesstddev);
  chargingcap = 5;
  dischargingcap = 25;
  energycap = 25;
  % Compute net demand
  netdemand = D - G;
  overgeneration = zeros(1,length(netdemand));
  overgenstep = overgeneration;
  overgenstep(find(netdemand>0)) = netdemand(netdemand>0); % creates an hourly matrix of when energy is available for storage.
  overgeneration(find(overgenstep<chargingcap)) = overgenstep(overgenstep<chargingcap);
  overgeneration(find(overgenstep>chargingcap)) = chargingcap;
  [discharged] = optimized_behavior(overgeneration, prices, dischargingcap, energycap);
  % Integrate negative-demand hours -> battery storage
  excess = -sum(max(0, netdemand));
  
  % Compute electricity cost
  cost = min(0, netdemand) .* prices - discharged(hours+1:2*hours)'.*prices;
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


function [discharged] = optimized_behavior(overgeneration, prices, dischargingcap, energycap)
%This function performs the linear optimization.

hours = length(prices);
overgenmatrix = ones(hours);
overgenmatrix(1,1:hours) = overgenmatrix(1,1:hours) .* overgeneration;
f = zeros(2*hours,1); %1st half discharge second half charge, the charging is free.
f(1:hours) = -prices; %discharging

A = zeros(2*hours,2*hours);
A(1:hours,1:hours) = -tril(ones(hours));  %discharging cap
A(1:hours,(1+hours):(2*hours)) = tril(ones(hours));%charging cap
A((1+hours):(2*hours),1:hours) = tril(ones(hours)); %discharging floor
A((1+hours):(2*hours),(1+hours):(2*hours)) = -tril(ones(hours)); %charging floor
b = [energycap*ones(hours,1); zeros(hours,1)];

max_power(1:hours) = dischargingcap;
max_power(hours+1:2*hours) = overgeneration;
options = optimset('LargeScale','on','Display','off','TolFun',1e-6);
discharged = linprog(f,A,b,[],[],zeros(1,2*hours),max_power,[],options);
end