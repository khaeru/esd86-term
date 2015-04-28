function P = price(hours, mean, stddev)
  % This function generates the stochastic price data seen by the household.
  % The 1/100 factor is to make the base price 5 cents per kWh. The should
  % still be adjusted... but the weekly electric bill should be about 
  % $20-40 without renewables.
  P = (sin(pi * hours / 12 + pi) + 5 + (randn(size(hours)) * stddev + mean))/100;
end