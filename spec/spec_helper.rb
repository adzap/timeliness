require 'rspec'

require 'active_support/time'
require 'timeliness'

Rspec.configure do |c|
  c.mock_with :rspec
end
