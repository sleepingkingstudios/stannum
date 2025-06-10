# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'sleeping_king_studios-tasks', '~> 0.4', '>= 0.4.1'
gem 'sleeping_king_studios-tools', '~> 1.2'

group :development, :test do
  gem 'bigdecimal', '~> 3.1'
  gem 'byebug', '~> 11.0'

  gem 'rspec', '~> 3.13'
  gem 'rspec-sleeping_king_studios', '~> 2.8'
  gem 'rubocop', '~> 1.76'
  gem 'rubocop-rspec', '~> 3.6'
  gem 'simplecov', '~> 0.22'
end

group :docs do
  gem 'jekyll', '~> 4.4'
  gem 'jekyll-theme-dinky', '~> 0.2'

  # Use Kramdown to parse GFM-dialect Markdown.
  gem 'kramdown-parser-gfm', '~> 1.1'

  gem 'sleeping_king_studios-docs', '~> 0.1'

  # Use Webrick as local content server.
  gem 'webrick', '~> 1.9'

  gem 'yard', '~> 0.9', require: false
end
