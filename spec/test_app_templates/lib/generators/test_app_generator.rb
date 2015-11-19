require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../spec/test_app_templates", __FILE__)

  # if you need to generate any additional configuration
  # into the test app, this generator will be run immediately
  # after setting up the application

  def generate_blacklight
    say_status('status', 'GENERATING BLACKLIGHT', :yellow)
    generate "blacklight:install", "--devise"
  end

  def configure_blacklight
    say_status('status', 'CONFIGURING BLACKLIGHT', :yellow)
    remove_file 'config/blacklight.yml'
    copy_file 'blacklight.yml', 'config/blacklight.yml'
  end

  def replace_blacklight_catalog_controller
    say_status('status', 'REPLACING BLACKLIGHT CATALOG CONTROLLER', :yellow)
    remove_file 'app/controllers/catalog_controller.rb'
    copy_file 'catalog_controller.rb', 'app/controllers/catalog_controller.rb'
  end

  def add_access_controls_to_user
    say_status('status', 'ADD ACCESS CONTROLS TO USER', :yellow)
    insert_into_file 'app/models/user.rb',
      "  include Blacklight::AccessControls::User\n",
      after: "class User < ActiveRecord::Base\n"
  end

  def add_access_controls_to_search_builder
    say_status('status', 'ADDING ACCESS CONTROLS TO SEARCH BUILDER', :yellow)
    insert_into_file 'app/models/search_builder.rb',
      "  include Blacklight::AccessControls::Enforcement\n",
      before: "end"
  end

#  def install_engine
#    generate 'blacklight-access_controls:install'
#  end

  def add_cancan_ability
    say_status('status', 'ADDING CANCAN ABILITY', :yellow)
    copy_file 'ability.rb', 'app/models/ability.rb'
  end

end
