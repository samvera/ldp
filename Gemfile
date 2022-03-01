source 'https://rubygems.org'

# Specify your gem's dependencies in ldp-client.gemspec
gemspec

gem 'byebug', platforms: [:mri]
gem 'capybara_discoball', '~> 0.0.2'

if ENV['RAILS_VERSION']
  if ENV['RAILS_VERSION'] == 'edge'
    gem 'rails', github: 'rails/rails'
  else
    gem 'rails', ENV['RAILS_VERSION']
  end
else
  gem 'rails', '~> 6.0'
end
