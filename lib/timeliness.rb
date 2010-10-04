require 'date'
require 'active_support/core_ext/module'
require 'active_support/core_ext/hash'

require 'timeliness/helpers'
require 'timeliness/parser'

module Timeliness
  mattr_accessor :default_timezone
  self.default_timezone = :utc

  mattr_accessor :dummy_date_for_time_type
  self.dummy_date_for_time_type = [ 2000, 1, 1 ]

  # Set the threshold value for a two digit year to be considered last century
  #
  # Default: 30
  #
  #   Example:
  #     year = '29' is considered 2029
  #     year = '30' is considered 1930
  #
  mattr_accessor :ambiguous_year_threshold
  self.ambiguous_year_threshold = 30

  delegate :parse, :add_formats, :remove_formats, :remove_us_formats, :to => Parser
end
