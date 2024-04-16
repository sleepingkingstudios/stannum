# frozen_string_literal: true

$LOAD_PATH << './lib'

require 'stannum/version'

Gem::Specification.new do |gem|
  gem.name        = 'stannum'
  gem.version     = Stannum::VERSION
  gem.summary     = 'A library for specifying and validating data structures.'

  gem.description = <<~DESCRIPTION.strip
    A focused library for specifying and validating data structures. Stannum
    provides tools to define data schemas for domain objects, method arguments,
    or other structured data and to validate data against and coerce data to
    the defined schema.
  DESCRIPTION
  gem.authors     = ['Rob "Merlin" Smith']
  gem.email       = ['merlin@sleepingkingstudios.com']
  gem.homepage    = 'http://sleepingkingstudios.com'
  gem.license     = 'MIT'

  gem.metadata = {
    'bug_tracker_uri'       => 'https://github.com/sleepingkingstudios/stannum/issues',
    'source_code_uri'       => 'https://github.com/sleepingkingstudios/stannum',
    'rubygems_mfa_required' => 'true'
  }

  gem.required_ruby_version = '>= 2.7'
  gem.require_path          = 'lib'
  gem.files                 =
    Dir['config/locales/*', 'lib/**/*.rb', 'LICENSE', '*.md']

  gem.add_runtime_dependency 'sleeping_king_studios-tools', '~> 1.1.0'
end
