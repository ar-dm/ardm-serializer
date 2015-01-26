# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dm-serializer/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name             = "ardm-serializer"
  gem.version          = DataMapper::Serializer::VERSION

  gem.authors          = [ 'Martin Emde', 'Guy van den Berg', 'Dan Kubb' ]
  gem.email            = [ 'me@martinemde.com', "dan.kubb@gmail.com" ]
  gem.summary          = 'Ardm fork of dm-serializer'
  gem.description      = "DataMapper plugin for serializing Resources and Collections"
  gem.homepage         = "https://github.com/ar-dm/ardm-serializer"
  gem.license          = 'MIT'

  gem.files            = `git ls-files`.split("\n")
  gem.test_files       = `git ls-files -- {spec}/*`.split("\n")
  gem.extra_rdoc_files = %w[LICENSE README.rdoc]
  gem.require_paths    = [ "lib" ]

  gem.add_runtime_dependency 'ardm-core',  '~> 1.2'
  gem.add_runtime_dependency 'fastercsv',  '~> 1.5'
  gem.add_runtime_dependency 'multi_json', '~> 1.0'
  gem.add_runtime_dependency 'json',       '~> 1.6'
  gem.add_runtime_dependency 'json_pure',  '~> 1.6'

  gem.add_development_dependency 'rake',  '~> 0.9'
  gem.add_development_dependency 'rspec', '~> 1.3'
end
