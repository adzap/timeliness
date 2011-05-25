require 'rspec'

require 'active_support/time'
require 'timecop'
require 'timeliness'
require 'timeliness/core_ext'

module TimelinessHelpers
  def parser
    Timeliness::Parser
  end

  def definitions
    Timeliness::Definitions
  end

  def parse(*args)
    Timeliness::Parser.parse(*args)
  end

  def current_date(options={})
    Timeliness::Parser.send(:current_date, options)
  end

  def should_parse(*args)
    Timeliness::Parser.parse(*args).should_not be_nil
  end

  def should_not_parse(*args)
    Timeliness::Parser.parse(*args).should be_nil
  end
end

RSpec.configure do |c|
  c.mock_with :rspec
  c.include TimelinessHelpers
end
