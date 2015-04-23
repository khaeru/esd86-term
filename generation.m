function [G, V] = generation(lambda, k, V_cutin, V_rated, V_cutout, G_max)
  % GENERATION Simulate a random wind generation profile.
  %    [G, V] = generation(lambda, k) returns a 1-by-N_hours matrix with a
  %    random wind generation profile and wind speeds. The wind speed is drawn
  %    from a Weibull distribution with scale lambda and shape k. The generation
  %    is calculated from the wind speed for a turbine with cut-in wind speed
  %    V_cutin, rated power at V_rated, a cut-out wind speed at V_cutout, and
  %    maximum power output G_max.
  global N_hours
  V = wblrnd(lambda, k, 1, N_hours);
  G = zeros(size(V));
  % Convert speed stochastic data to generation - corrected
  for index = 1:length(V)
    if V(index) < V_cutin || V(index) > V_cutout
      G(index) = 0;  % Wind is too weak or strong to generate
    elseif V(index) > V_rated
      G(index) = G_max;  % Above rated wind speed, full power output
    else
      % Below rated wind speed, power output is a cubic function of speed
      G(index) = G_max * ((V(index) - V_cutin) / (V_rated - V_cutin)) ^ 3;
    end
  end
end