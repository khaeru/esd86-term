% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>

% Household Storage Requirements


function household
% This funcion calls the functions which generate the stochastic inputs.

hours = 1:24*14;




netdemand = demand .- generation;

end


function [demand] = makedemand(hours)
% This function generates the stochastic demand profile for the household.
demand = zeros(length(hours)); %make basic demand matrix
demanderror = zeros(length(hours)); %make the error matrix that will sample from the distribution
end


function [gen] = makegeneration(hours)
%This function generates the stochastic wind generation profile. First it
%makes the stochastic wind speed then it converts the wind speed to a
%power.
speed = zeros(length(hours));

generation = speed.^3; %convert speed stochastic data to generation
end

function [prices] = inputprices(hours)
%This function generates the stochastic price data seen by the household.
prices = zeros(length(hours)); %make price matrix
priceserror = zeros(length(hours)); %make the stochastic matrix for the price data


end
=======

% minutes in a day
DAY = 60 * 24;
x = linspace(0, DAY, DAY);

% plot
plot(x, demand(x))
>>>>>>> origin/master
