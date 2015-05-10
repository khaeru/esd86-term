function [G] = generation(V)
  % GENERATION Calculate generation from a wind turbine.
  %    [G] = generation(V) returns a 1-by-N_hours matrix with a wind generation
  %    profile, given wind speeds V. Generation is calculated for a turbine with
  %    cut-in wind speed V_cutin (global variable), rated power at V_rated, a
  %    cut-out wind speed at V_cutout, and maximum power output G_max.
  global V_cutin V_rated V_cutout G_max
  
  % Convert speed stochastic data to generation - corrected
  G = zeros(size(V));
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