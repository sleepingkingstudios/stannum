# frozen_string_literal: true

require 'stannum/associations'

module Stannum::Associations
  # Data object representing a plural association.
  class Many < Stannum::Association
    # Wrapper object for an entity's plural association.
    class Proxy
      include Enumerable

      # @param association [Stannum::Associations::Many] the association being
      #   wrapped.
      # @param entity [Stannum::Entity] the entity instance whose association is
      #   being wrapped.
      def initialize(association:, entity:)
        @association = association
        @entity      = entity
      end

      # @overload each
      #   @return [Enumerator] an enumerator over each item in the entity's
      #     association data.
      #
      # @overload each(&block)
      #   @yield Yields each item in the entity's association data.
      #   @yieldparam item [Stannum::Entity] the associated entity.
      def each(&)
        return enum_for(:each) unless block_given?

        (entity.read_association(association.name, safe: false) || []).each(&)
      end

      private

      attr_reader :association

      attr_reader :entity
    end

    # (see Stannum::Association#add_value)
    def add_value(entity, value, update_inverse: true)
      return unless value

      data = entity.read_association(name, safe: false) || []

      data, changed = add_item(data:, value:)

      entity.write_association(name, data, safe: false) if changed

      update_item_inverse(entity:, value:) if inverse? && update_inverse

      nil
    end

    # (see Stannum::Association#clear_value)
    def clear_value(entity, update_inverse: true)
      data = entity.read_association(name, safe: false) || []

      entity.write_association(name, [], safe: false)

      if inverse? && update_inverse
        data.each { |item| remove_item_inverse(value: item) }
      end

      nil
    end

    # (see Stannum::Association#get_value)
    def get_value(entity)
      @proxy ||= Proxy.new(association: self, entity:) # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    # @return [true] true if the association is a plural association; otherwise
    #   false.
    def many?
      true
    end

    # (see Stannum::Association#remove_value)
    def remove_value(entity, value, update_inverse: true)
      return unless value

      data = entity.read_association(name, safe: false) || []

      data, changed = remove_item(data:, value:)

      return unless changed

      entity.write_association(name, data, safe: false)

      remove_item_inverse(value:) if inverse? && update_inverse

      nil
    end

    # (see Stannum::Association#set_value)
    def set_value(entity, value, update_inverse: true)
      data = entity.read_association(name, safe: false) || []

      value&.each do |item|
        next unless item

        data, _ = add_item(data:, value: item)

        update_item_inverse(entity:, value: item) if inverse? && update_inverse
      end

      entity.write_association(name, data, safe: false)

      nil
    end

    private

    def add_item(data:, value:)
      return data, false if data.include?(value)

      data = [*data, value]

      [data, true]
    end

    def remove_item(data:, value:)
      return data, false unless data.include?(value)

      data = data.reject { |item| item == value }

      [data, true]
    end

    def remove_item_inverse(value:, inverse_value: nil, update_inverse: false)
      inverse_value ||= resolved_inverse.get_value(value)

      return unless inverse_value

      resolved_inverse.remove_value(value, inverse_value, update_inverse:)
    end

    def update_item_inverse(entity:, value:)
      inverse_value = resolved_inverse.get_value(value)

      return if entity == inverse_value

      if inverse_value
        remove_item_inverse(inverse_value:, value:, update_inverse: true)
      end

      resolved_inverse.add_value(value, entity, update_inverse: false)
    end
  end
end
