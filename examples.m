function examples()
  % EXAMPLES Generate plots for a variety of example draws from the
  % distributions
  global N_hours mu_d sigma_d lambda_w k_w V_cutin V_rated V_cutout G_max;

  hours = 1:N_hours;

  % GENERATION:
  V1 = wind(lambda_w, k_w, 'simple');
  V2 = wind(lambda_w, k_w, 'ordered');
  V3 = wind(lambda_w, k_w, 'peaky');
  G1 = generation(V1);
  G2 = generation(V2);

  H = newfig();
  xlabel('Time (hour)');
  ylabel('Wind speed (m/s) or gen (kW)');
  plot(hours, V1, hours, G1, hours, V2, hours, G2, hours, V3);
  legend('Weibull speed', 'Weibull gen', 'Ordered speed', 'Ordered gen', ...
         'Peaky speed');
  xlim([0 48]);
  plot([0 N_hours], V_cutin * [1 1], 'r', ...
       [0 N_hours], V_rated * [1 1], 'g', ...
       [0 N_hours], V_cutout * [1 1], 'b', 'LineWidth', 3);
  savefig_(H, 'windgen');

  H = newfig();
  ylabel('Count');
  xlabel('Wind speed (m/s)');
  [NV, ~] = histcounts(V1, 'BinWidth', 1);
  histogram(V1, 'BinWidth', 1);
  histogram(V2, 'BinWidth', 1);
  histogram(V3, 'BinWidth', 1);
  legend('Weibull', 'Ordered', 'Peaky');
  plot(V_cutin * [1 1], [0 max(NV)], 'r', ...
       V_rated * [1 1], [0 max(NV)], 'g', ...
       V_cutout * [1 1], [0 max(NV)], 'b', 'LineWidth', 3);
  savefig_(H, 'wind_hist1');

%   H = newfig();
%   ylabel('Count');
%   xlabel('Wind generation (kW)');
%   [NG, ~] = histcounts(G1,  -0.1:0.2:G_max+0.1);
%   histogram(G1, -0.1:0.2:G_max+0.1);
%   histogram(G2, -0.1:0.2:G_max+0.1);
%   legend('Weibull', 'Ordered');
%   plot(G_max * [1 1], [0 max(NG)], 'g', 'Linewidth', 3);
%   savefig_(H, 'wind_hist2');
%  
%   % PRICES: a plot contrasting different price aggregation levels
%   P = price();
%   P1 = agg_price(P, 1, 1);
%   P2 = agg_price(P, 4, 1);
%   P3 = agg_price(P, 6, 4);
%   P4 = agg_price(P, 24, 1);
% 
%   x = 1:size(P, 2);
%   [x1, y1] = stairs((hours' - 1) * 60, P1);
%   [x2, y2] = stairs((hours' - 1) * 60, P2);
%   [x3, y3] = stairs((hours' - 1) * 60, P3);
%   [x4, y4] = stairs((hours' - 1) * 60, P4);
% 
%   H = newfig();
%   xlabel('Time (hour)');
%   ylabel('Price ($/kW·h)');
% 
%   x1 = x1 ./ 60;
%   plot(x ./ 60, P)
%   savefig_(H, 'price_example1');
%   plot(x1, y1, x1, y2, x1, y3, x1, y4, 'LineWidth', 3);
%   legend({'Spot', '1 h mean', '4 h mean', '4 h mean, 3 h offset', ...
%           '24 h mean'})
%   savefig_(H, 'price_example2');

end