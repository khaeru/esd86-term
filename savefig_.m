function savefig_(H, name)
  % SAVEFIG_ Save a figure to both .fig and .pdf files.
  savefig(H, name)
  print(H, '-dpdf', name)
end