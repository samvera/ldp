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

  case ENV['RAILS_VERSION']
  when /6\.[0-1]/
    gem 'activesupport'
  when /5\.[1-2]/
    gem 'activesupport'
  end
else
  gem 'rails', '~> 6.0.0'
end
