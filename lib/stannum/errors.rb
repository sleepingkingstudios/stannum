# frozen_string_literal: true

require 'stannum'

module Stannum
  # An errors object represents a collection of errors
  class Errors
    include Enumerable

    def initialize
      @errors = []
    end

    # Checks if the other errors object contains the same errors.
    #
    # @return [true, false] true if the other object is an errors object or an
    #   array with the same class and errors, otherwise false.
    def ==(other)
      return false unless other.is_a?(Array) || other.is_a?(self.class)

      return false unless empty? == other.empty?

      compare_hashed_errors(other)
    end
    alias eql? ==

    # Adds an error of the specified type.
    #
    # @example Adding An Error
    #   errors = Stannum::Errors.new.add(:not_found)
    #
    # @example Adding An Error With A Message
    #   errors = Stannum::Errors.new.add(:not_found, message: 'is missing')
    #
    # @example Adding Multiple Errors
    #   errors = Stannum::Errors.new
    #   errors
    #     .add(:not_numeric)
    #     .add(:not_integer, message: 'is outside the range')
    #     .add(:not_in_range)
    #
    # @param type [String, Symbol] The error type. This should be a string or
    #   symbol with one or more underscored, dot-separated values.
    # @param message [String] A custom error message to display.
    #
    # @return [Stannum::Errors] the errors object.
    def add(type, message: nil)
      type = normalize_type(type)
      msg  = normalize_message(message)
      err  = { message: msg, type: type }

      @errors << err

      self
    end

    # @overload each
    #   Returns an Enumerator that iterates through the errors.
    #
    #   @return [Enumerator]
    #
    # @overload each
    #   Iterates through the errors, yielding each error to the provided block.
    #
    #   @yieldparam error [Hash<Symbol=>Object>] The error object. Each error
    #     is a hash containing the keys :message and :type.
    def each
      return to_enum(:each) { size } unless block_given?

      @errors.each { |item| yield item }
    end

    # Checks if the errors object contains any errors.
    #
    # @return [true, false] true if the errors object has no errors, otherwise
    #   false.
    def empty?
      @errors.empty?
    end
    alias blank? empty?

    # The number of errors in the errors object.
    #
    # @return [Integer] the number of errors.
    def size
      @errors.size
    end
    alias count size

    # Generates an array of error objects.
    #
    # Each error is a hash containing the keys :message and :type.
    #
    # @return [Array<Hash>] the error objects.
    def to_a
      each.to_a
    end

    private

    def compare_hashed_errors(other_errors)
      hashes       = Set.new(@errors.map(&:hash))
      other_hashes = Set.new(other_errors.map(&:hash))

      hashes == other_hashes
    end

    def normalize_message(message)
      return if message.nil?

      unless message.is_a?(String)
        raise ArgumentError, 'message must be a String'
      end

      raise ArgumentError, "message can't be blank" if message.empty?

      message
    end

    def normalize_type(type)
      raise ArgumentError, "error type can't be nil" if type.nil?

      unless type.is_a?(String) || type.is_a?(Symbol)
        raise ArgumentError, 'error type must be a String or Symbol'
      end

      raise ArgumentError, "error type can't be blank" if type.empty?

      type.to_s
    end
  end
end
