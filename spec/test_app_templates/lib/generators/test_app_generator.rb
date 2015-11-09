require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "./spec/test_app_templates"

  # if you need to generate any additional configuration
  # into the test app, this generator will be run immediately
  # after setting up the application

  def generate_blacklight
    say_status('warning', 'GENERATING BLACKLIGHT', :yellow)
    generate "blacklight:install", "--devise"
  end

#  def install_engine
#    generate 'blacklight-access-controls:install'
#  end

end
