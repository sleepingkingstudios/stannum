# frozen_string_literal: true

require 'stannum/version'

# A library for specifying and validating data structures.
module Stannum
  autoload :Attribute,           'stannum/attribute'
  autoload :Constraint,          'stannum/constraint'
  autoload :Constraints,         'stannum/constraints'
  autoload :Contract,            'stannum/contract'
  autoload :Contracts,           'stannum/contracts'
  autoload :Entities,            'stannum/entities'
  autoload :Entity,              'stannum/entity'
  autoload :Errors,              'stannum/errors'
  autoload :Messages,            'stannum/messages'
  autoload :ParameterValidation, 'stannum/parameter_validation'
  autoload :Schema,              'stannum/schema'
  autoload :Struct,              'stannum/struct'

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
