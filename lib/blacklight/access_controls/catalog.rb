# frozen_string_literal: true
# This is behavior for the catalog controller.

module Blacklight
  module AccessControls
    module Catalog
      extend ActiveSupport::Concern

      # Override blacklight to produce a search_builder that has
      # the current ability in context
      def search_builder
        super.tap { |builder| builder.current_ability = current_ability }
      end

      # Controller "before" filter for enforcing access controls
      # on show actions.
      # @param [Hash] opts (optional, not currently used)
      def enforce_show_permissions(opts={})
        permissions = current_ability.permissions_doc(params[:id])
        unless can? :read, permissions
          raise Blacklight::AccessControls::AccessDenied.new("You do not have sufficient access privileges to read this document, which has been marked private.", :read, params[:id])
        end
        permissions
      end

    end
  end
end
