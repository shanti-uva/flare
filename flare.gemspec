$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'flare/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'flare'
  s.version     = Flare::VERSION
  s.authors     = ["Andres Montano"]
  s.email       = ["amontano@virginia.edu"]
  s.homepage    = "http://subjects.kmaps.virginia.edu"
  s.summary     = 'Engine that facilitates in a flexible manner connections to solr indices.'
  s.description = 'Engine that facilitates in a flexible manner connections to solr indices.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']
  
  s.add_dependency 'rails', '>= 4.0'
  s.add_dependency 'faraday', '~> 0.11.0'
  s.add_dependency 'rsolr', '~> 2.0.0.pre3'

  s.add_development_dependency 'sqlite3'
end
