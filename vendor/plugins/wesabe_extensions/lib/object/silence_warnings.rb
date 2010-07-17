module Kernel
  # Do not print warnings for code run inside this block
  def silence_warnings
    old_verbose, $VERBOSE = $VERBOSE, nil
    yield
  ensure
    $VERBOSE = old_verbose
  end
end
