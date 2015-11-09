ENV['RAILS_ENV'] ||= 'test'

require 'engine_cart'
EngineCart.load_application!

require 'blacklight-access-controls'

RSpec.configure do |config|
  config.fixture_path = File.expand_path('../fixtures', __FILE__)
end
