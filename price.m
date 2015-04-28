function [P Pm] = price(B, S)
  % PRICE Simulate a random real-time electricity price and aggregate
  %    [P Pm] = PRICE(B, S) returns simulated real-time (1 minute resolution)
  %    electricity prices, Pm, and hourly aggregated prices P. Aggregated prices
  %    are means over B-hour intervals, with the first interval starting at the
  %    S-th hour of the day. The real-time prices are simulated from an
  %    Ornstein-Uhlenbeck process with time-dependent parameters
  global N_hours;

  % Default arguments
  if nargin < 2
    if nargin < 1
      B = 1;
    end
    S = 1;
  end

  % Check argument values
  assert(mod(24, B) == 0 && 1 <= S && S <= B);

  % Minute-by-minute prices
  dt = 1;                       % time increment = 1 minute
  time = 1:(N_hours * 60);      % time axis
  alpha = 0.05;                 % Rate of mean reversion
  epsilon = randn(size(time));  % Random increments for the O-U process
  sigma = 0.002;                % Scale factor for random increments
  k = exp(-alpha * dt);         % Pre-compute a frequently used factor
  % Mean prices
  mu = 0.02 * sin(2 * pi * time / (24 * 60) + pi) + 0.05;
  % Preallocate and set initial value
  Pm = zeros(size(time));
  Pm(1) = mu(1);
  % Simulate
  for t = 2:size(time, 2)
    Pm(t) = Pm(t-1) * k + mu(t) * (1 - k) + ...
            + sigma * sqrt((1 - k^2) / (2 * alpha)) * epsilon(t);
  end

  % Aggregate prices
  P = zeros(1, N_hours);
  % First period, possibly partial width
  P(1:S-1) = mean(Pm(1:S*60));
  % Intermediate periods
  for h = S:B:(N_hours - B)
    P(h:h+B-1) = mean(Pm(1+(h-1)*60:(h+B-1)*60));
  end
  % Last period
  P(h+B:end) = mean(Pm(1+(h+B-1)*60:end));
end
