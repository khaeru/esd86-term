% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>

% Household Storage Requirements


function household
% This funcion calls the functions which generate the stochastic inputs for
% a two week period.

hours = 1:24*14;
demandmeanerror = 0; %For adjusting the demand stochastic normal distribution
demandstddev = 1; % for adjusting the demand stochastic normal distribution
pricesmeanerror = 0;% for adjusting the prices stochastic normal distribution
pricesstddev = 1; % for adjusting the prices stochastic normal distribution
genshape = 1; %for adjusting the speed weibull distribution
genscale = 1; %for adjusting the speed weibull distribution

[demand] = makedemand(hours,demandmeanerror,demandstddev);
[generation] = makegeneration(hours,genshape,genscale);
[prices] = inputprices(hours,pricesmeanerror,pricesstddev);


netdemand = demand - generation;
save('test.mat')
end


function [demand] = makedemand(hours,mean,stddev)
% This function generates the stochastic demand profile for the household.
demand = zeros([1 length(hours)]); %make basic demand matrix
demanderror = zeros([1 length(hours)]); %make the error matrix that will sample from a standard normal distribution
daily = [3 3 3 3 3 4 5 7 7 5 5 5 4 4 5 7 8 9 8 6 6 5 4 3];
numberdays = length(hours)/24 - 1;
base = zeros([1 length(hours)]);
for i = 0:numberdays
base((i*24)+1:(i*24)+24) = daily(1:24); % repeats the base daily demand for each day
end

demanderror = randn([1 length(hours)])*stddev + mean;
demand = base + demanderror;
end


function [generation] = makegeneration(hours,shape,scale)
%This function generates the stochastic wind generation profile. First it
%makes the stochastic wind speed then it converts the wind speed to a
%power.

speed = wblrnd(shape,scale,[1 length(hours)]);

generation = speed.^3; %convert speed stochastic data to generation - not yet correct
end

function [prices] = inputprices(hours,mean,stddev)
%This function generates the stochastic price data seen by the household.
prices = zeros([1 length(hours)]); %make price matrix
priceserror = zeros([1 length(hours)]); %make the stochastic matrix for the price data
base = prices;
base = sin(pi*hours/12 + pi)+5; % makes the basic sinusoid of prices


priceserror = randn([1 length(hours)])*stddev + mean;
prices = base + priceserror;
end
%=======

% minutes in a day
%DAY = 60 * 24;
%x = linspace(0, DAY, DAY);

% plot
%plot(x, demand(x))
%>>>>>>> origin/master
