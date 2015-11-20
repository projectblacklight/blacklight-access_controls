module Blacklight
  class AccessControlsGenerator < Rails::Generators::Base

    desc "This generator makes the following changes to your application:

1. Includes Blacklight::AccessControls::User in the User class.
2. Includes Blacklight::AccessControls::Enforcement in the SearchBuilder class.
3. Adds access controls to CatalogController.
4. Adds Ability class."


    source_root File.expand_path("..", __FILE__)

    def add_access_controls_to_user
      say_status('status', 'ADD ACCESS CONTROLS TO USER', :yellow)
      insert_into_file 'app/models/user.rb',
        "  include Blacklight::AccessControls::User\n\n",
        after: "include Blacklight::User\n"
    end

    def add_access_controls_to_search_builder
      say_status('status', 'ADDING ACCESS CONTROLS TO SEARCH BUILDER', :yellow)
      insert_into_file 'app/models/search_builder.rb',
        "  include Blacklight::AccessControls::Enforcement\n",
        before: "end"
    end

    def add_access_controls_to_catalog_controller
      say_status('status', 'ADDING ACCESS CONTROLS TO CATALOG CONTROLLER', :yellow)

      string_to_insert = <<-EOS
  include Blacklight::AccessControls::Catalog

  # Apply the blacklight-access_controls
  before_filter :enforce_show_permissions, only: :show

      EOS

      insert_into_file 'app/controllers/catalog_controller.rb',
        string_to_insert, after: "include Blacklight::Catalog\n"
    end

    def add_cancan_ability
      say_status('status', 'ADDING CANCAN ABILITY', :yellow)
      copy_file 'ability.rb', 'app/models/ability.rb'
    end

  end
end
