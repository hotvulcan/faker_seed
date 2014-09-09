$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "faker_seed/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "faker_seed"
  s.version     = FakerSeed::VERSION
  s.authors     = ["Rogério Chaves"]
  s.email       = ["rogerio@react.ag"]
  s.homepage    = "https://github.com/rogeriochaves/faker_seed"
  s.summary     = "Easily generate fake seed data to your Rails app with no configuration and a single command line"
  s.description = "It's as easy as: rails g fake posts -n 50"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 4.1.1"
  s.add_dependency "paperclip", ">= 4.1.1"
  s.add_dependency "faker", "~> 1.4.3"
  s.add_dependency "brfaker", "~> 0.1.0"

  s.add_development_dependency "sqlite3"
end
