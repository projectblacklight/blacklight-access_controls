module Blacklight
  module AccessControls
    module Enforcement
      extend ActiveSupport::Concern

      included do
        attr_writer :current_ability
        class_attribute :solr_access_filters_logic

        # Set defaults. Each symbol identifies a _method_ that must be in
        # this class, taking one parameter (permission_types)
        # Can be changed in local apps or by plugins, eg:
        # CatalogController.include ModuleDefiningNewMethod
        # CatalogController.solr_access_filters_logic += [:new_method]
        # CatalogController.solr_access_filters_logic.delete(:we_dont_want)
        self.solr_access_filters_logic = [:apply_group_permissions, :apply_user_permissions]

        # Apply appropriate access controls to all solr queries
        self.default_processor_chain += [:add_access_controls_to_solr_params]
      end

      def current_ability
        @current_ability || raise("current_ability has not been set on #{self}")
      end

      protected

      def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
        user_access_filters = []

        # Grant access based on user id & group
        solr_access_filters_logic.each do |method_name|
          user_access_filters += send(method_name, permission_types, ability)
        end
        user_access_filters
      end

      #
      # Solr query modifications
      #

      # Set solr_parameters to enforce appropriate permissions
      # * Applies a lucene query to the solr :q parameter for gated discovery
      # * Uses public_qt search handler if user does not have "read" permissions
      # @param solr_parameters the current solr parameters
      def add_access_controls_to_solr_params(solr_parameters)
        apply_gated_discovery(solr_parameters)
      end

      # Which permission levels (logical OR) will grant you the ability to discover documents in a search.
      # Override this method if you want it to be something other than the default
      def discovery_permissions
        @discovery_permissions ||= ["discover","read"]
      end
      def discovery_permissions= (permissions)
        @discovery_permissions = permissions
      end

      # Controller before filter that sets up access-controlled lucene query in order to provide gated discovery behavior
      # @param solr_parameters the current solr parameters
      def apply_gated_discovery(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << gated_discovery_filters.join(" OR ")
        Rails.logger.debug("Solr parameters: #{ solr_parameters.inspect }")
      end

      def apply_group_permissions(permission_types, ability = current_ability)
        # for groups
        user_access_filters = []
        ability.user_groups.each_with_index do |group, i|
          permission_types.each do |type|
            user_access_filters << escape_filter(solr_field_for(type, 'group'), group)
          end
        end
        user_access_filters
      end

      def apply_user_permissions(permission_types, ability = current_ability)
        # for individual user access
        user_access_filters = []
        user = ability.current_user
        if user && user.user_key.present?
          permission_types.each do |type|
            user_access_filters << escape_filter(solr_field_for(type, 'user'), user.user_key)
          end
        end
        user_access_filters
      end

      # Find the name of the solr field for this type of permission.
      # e.g. "read_access_group_ssim" or "discover_access_person_ssim".
      def solr_field_for(permission_type, permission_category)
        method_name = "#{permission_type}_#{permission_category}_field".to_sym
        Blacklight::AccessControls.config.send(method_name)
      end

      def escape_filter(key, value)
        [key, value.gsub(/[ :\/]/, ' ' => '\ ', '/' => '\/', ':' => '\:')].join(':')
      end

    end
  end
end
