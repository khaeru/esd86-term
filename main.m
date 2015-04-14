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
  costs = zeros([1 N]);
  excess = zeros([1 N]);
  for draw = 1:N
    costs(draw), excess(draw) = household;
  end
  
  figure;
  histogram(costs)
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
  [generation] = makegeneration(hours, genshape, genscale);
  [prices] = price(hours, pricesmeanerror, pricesstddev);

  % Compute net demand
  netdemand = demand - generation;

  % Integrate negative-demand hours -> battery storage
  excess = -sum(max(0, netdemand));
  
  % Compute electricity cost
  cost = min(0, netdemand) .* prices;
  totalcost = sum(cost);

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
  daily = daily / 12;
  base = repmat(daily, 1, days) * scale;
  demanderror = randn(size(hours)) * stddev + mean;
  demand = base + demanderror;
end


function [generation] = makegeneration(hours, shape, scale)
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
  speed = wblrnd(shape, scale, size(hours));
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
