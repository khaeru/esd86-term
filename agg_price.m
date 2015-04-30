function P = agg_price(prices, varargin)
  % AGG_PRICE Aggregate real-time electricity prices to hourly prices
  %    P = agg_price(P, B, S) returns the minute-by-minute electricty prices P,
  %    Aggregated as means over B-hour intervals, with the first interval
  %    starting at the S-th hour of the day. By default, B = S = 1.
  global N_hours;
  
  % Default arguments
  if nargin < 3
    varargin{2} = 1;
    if nargin < 2
      varargin{1} = 1;
    end
  end
  % Check argument values
  [B, S] = deal(varargin{:});
  assert(mod(24, B) == 0 && 1 <= S && S <= B);

  % Aggregate prices
  P = zeros(1, N_hours);
  % First period, possibly partial width
  P(1:S-1) = mean(prices(1:S*60));
  % Intermediate periods
  for h = S:B:(N_hours - B)
    P(h:h+B-1) = mean(prices(1+(h-1)*60:(h+B-1)*60));
  end
  % Last period
  P(h+B:end) = mean(prices(1+(h+B-1)*60:end));
end