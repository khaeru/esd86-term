function H = newfig()
  % NEWFIG Create a new figure with certain common properties.
  global Fontsize;
  
  H = figure('Units', 'normalized', 'OuterPosition', [0 0 1 1]);
  ax = axes();
  set(ax, 'Fontsize', Fontsize);
  hold(ax, 'on');
end