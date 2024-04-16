# frozen_string_literal: true

require 'stannum/associations'

module Stannum::Associations
  # Data object representing a singular association.
  class One < Stannum::Association
    # Builder class for defining association methods on an entity.
    class Builder < Stannum::Association::Builder
      private

      def define_reader(association)
        entity_class.define_method(association.reader_name) do
          association.read_association(self)
        end
      end

      def define_writer(association)
        entity_class.define_method(association.writer_name) do |value|
          association.write_association(self, value)
        end
      end
    end

    # (see Stannum::Association#clear_association)
    def clear_association(entity)
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

    # @return [true] true if the association is a singular association;
    #   otherwise false.
    def one?
      true
    end

    # (see Stannum::Association#read_association)
    def read_association(entity)
      entity.read_association(name, safe: false)
    end

    # (see Stannum::Association#read_association)
    def write_association(entity, value)
      entity.write_association(name, value, safe: false)
    end
  end
end
