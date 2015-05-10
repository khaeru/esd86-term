function montecarlo(N)
  % MONTECARLO Monte Carlo simulation of the households.
  number_batteries = [1 2 3 4 5];

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

  H = newfig();
  histogram(totalcost)
  savefig_(H, 'costs_mc');
  
  H = newfig();
  histogram(excess)
  savefig_(H, 'excess_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline, Y, renewline, Y, totalcost_sort, X, 'LineWidth', 4);
  legend({'Cost without renewables', 'Cost with only renewables', ...
         'Cost with 1 Battery', 'Cost with 2 Batteries', ...
         'Cost with 3 Batteries', 'Cost with 4 Batteries', ...
         'Cost with 5 Batteries'}, 'Location', 'NorthEast');
  savefig_(H,'cdf_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  opts = {'Normalization', 'pdf', 'DisplayStyle', 'stairs'};
  histogram(basicline, opts{:});
  histogram(renewline, opts{:});
  histogram(totalcost_sort, opts{:});
  legend({'Cost without renewables', 'Cost with only renewables', ...
          'Cost with 1 Battery' }, 'Location', 'NorthEast');
  savefig_(H, 'pdf_mc');
  
  H = newfig();
  xlabel('Weekly Electricity Bill [$]');
  ylabel('Probability');
  plot(basicline, Y, renewline, Y, 'LineWidth', 4);
  plot(totalcost_sort + Batt_ann_matrix, X, 'LineWidth', 4);
  legend({'Cost without renewables', 'Cost with only renewables', ...
          'Cost with 1 Battery', 'Cost with 2 Batteries', ...
          'Cost with 3 Batteries', 'Cost with 4 Batteries', ...
          'Cost with 5 Batteries'}, 'Location', 'NorthEast');
  savefig_(H, 'cdf_mc_annuity');
end