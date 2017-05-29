$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "flynn_auto_scale/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "flynn_auto_scale"
  s.version     = FlynnAutoScale::VERSION
  s.authors     = ["Lazaro Herrera"]
  s.email       = ["lazherrera@gmail.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of FlynnAutoScale."
  s.description = "TODO: Description of FlynnAutoScale."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.0.3"

  s.add_development_dependency "sqlite3"
end
