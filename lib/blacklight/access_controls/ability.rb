require 'cancan'

module Blacklight
  module AccessControls
    module Ability
      extend ActiveSupport::Concern

      included do
        include CanCan::Ability
        include Blacklight::AccessControls::PermissionsQuery

        # Once you include this module, you can add custom
        # permission methods to ability_logic, like so:
        # self.ability_logic +=[:setup_my_permissions]
        class_attribute :ability_logic
        self.ability_logic = [:discover_permissions, :read_permissions]
      end

      def initialize(user, options={})
        @current_user = user || guest_user
        @options = options
        @cache = Blacklight::AccessControls::PermissionsCache.new
        grant_permissions
      end

      attr_reader :current_user, :options, :cache

      def self.user_class
        Blacklight::AccessControls.config.user_model.constantize
      end

      # A user who isn't logged in
      def guest_user
        Blacklight::AccessControls::Ability.user_class.new
      end

      def grant_permissions
# TODO: move this debug statement to a better place?
#        Rails.logger.debug("Usergroups are " + user_groups.inspect)
        self.ability_logic.each do |method|
          send(method)
        end
      end

      def discover_permissions
# TODO:
#        # If we only have an ID instead of a SolrDocument
#        can :discover, String do |id|
#          test_discover(id)
#        end

        can :discover, SolrDocument do |obj|
          test_discover(obj.id)
        end
      end

      def read_permissions
# TODO:
        # can :read, String do |id|
        #   test_read(id)
        # end

        can :read, SolrDocument do |obj|
          test_read(obj.id)
        end
      end

      # TODO: implement this method
      def test_discover(id)
#      Rails.logger.debug("[CANCAN] Checking discover permissions for user: #{current_user.user_key} with groups: #{user_groups.inspect}")

        group_intersection = user_groups & discover_groups(id)
        !group_intersection.empty?

#        !group_intersection.empty? || discover_users(id).include?(current_user.user_key)
#        has_group_permission(id)? || has_user_permission(id)?
      end

      # TODO: implement this method
      def test_read(id)
        true
      end

      # You can override this method if you are using a different AuthZ (such as LDAP)
      def user_groups
        return @user_groups if @user_groups

        @user_groups = default_user_groups
        @user_groups |= current_user.groups if current_user.respond_to? :groups
        @user_groups |= ['registered'] unless current_user.new_record?
        @user_groups
      end

      # Everyone is automatically a member of group 'public'
      def default_user_groups
        ['public']
      end

      # read implies discover, so discover_groups is the union of read and discover groups
      def discover_groups(id)
        doc = permissions_doc(id)
        return [] if doc.nil?
        dg = read_groups(id) | (doc[self.class.discover_group_field] || [])
        Rails.logger.debug("[CANCAN] discover_groups: #{dg.inspect}")
        dg
      end

      # TODO: implement this method
      def read_groups(id)
        []
      end

      module ClassMethods
        def discover_group_field
          "discover_access_group_ssim"
          #TODO: Instead of hard-coding, get this from Config
        end
      end
    end
  end
end
