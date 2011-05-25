# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "timeliness/version"

Gem::Specification.new do |s|
  s.name        = "timeliness"
  s.version     = Timeliness::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Adam Meehan"]
  s.email       = %q{adam.meehan@gmail.com}
  s.homepage    = %q{http://github.com/adzap/timeliness}
  s.summary     = %q{Date/time parsing for the control freak.}
  s.description = %q{Fast date/time parser with customisable formats, timezone and I18n support.}

  s.rubyforge_project = %q{timeliness}

  s.files            = `git ls-files`.split("\n")
  s.files            = `git ls-files`.split("\n") - %w{ .gitignore .rspec Gemfile Gemfile.lock }
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG.rdoc"]
  s.require_paths    = ["lib"]
end
