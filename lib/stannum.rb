# frozen_string_literal: true

require 'stannum/version'

# A library for specifying and validating data structures.
module Stannum
  autoload :Constraint,  'stannum/constraint'
  autoload :Constraints, 'stannum/constraints'
  autoload :Contracts,   'stannum/contracts'
  autoload :Errors,      'stannum/errors'
  autoload :Struct,      'stannum/struct'

  # @return [String] the absolute path to the gem directory.
  def self.gem_path
    pattern = /#{File::SEPARATOR}lib#{File::SEPARATOR}?\z/

    __dir__.sub(pattern, '')
  end

  # @return [String] the current version of the gem.
  def self.version
    @version ||= Stannum::Version.to_gem_version
  end
end
