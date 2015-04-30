function Pm = price()
  % PRICE Simulate a random real-time electricity price
  %    [P Pm] = PRICE(B, S) returns simulated real-time (1 minute resolution)
  %    electricity prices from an Ornstein-Uhlenbeck process with time-dependent
  %    parameters.
  global N_hours;

  % Minute-by-minute prices
  dt = 1;                       % time increment = 1 minute
  time = 1:(N_hours * 60);      % time axis
  alpha = 0.05;                 % Rate of mean reversion
  epsilon = randn(size(time));  % Random increments for the O-U process
  sigma = 0.002;                % Scale factor for random increments
  k = exp(-alpha * dt);         % Pre-compute a frequently used factor
  % Mean prices — center the mean at 0.205, in accordance with PG&E electricity
  % rates. Vertical scale is 0.02 because ???.
  mu = 0.02 * sin(2 * pi * time / (24 * 60) + pi) + 0.205; 
  % Preallocate and set initial value
  Pm = zeros(size(time));
  Pm(1) = mu(1);
  % Simulate
  for t = 2:size(time, 2)
    Pm(t) = Pm(t-1) * k + mu(t) * (1 - k) + ...
            + sigma * sqrt((1 - k^2) / (2 * alpha)) * epsilon(t);
  end
end
