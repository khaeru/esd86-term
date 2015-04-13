function [prices] = price(hours, mean, stddev)
  % This function generates the stochastic price data seen by the household.
  % Make the stochastic matrix for the price data
  base = sin(pi * hours / 12 + pi) + 5; % makes the basic sinusoid of prices
  priceserror = randn(size(hours)) * stddev + mean;
  prices = base + priceserror;
end