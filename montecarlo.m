function montecarlo(N)
  % MONTECARLO Monte Carlo simulation of the households.
  number_batteries = [1 0.8 2 3 4 5];

  totalcost = zeros([length(number_batteries) N]);
  excess = zeros([length(number_batteries) N]);
  total_basic_cost = zeros([length(number_batteries) N]);
  total_renew_cost = zeros([length(number_batteries) N]);
  cost_mean = zeros([N 3]);
  cost_variance = zeros([N 3]);
  for i = 1:length(number_batteries)
    for draw = 1:N
      if mod(draw, 10) == 1
        disp([i draw])
      end
      [totalcost(i,draw), excess(i,draw), total_basic_cost(i,draw), ...
        total_renew_cost(i,draw)] = household(number_batteries(i));
    end

    cost_mean(i,1) = mean(total_basic_cost(i,:));
    cost_mean(i,2) = mean(total_renew_cost(i,:));
    cost_mean(i,3) = mean(totalcost(i,:));
    cost_variance(i,1) = var(total_basic_cost(i,:));
    cost_variance(i,2) = var(total_renew_cost(i,:));
    cost_variance(i,3) = var(totalcost(i,:));
  end
    
  totalcost_sort = sort(totalcost,2);
  excess_sort = sort(excess,2);
  total_basic_cost_sort = sort(total_basic_cost,2);
  total_renew_cost_sort = sort(total_renew_cost,2);
      
  renewline = sort(total_renew_cost(:));
  renewline = renewline';
  basicline = sort(total_basic_cost(:));
  basicline = basicline';

  Battery_annuity = 3.4;
  Batt_ann_matrix = Battery_annuity * repmat(number_batteries',1,N);
  X = 1/N:1/N:1;
  X_diff = 1/(N-1):1/(N-1):1;
  Y = 1/(N*i):1/(N*i):1;
  Y_diff = 1/(N*i-1):1/(N*i-1):1;
  %save('test.mat');

%   % currently unused
%   H = newfig();
%   histogram(totalcost)
%   savefig_(H, 'costs_mc');
%
%   % currently unused
%   H = newfig();
%   histogram(excess)
%   savefig_(H, 'excess_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline, Y, renewline, Y, totalcost_sort, X, 'LineWidth', 4);
  legend({'Cost w/o renewables', 'Cost w/ wind only', ...
          'Cost w/ 1 battery', '"0.8" batteries', '2 batteries', ...
          '3 batteries', '4 batteries', '5 batteries'}, 'Location', 'Best');
  savefig_(H,'cdf_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('pdf');
  opts = {'Normalization', 'pdf', 'EdgeColor', 'none'};
  histogram(basicline, opts{:});
  histogram(renewline, opts{:});
  histogram(totalcost_sort(1,:), opts{:});
  histogram(totalcost_sort(2,:), opts{:});
  histogram(totalcost_sort(6,:), opts{:});
  legend({'Cost w/o renewables', 'Cost w/ wind only', ...
          'Cost w/ 1 battery', '"0.8" batteries', '5 batteries'}, ...
          'Location', 'Best');
  savefig_(H, 'pdf_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline, Y, renewline, Y, 'LineWidth', 4);
  plot(totalcost_sort + Batt_ann_matrix, X, 'LineWidth', 4);
  legend({'Cost w/o renewables', 'Cost w/ wind only', ...
          'Cost w/ 1 battery', '"0.8" batteries', '2 batteries', ...
          '3 batteries', '4 batteries', '5 batteries'}, 'Location', 'Best');
  savefig_(H, 'cdf_mc_annuity');
end
