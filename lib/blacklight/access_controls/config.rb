module Blacklight
  module AccessControls
    class Config

      def initialize
        @user_model = default_user_model
        @discover_group_field = default_discover_group_field
        @discover_user_field = default_discover_user_field
        @read_group_field = default_read_group_field
        @read_user_field = default_read_user_field
      end

      attr_accessor :user_model
      attr_accessor :discover_group_field, :discover_user_field
      attr_accessor :read_group_field, :read_user_field

      def default_user_model
        'User'
      end

      def default_discover_group_field
        "discover_access_group_ssim"
      end

      def default_discover_user_field
        "discover_access_person_ssim"
      end

      def default_read_group_field
        "read_access_group_ssim"
      end

      def default_read_user_field
        "read_access_person_ssim"
      end

    end
  end
end
