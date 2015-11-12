#!/usr/bin/env rake

require 'engine_cart/rake_task'

ZIP_URL = "https://github.com/projectblacklight/blacklight-jetty/archive/v4.10.4.zip"
require 'jettywrapper'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

namespace :jetty do

  desc "Copies the contents of solr_conf into the Solr blacklight-core and test-core"
  task :config_solr do
    FileUtils.cp_r 'jetty/solr/blacklight-core', 'jetty/solr/test-core'

    FileUtils.cp 'solr_conf/solr.xml', 'jetty/solr/blacklight-core'
    FileUtils.cp 'solr_conf/solr.xml', 'jetty/solr/test-core'

    FileList['solr_conf/conf/*'].each do |f|
      cp("#{f}", 'jetty/solr/blacklight-core/conf/', verbose: true)
      cp("#{f}", 'jetty/solr/test-core/conf/', verbose: true)
    end
  end
end
