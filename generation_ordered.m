function [G, V] = generation_ordered(lambda, k, V_cutin, V_rated, V_cutout, G_max)
  % GENERATION Simulate a random wind generation profile.
  %    [G, V] = generation(lambda, k) returns a 1-by-N_hours matrix with a
  %    random wind generation profile and wind speeds. The wind speed is drawn
  %    from a Weibull distribution with scale lambda and shape k. The generation
  %    is calculated from the wind speed for a turbine with cut-in wind speed
  %    V_cutin, rated power at V_rated, a cut-out wind speed at V_cutout, and
  %    maximum power output G_max.
  
  % This version is now updated to 1: order the wind speeds so they' ramp
  % up and down and 2: to have two different wind peaks.
  global N_hours N_days
  V = wblrnd(lambda, k, 1, N_hours);
  X = wblrnd(3*lambda/4, k, 1, N_hours);
  for i = 0:N_days-1
      V(1+24*i:6+24*i) = sort(V(1+24*i:6+24*i));
      V(7+24*i:12+24*i) = sort(V(7+24*i:12+24*i), 'descend');
      V(13+24*i:18+24*i) = sort(X(13+24*i:18+24*i));
      V(19+24*i:24+24*i) = sort(X(19+24*i:24+24*i), 'descend');
      
  end
  
  
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