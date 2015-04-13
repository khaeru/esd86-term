% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>

% Household Storage Requirements

function main(cmd)
  switch cmd
    case 'mc'
      montecarlo(500)
  
    case 'single'
      household(true)
  end
end


function montecarlo(N)
  costs = zeros([1 N]);
  for draw = 1:N
    costs(draw) = household;
  end
  
  histogram(costs)
  saveas(gcf, 'costs_mc.svg');
end


function [totalcost] = household(save_plots)
  % This funcion calls the functions which generate the stochastic inputs for
  % a two week period.

  if nargin < 1
    save_plots = false;
  end
  
  days = 7;
  hours = 1:(24 * days);
  demandmeanerror = 0; %For adjusting the demand stochastic normal distribution
  demandstddev = 1; % for adjusting the demand stochastic normal distribution
  pricesmeanerror = 0;% for adjusting the prices stochastic normal distribution
  pricesstddev = 1; % for adjusting the prices stochastic normal distribution
  genshape = 1; %for adjusting the speed weibull distribution
  genscale = 0.5; %for adjusting the speed weibull distribution

  [demand] = makedemand(hours, demandmeanerror, demandstddev);
  [generation] = makegeneration(hours, genshape, genscale);
  [prices] = inputprices(hours, pricesmeanerror, pricesstddev);

  % Compute net demand
  netdemand = demand - generation;

  % TODO identify & integrate negative-demand hours -> battery storage
  
  % Compute electricity cost
  cost = min(zeros(size(hours)), netdemand) .* prices;
  totalcost = sum(cost);

  if logical(save_plots)
    figure;
    plot(hours, demand, 'b', hours, generation, 'g', hours, netdemand, 'r');
    xlabel('Hours')
    ylabel('kW')
    legend('Demand', 'Generation', 'Net Demand')
    saveas(gcf, 'power.svg');

    figure;
    histogram(demand, 'BinWidth', 10)
    hold(gca, 'on');
    histogram(netdemand, 'BinWidth', 10)
    saveas(gcf, 'netdemand.svg');

    save('test.mat')
  end
end


function [demand] = makedemand(hours, mean, stddev)
  % This function generates the stochastic demand profile for the household.
  scale = 10;
  % Make the error matrix that will sample from a standard normal distribution
  daily = [3 3 3 3 3 4 5 7 7 5 5 5 4 4 5 7 8 9 8 6 6 5 4 3];
  base = repmat(daily, 1, length(hours) / 24) * scale;
  demanderror = randn([1 length(hours)]) * stddev + mean;
  demand = base + demanderror;
end


function [generation] = makegeneration(hours, shape, scale)
  % This function generates the stochastic wind generation profile. First it
  % makes the stochastic wind speed then it converts the wind speed to a
  % power.
  scale2 = 10;
  maxgen = 50 * ones(size(hours));
  % Conditional distribution: low, medium or high wind days
  %wind = ceil(rand * 3);
  wind = rand * 3;
  speed = wblrnd(shape, scale , [1 length(hours)]);
  % Convert speed stochastic data to generation - not yet correct
  generation = min(maxgen, wind .* scale2 .* (speed .^ 3));
end


function [prices] = inputprices(hours, mean, stddev)
  % This function generates the stochastic price data seen by the household.
  % Make the stochastic matrix for the price data
  base = sin(pi * hours / 12 + pi) + 5; % makes the basic sinusoid of prices
  priceserror = randn([1 length(hours)]) * stddev + mean;
  prices = base + priceserror;
end
