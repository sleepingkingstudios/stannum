# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

group :development, :test do
  gem 'bigdecimal', '~> 3.1'
  gem 'byebug', '~> 11.0'

  gem 'rspec', '~> 3.13'
  gem 'rspec-sleeping_king_studios',
    '>= 2.8.0.alpha',
    git:    'https://github.com/sleepingkingstudios/rspec-sleeping_king_studios.git',
    branch: 'main'
  gem 'rubocop', '~> 1.70'
  gem 'rubocop-rspec', '~> 3.3'
  gem 'simplecov', '~> 0.22'
end

gem 'sleeping_king_studios-tasks', '~> 0.4', '>= 0.4.1'
gem 'sleeping_king_studios-tools',
  '>= 1.2.0.alpha',
  git:    'https://github.com/sleepingkingstudios/sleeping_king_studios-tools.git',
  branch: 'main'

gem 'yard', '~> 0.9', require: false, group: :doc
