version = File.read(File.expand_path("../VERSION", __FILE__)).strip

Gem::Specification.new do |gem|
  gem.name          = "blacklight-access_controls"

  gem.description   = %q{Access controls for project blacklight}
  gem.summary       = %q{Access controls for project blacklight}
  gem.homepage      = "http://http://projectblacklight.org"
  gem.email         = ["blacklight-development@googlegroups.com"]
  gem.authors       = ["Chris Beer", "Justin Coyne", "Matt Zumwalt", "Valerie Maher"]

  gem.files         = `git ls-files`.split($\)
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.version       = version
  gem.license       = "APACHE2"

  gem.required_ruby_version = '>= 1.9.3'

  gem.add_dependency 'cancancan', '~> 1.8'
  gem.add_dependency "blacklight", '~> 5.16'

  gem.add_development_dependency "rake", '~> 10.1'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency "engine_cart", "~> 0.8"
  gem.add_development_dependency "jettywrapper"
  gem.add_development_dependency "factory_girl_rails", "~> 4.0"
  gem.add_development_dependency "database_cleaner"
end
