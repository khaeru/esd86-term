function y = demand(x)
% basic profile of daily demand
base = sin(x * 4 / max(x));

% 0-mean noise 
amplitude = 0.1;
noise = amplitude * randn(size(x));

% total demand
y = base + noise;
end
