# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ldp/version'

Gem::Specification.new do |spec|
  spec.name          = "ldp"
  spec.version       = Ldp::VERSION
  spec.authors       = ["Chris Beer"]
  spec.email         = ["chris@cbeer.info"]
  spec.description   = %q{Linked Data Platform client library}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/projecthydra/ldp"
  spec.license       = "APACHE2"
  spec.required_ruby_version = '~> 2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.add_dependency "faraday"
  spec.add_dependency "rdf",            ">= 1.1"
  spec.add_dependency "rdf-turtle"
  spec.add_dependency "rdf-vocab",      ">= 0.8"
  spec.add_dependency "rdf-isomorphic"
  spec.add_dependency "json-ld"
  spec.add_dependency "http_logger"
  spec.add_dependency "deprecation"
  spec.add_dependency "slop"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "simplecov"
end
