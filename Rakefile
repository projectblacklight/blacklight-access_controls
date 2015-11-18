#!/usr/bin/env rake

require 'solr_wrapper'

SOLR_OPTIONS = {
    verbose: true,
    cloud: false,
    port: '8983',
    version: '5.3.1',
    instance_dir: 'solr',
    download_dir: 'tmp'
}

SolrWrapper.default_instance_options = SOLR_OPTIONS

require 'solr_wrapper/rake_task'
require 'engine_cart/rake_task'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

task :default => 'solr:spec'

def solr_config_dir
  File.join(File.expand_path(File.dirname(__FILE__)), "solr_conf", "conf")
end

namespace :solr do

  desc 'Configure solr cores'
  task :config do
    SolrWrapper.wrap do |solr|
      core = solr.create(name: 'development', dir: solr_config_dir)
      core = solr.create(name: 'test', dir: solr_config_dir)
    end
  end

  desc "Run test suite (with solr wrapper)"
  task :spec do
    SolrWrapper.wrap do |solr|
      solr.with_collection(name:'test', dir: solr_config_dir) do |collection_name|
        Rake::Task['spec'].invoke
      end
    end
  end

end
