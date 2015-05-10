% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>

function main(cmd)
  % MAIN Entry points for the household storage model
  %    MAIN(cmd) runs the model in the configuration given by cmd; valid values
  %    are 'mc', 'single' and 'prices'.

  globals
  switch cmd
    case 'mc'
      % Run a Monte Carlo simulation with 500 draws, and plot a histogram
      montecarlo(500)

    case 'single'
      % Run a single simulation, saving the plots
      household(true,1)

    case 'examples'
      examples()
  end
end


function globals
  % GLOBALS  Set global parameters for the household problem.

  global N_days N_hours mu_d sigma_d k_w lambda_w V_cutin V_rated V_cutout ...
    G_max Fontsize Efficiency

  % Time dimension
  N_days = 7;
  N_hours = 24 * N_days;
  % Normal distribution for the random part of demand
  mu_d = 0;
  sigma_d = 13;
  % Weibull distribution of wind speed
  k_w = 2;
  lambda_w = 8;
  % Engineering parameters for the wind turbine
  V_cutin = 3;
  V_rated = 12;
  V_cutout = 25;
  G_max = 3.8;
  % Style of plots
  Fontsize = 20;
  % Engineering parameters for storage
  Efficiency = .9;
end
