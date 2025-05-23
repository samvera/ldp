source 'https://rubygems.org'

gem 'activesupport'
gem 'byebug', platforms: [:mri]

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end

# rdf-tabular has a dependency on csv but it was removed from the ruby standard library starting in 3.4
gem "csv", "~> 3.0" if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.3')

# Specify your gem's dependencies in ldp-client.gemspec
gemspec
