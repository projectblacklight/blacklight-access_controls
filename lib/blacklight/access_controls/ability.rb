require 'cancan'

module Blacklight
  module AccessControls
    module Ability
      extend ActiveSupport::Concern

      included do
        include CanCan::Ability

        # Once you include this module, you can add custom
        # permission methods to ability_logic, like so:
        # self.ability_logic +=[:setup_my_permissions]
        class_attribute :ability_logic
        self.ability_logic = [:discover_permissions, :read_permissions]
      end

      def initialize(user, options = {})
#        @current_user = user || Hydra::Ability.user_class.new # guest user (not logged in)
#        @options = options
        grant_default_permissions
      end

      def grant_default_permissions
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
        true
      end

      # TODO: implement this method
      def test_read(id)
        true
      end

    end
  end
end
