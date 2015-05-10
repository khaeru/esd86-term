function [V] = wind(lambda, k, method)
  % GENERATION Simulate a random wind speed profile.
  %    [V] = wind(lambda, k, method) returns a 1-by-N_hours matrix with a
  %    random wind speed profile. 'method' determines how the speeds are
  %    generated:
  %    'simple' - the wind speed is drawn from a Weibull distribution with scale
  %               lambda and shape k.

  global N_days N_hours

  switch method
    case 'simple'
      V = wblrnd(lambda, k, 1, N_hours);

    case 'ordered'
      % This version is now updated to 1: order the wind speeds so they' ramp
      % up and down and 2: to have two different wind peaks.
      scale = 0.75;
      V = wblrnd(lambda, k, 1, N_hours);
      X = wblrnd(scale * lambda, k, 1, N_hours);
      for i = 0:N_days-1
        V(1+24*i:6+24*i) = sort(V(1+24*i:6+24*i));
        V(7+24*i:12+24*i) = sort(V(7+24*i:12+24*i), 'descend');
        V(13+24*i:18+24*i) = sort(X(13+24*i:18+24*i));
        V(19+24*i:24+24*i) = sort(X(19+24*i:24+24*i), 'descend'); 
      end

    case 'peaky'
      % Draw from a different Weibull distribution for every hour
      lambda_ = sin(2 * pi * (1:N_hours) / 24 + pi) + lambda;
      V = zeros([1 N_hours]);
      for i = 1:N_hours
        V(i) = wblrnd(lambda_(i), k);
      end
    
    otherwise
      assert(false)
  end
end