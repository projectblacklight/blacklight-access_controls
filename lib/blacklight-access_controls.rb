require 'rails'
require 'cancan'
require 'blacklight'
require 'blacklight/access_controls'

module Blacklight::AccessControls
  extend ActiveSupport::Autoload

  class << self
    def configure
      @config ||= Config.new
      yield @config if block_given?
      @config
    end
    alias :config :configure
  end

end
