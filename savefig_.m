function savefig_(H, name)
  % SAVEFIG_ Save a figure to both .fig and .pdf files.
  name = fullfile('figure', name);
  savefig(H, name);
  saveTightFigure(H, strcat(name, '.pdf'));
end