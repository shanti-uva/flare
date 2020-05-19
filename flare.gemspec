$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'flare/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'flare'
  spec.version     = Flare::VERSION
  spec.authors     = ["Andres Montano"]
  spec.email       = ["amontano@virginia.edu"]
  spec.homepage    = "http://subjects.kmaps.virginia.edu"
  spec.summary     = 'Engine that facilitates in a flexible manner connections to solr indices.'
  spec.description = 'Engine that facilitates in a flexible manner connections to solr indices.'
  spec.license     = 'MIT'
  
  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  
  spec.add_dependency "rails", "~> 5.2.4", ">= 5.2.4.2"
  spec.add_dependency "activeresource"
  spec.add_dependency 'faraday', '~> 0.11.0'
  spec.add_dependency 'rsolr', '~> 2.0.0.pre3'
  spec.add_dependency 'delayed_job_active_record'
  spec.add_dependency 'daemons'
  spec.add_dependency 'pg'
  
  #Testing dependencies
  spec.add_development_dependency 'rspec-rails'
  spec.test_files = Dir["spec/**/*"]
end
