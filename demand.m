function D = demand(mean, stddev)
  % DEMAND Simulate a random demand profile for the household.
  %     D = demand(hours, mean, stddev) returns a 1-by-N_hours matrix containing
  %     a base demand with added, uncorrelated, random noise distributed
  %     Normal(mean, stddev²)..
  global N_days N_hours
  % Basic hourly data from Paatero & Lund (2006), Figure 4, p.283
  daily = [125 110 105 107 115 140 170 185 190 191 192 194 200 210 225 260 ...
           290 305 315 325 315 275 220 160];
  % TODO this is arbitrary: find a good value, make a global parameter
  scale = 1 / 500;
  % Repeat the basic daily profile and add normal noise
  D = repmat(daily, 1, N_days) * scale + randn(1, N_hours) * stddev *scale + mean*scale;
end