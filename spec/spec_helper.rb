# spec_helper.rb
#
# general requirements for constraint specs

require 'puppet'
gem 'rspec', '>=2.0.0'
require 'rspec/expectations'

RSpec.configure do |config|
  config.mock_with :mocha
end
