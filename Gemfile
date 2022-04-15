source 'https://rubygems.org'

# Specify your gem's dependencies in ldp-client.gemspec
gemspec

# gem 'slop', '~> 3.6' if RUBY_PLATFORM == "java"
gem 'byebug', platforms: [:mri]
gem 'capybara_discoball', '~> 0.0.2'
gem 'derby',              git: 'https://github.com/fcrepo4-labs/derby.git'

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
end
