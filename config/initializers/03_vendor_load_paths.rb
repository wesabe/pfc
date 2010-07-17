# Add any dirs under vendor to the library search path (exclude plugins)
vendor_dirs = Dir.glob(Rails.root.join('vendor','*')) - [Rails.root.join('vendor','plugins')]
vendor_dirs.each {|d| $: << File.expand_path(d)}