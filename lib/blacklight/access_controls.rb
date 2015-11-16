module Blacklight
  module AccessControls
    extend ActiveSupport::Autoload

    autoload :Config
    autoload :User
    autoload :PermissionsQuery
    autoload :PermissionsCache
    autoload :PermissionsSolrDocument
    autoload :Ability
    autoload :Enforcement
    autoload :SearchBuilder
  end
end
