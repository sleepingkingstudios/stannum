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
          read_association(association.name, safe: false)
        end
      end

      def define_writer(association)
        entity_class.define_method(association.writer_name) do |value|
          write_association(association.name, value, safe: false)
        end
      end
    end

    # @return [true] true if the association is a singular association;
    #   otherwise false.
    def one?
      true
    end
  end
end
