# :stopdoc:
# Load necessary functions.
#
module Archetype::Functions
end

%w(hash helpers styleguide_memoizer css).each do |dep|
  require "archetype/functions/#{dep}"
end
