# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.authors       = ['Wael M. Nasreddine']
  gem.email         = ['wael.nasreddine@gmail.com']
  gem.description   = 'Capistrano recipes for content managment'
  gem.summary       = gem.summary
  gem.homepage      = 'http://technogate.github.com/contao'
  gem.required_ruby_version = Gem::Requirement.new('>= 1.9.2')

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = 'capistrano-content'
  gem.require_paths = ['lib']
  gem.version       = '0.0.6'

  # Runtime dependencies
  gem.add_dependency 'rake'
  gem.add_dependency 'capistrano', '>= 2.12.0'
  gem.add_dependency 'capistrano-utils'
end
