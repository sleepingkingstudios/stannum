# frozen_string_literal: true

require 'stannum/associations'

module Stannum::Associations
  # Data object representing a singular association.
  class One < Stannum::Association
    # (see Stannum::Association#add_value)
    def add_value(entity, value, update_inverse: true)
      set_value(entity, value, update_inverse:)
    end

    # (see Stannum::Association#add_value)
    def clear_value(entity, update_inverse: true)
      previous_value = entity.read_association(name, safe: false)

      if update_inverse && previous_value && inverse?
        resolved_inverse.remove_value(
          previous_value,
          entity,
          update_inverse: false
        )
      end

      entity.write_attribute(foreign_key_name, nil, safe: false) if foreign_key?

      entity.write_association(name, nil, safe: false)
    end

    # @return [Boolean] true if the association has a foreign key; otherwise
    #   false.
    def foreign_key?
      return @has_foreign_key unless @has_foreign_key.nil?

      value = options[:foreign_key_name]

      return @has_foreign_key = false if value.nil? || value == false

      @has_foreign_key = true
    end

    # @return [String?] the name of the foreign key, if any.
    def foreign_key_name
      return nil unless foreign_key?

      @foreign_key_name ||= options[:foreign_key_name].to_s
    end

    # @return [Class, Stannum::Constraint, nil] the type of the foreign key, if
    #   any.
    def foreign_key_type
      return nil unless foreign_key?

      @foreign_key_type ||= options[:foreign_key_type]
    end

    # (see Stannum::Association#get_value)
    def get_value(entity)
      entity.read_association(name, safe: false)
    end

    # @return [true] true if the association is a singular association;
    #   otherwise false.
    def one?
      true
    end

    # (see Stannum::Association#remove_value)
    def remove_value(entity, value, update_inverse: true)
      previous_value = entity.read_association(name, safe: false)

      return unless matching_value?(value, previous_value)

      clear_value(entity, update_inverse:)
    end

    # (see Stannum::Association#set_value)
    def set_value(entity, value, update_inverse: true) # rubocop:disable Metrics/MethodLength
      if foreign_key?
        entity.write_attribute(
          foreign_key_name,
          value&.primary_key,
          safe: false
        )
      end

      entity.write_association(name, value, safe: false)

      return unless update_inverse && value && inverse?

      previous_inverse = resolved_inverse.get_value(value)

      resolved_inverse.remove_value(value, previous_inverse) if previous_inverse

      resolved_inverse.add_value(value, entity, update_inverse: false)
    end

    private

    def matching_value?(value, previous_value)
      return true if value == previous_value

      foreign_key? && (value == previous_value&.primary_key)
    end
  end
end
