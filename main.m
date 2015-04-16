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
  global days N_hours maxgen
  days = 7;
  N_hours = 24 * days;
  maxgen = 20;
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
  global days
  
  if nargin < 1
    save_plots = false;
  end
  
  hours = 1:(24 * days);
  % Parameters for the normal distribution of the stochastic part of demand
  demandmeanerror = 0;
  demandstddev = 1;
  % Parameters for the normal distribution of the stochastic part of prices  
  pricesmeanerror = 0;
  pricesstddev = 1;
  % Parameters for the Weibull distribution of wind speed
  genshape = 2;
  genscale = 8;

  % Draw from the distributions
  [demand] = makedemand(hours, demandmeanerror, demandstddev);
  [generation speed] = makegeneration(hours, genshape, genscale);
  [prices] = price(hours, pricesmeanerror, pricesstddev);
chargingcap = 5;
dischargingcap = 25;
energycap = 25;
  % Compute net demand
  netdemand = demand - generation;
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
    plot(hours, demand, 'b', hours, generation, 'g', hours, netdemand, 'r');
    xlabel('Hours')
    ylabel('kW')
    legend('Demand', 'Generation', 'Net Demand')
    saveas(gcf, 'power.pdf');

    figure;
    bin_width = 3;
    histogram(demand, 'BinWidth', bin_width)
    hold(gca, 'on');
    histogram(netdemand, 'BinWidth', bin_width)
    xlabel('Demand [kW]')
    legend('Gross', 'Net')
    saveas(gcf, 'netdemand.pdf');

    save('test.mat')
  end
end


function [demand] = makedemand(hours, mean, stddev)
  % Generates the stochastic demand profile for the household
  global days
  scale = 3;
  % Make the error matrix that will sample from a standard normal distribution
  daily = [125 110 105 107 115 140 170 185 190 191 192 194 200 210 225 260 290 305 315 325 315 275 220 160];
  daily = daily / 50;
  base = repmat(daily, 1, days) * scale;
  demanderror = randn(size(hours)) * stddev + mean;
  demand = base + demanderror;
end


function [generation speed] = makegeneration(hours, shape, scale)
  % This function generates the stochastic wind generation profile. First it
  % makes the stochastic wind speed then it converts the wind speed to a
  % power.
  global maxgen
  scale2 = 5;
  % Conditional distribution: low, medium or high wind days
  %wind = ceil(rand * 3);
  wind = rand * 3;
  cutin = 2.7;
  rated = 11;
  cutout = 25;
  maxpower = 25;
  speed = wblrnd(scale, shape, size(hours));
  generation = speed;
  % Convert speed stochastic data to generation - corrected
  for index = 1:length(speed)
      if speed(index) < cutin || speed(index) > cutout
          generation(index) = 0;
      else if speed(index) > rated
              generation(index) = maxpower;
          else
              generation(index) = maxpower*((speed(index) - cutin)/(rated - cutin))^3;
          end
      end
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