$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'flare/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'flare'
  s.version     = Flare::VERSION
  s.authors     = ['TODO: Your name']
  s.email       = ['TODO: Your email']
  s.homepage    = 'TODO'
  s.summary     = 'TODO: Summary of Flare.'
  s.description = 'TODO: Description of Flare.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.1.5'
  s.add_dependency 'faraday', '~> 0.11.0'
  s.add_dependency 'rsolr', '~> 2.0.0.pre3'

  s.add_development_dependency 'sqlite3'
end
