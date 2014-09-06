require 'capybara/rspec'
require 'simplecov'

SimpleCov.start

require_relative '../app'

RubyistIpsumApp.environment = :test
Bundler.require :default, RubyistIpsumApp.environment

RSpec.configure do |config|
  config.color = true
  config.tty   = true
end

Capybara.app = RubyistIpsumApp