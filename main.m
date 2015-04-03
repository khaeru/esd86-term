% ESD.86 Spring 2015 -- Term Project
% Authors: Paul Natsuo Kishimoto <pnk@MIT.EDU>
%          Joshua Michael Mueller <jmmuell@MIT.EDU>

% minutes in a day
DAY = 60 * 24;
x = linspace(0, DAY, DAY);

% plot
plot(x, demand(x))