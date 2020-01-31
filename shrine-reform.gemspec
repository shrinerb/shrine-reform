Gem::Specification.new do |gem|
  gem.name          = "shrine-reform"
  gem.version       = "0.1.5"

  gem.required_ruby_version = ">= 2.1"

  gem.summary      = "Provides Reform integration for Shrine."
  gem.homepage     = "https://github.com/shrinerb/shrine-reform"
  gem.authors      = ["Janko Marohnić"]
  gem.email        = ["janko.marohnic@gmail.com"]
  gem.license      = "MIT"

  gem.files        = Dir["README.md", "LICENSE.txt", "lib/**/*.rb", "*.gemspec"]
  gem.require_path = "lib"

  gem.add_dependency "shrine", "~> 3.0"
  gem.add_dependency "reform"

  gem.add_development_dependency "activerecord", "~> 5.0"
  gem.add_development_dependency "sqlite3"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "minitest"
end
