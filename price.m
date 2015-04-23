function P = price(hours, mean, stddev)
  % This function generates the stochastic price data seen by the household.
  P = sin(pi * hours / 12 + pi) + 5 + (randn(size(hours)) * stddev + mean);
end