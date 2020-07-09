$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "db_manager/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "db_manager"
  s.version = DbManager::VERSION
  s.authors = ["Dave Benson"]
  s.email = ["david_a_benson@yahoo.com"]
  s.homepage = ""
  s.summary = "Rake tasks to help manage a database."
  s.description = "Rake tasks to help manage a database."
  s.license = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 6.0.0"
  s.add_dependency 'dotenv-rails'

end
