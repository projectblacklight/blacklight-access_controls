ENV['RAILS_ENV'] ||= 'test'

require 'engine_cart'
EngineCart.load_application!

require 'blacklight-access-controls'

RSpec.configure do |config|
end
