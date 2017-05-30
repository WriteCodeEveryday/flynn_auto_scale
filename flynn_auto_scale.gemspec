$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "flynn_auto_scale/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "flynn_auto_scale"
  s.version     = FlynnAutoScale::VERSION
  s.authors     = ["Lazaro Herrera"]
  s.email       = ["lazherrera@gmail.com"]
  s.homepage    = "https://github.com/WriteCodeEveryday/flynn_auto_scale"
  s.summary     = "A gem that allows your Rails apps to self-scale as they need more and more resources under Flynn. Comes with an automated mode that can be used for 'day to day' web hosting operations and a manual mode where you can control when scaling operations take place (for scripts, background jobs and anything else)"
  s.description = "A gem that allows your Rails apps to self-scale as they need more and more resources under Flynn. Comes with an automated mode that can be used for 'day to day' web hosting operations and a manual mode where you can control when scaling operations take place (for scripts, background jobs and anything else)"
  s.license     = "CC0"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails"
  s.add_dependency "os"

  s.add_development_dependency "sqlite3"
end
