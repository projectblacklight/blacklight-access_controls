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

#  def install_engine
#    generate 'blacklight-access_controls:install'
#  end

  def add_cancan_ability
    say_status('status', 'ADDING CANCAN ABILITY', :yellow)
    copy_file 'ability.rb', 'app/models/ability.rb'
  end

end
