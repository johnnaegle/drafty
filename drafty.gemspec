$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "drafty/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "drafty"
  s.version     = Drafty::VERSION
  s.authors     = ["John Naegle"]
  s.email       = ["john.naegle@gmail.com"]
  s.homepage    = "https://github.com/johnnaegle/drafty"
  s.summary     = "Keep draft changes to objects off to the side until ready to be finalized"
  s.description = "Keep draft changes to objects off to the side until ready to be finalized"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.1"

  s.add_development_dependency "sqlite3"
end
