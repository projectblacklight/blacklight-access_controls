# frozen_string_literal: true
require 'deprecation'

module Blacklight
  module AccessControls
    # Attributes and methods used to restrict access via Solr.
    #
    # Note: solr_access_filters_logic is an Array of Symbols.
    # It sets defaults. Each symbol identifies a _method_ that must be in
    # this class, taking two parameters (permission_types, ability).
    # Can be changed in local apps or by plugins, e.g.:
    #   CatalogController.include ModuleDefiningNewMethod
    #   CatalogController.solr_access_filters_logic += [:new_method]
    #   CatalogController.solr_access_filters_logic.delete(:we_dont_want)
    module Enforcement
      extend ActiveSupport::Concern

      included do
        extend ::Deprecation
        attr_writer :current_ability, :discovery_permissions
        deprecation_deprecate :current_ability=

        ::Deprecation.warn(self, 'Blacklight::AccessControls::Enforcement is deprecated and will be removed in 1.0')
        class_attribute :solr_access_filters_logic
        alias_method :add_access_controls_to_solr_params, :apply_gated_discovery

        self.solr_access_filters_logic = %i[apply_group_permissions apply_user_permissions]

        # Apply appropriate access controls to all solr queries
        self.default_processor_chain += [:add_access_controls_to_solr_params] if respond_to?(:default_processor_chain)
      end

      delegate :current_ability, to: :scope

      # Which permission levels (logical OR) will grant you the ability to discover documents in a search.
      # Override this method if you want it to be something other than the default, or hit the setter
      def discovery_permissions
        @discovery_permissions ||= %w[discover read]
      end

      protected

      # Grant access based on user id & group
      # @return [Array{Array{String}}]
      def gated_discovery_filters(permission_types = discovery_permissions, ability = current_ability)
        solr_access_filters_logic.map { |method| send(method, permission_types, ability).reject(&:blank?) }.reject(&:empty?)
      end

      ### Solr query modifications

      # Controller before_filter that sets up access-controlled lucene query to provide gated discovery behavior.
      # Set solr_parameters to enforce appropriate permissions.
      # @param [Hash{Object}] solr_parameters the current solr parameters, to be modified herein!
      # @note Applies a lucene filter query to the solr :fq parameter for gated discovery.
      def apply_gated_discovery(solr_parameters)
        solr_parameters[:fq] ||= []
        solr_parameters[:fq] << gated_discovery_filters.reject(&:blank?).join(' OR ')
        Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
      end

      # For groups
      # @return [Array{String}] values are lucence syntax term queries suitable for :fq
      # @example
      #   [ "({!terms f=discover_access_group_ssim}public,faculty,africana-faculty,registered)",
      #     "({!terms f=read_access_group_ssim}public,faculty,africana-faculty,registered)" ]
      def apply_group_permissions(permission_types, ability = current_ability)
        groups = ability.user_groups
        return [] if groups.empty?
        permission_types.map do |type|
          field = solr_field_for(type, 'group')
          "({!terms f=#{field}}#{groups.join(',')})" # parens required to properly OR the clauses together.
        end
      end

      # For individual user access
      # @return [Array{String}] values are lucence syntax term queries suitable for :fq
      # @example ['discover_access_person_ssim:user_1@abc.com', 'read_access_person_ssim:user_1@abc.com']
      def apply_user_permissions(permission_types, ability = current_ability)
        user = ability.current_user
        return [] unless user && user.user_key.present?
        permission_types.map do |type|
          escape_filter(solr_field_for(type, 'user'), user.user_key)
        end
      end

      # @param [#to_s] permission_type a single value, e.g. "read" or "discover"
      # @param [#to_s] permission_category a single value, e.g. "group" or "person"
      # @return [String] name of the solr field for this type of permission
      # @example return values: "read_access_group_ssim" or "discover_access_person_ssim"
      def solr_field_for(permission_type, permission_category)
        method_name = "#{permission_type}_#{permission_category}_field".to_sym
        Blacklight::AccessControls.config.send(method_name)
      end

      def escape_filter(key, value)
        [key, escape_value(value)].join(':')
      end

      def escape_value(value)
        RSolr.solr_escape(value).gsub(/ /, '\ ')
      end
    end
  end
end
