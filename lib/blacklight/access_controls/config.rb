module Blacklight
  module AccessControls
    class Config

      attr_accessor :user_model

      def initialize
        @user_model = default_user_model
      end

      def default_user_model
        'User'
      end

    end
  end
end
