# frozen_string_literal: true

require 'stannum'

module Stannum
  # An errors object represents a collection of errors.
  #
  # Most of the time, an end user will not be creating an Errors object
  # directly. Instead, an errors object may be returned by a process that
  # validates or coerces data to an expected form. For one such example, see
  # the Stannum::Constraint and its subclasses.
  #
  # Internally, an errors object is an Array of errors. Each error is
  # represented by a Hash containing the keys :data, :message and :type.
  # represented by a Hash containing the keys :data, :message, :path and :type.
  #
  # - The :type of the error is a short, unique symbol or string that identifies
  #   the type of the error, such as 'invalid' or 'not_found'. The type is
  #   frequently namespaced, e.g. 'stannum.constraints.present'.
  # - The :message of the error is a short string that provides a human-readable
  #   description of the error, such as 'is invalid' or 'is not found'. The
  #   message may include format directives for error data (see below). If the
  #   :message key is missing or the value is nil, use a default error message
  #   or generate the message from the :type.
  # - The :data of the error stores additional information about the error and
  #   the expected behavior. For example, an out of range error might have
  #   type: 'out_of_range' and data { min: 0, max: 10 }, indicating that the
  #   expected values were between 0 and 10. If the data key is missing or the
  #   value is empty, there is no additional information about the error.
  # - The :path of the error reflects the steps to resolve the relevant property
  #   from the given data object. The path is an Array with keys of either
  #   Symbols/Strings (for object properties or Hash keys) or Integers (for
  #   Array indices). For example, given the hash { companies: [{ teams: [] }] }
  #   and an expecation that a company's team must not be empty, the resulting
  #   error would have path: [:companies, 0, :teams]. if the path key is missing
  #   or the value is empty, the error refers to the root object.
  #
  # @example Creating An Errors Object
  #   errors = Stannum::Errors.new
  #
  # @example Adding Errors
  #   errors.add(:not_numeric)
  #
  #   # Add an error with a custom message.
  #   errors.add(:invalid, message: 'is not valid')
  #
  #   # Add an error with additional data.
  #   errors.add(:out_of_range, min: 0, max: 10)
  #
  #   # Add multiple errors.
  #   errors.add(:first_error).add(:second_error).add(:third_error)
  #
  # @example Viewing The Errors
  #   errors.empty? #=> false
  #   errors.size   #=> 6
  #
  #   errors.each { |err| } #=> yields each error to the block
  #   errors.to_a           #=> returns an array containing each error
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
    # @param type [String, Symbol] The error type. This should be a string or
    #   symbol with one or more underscored, dot-separated values.
    # @param message [String] A custom error message to display. Optional;
    #   defaults to nil.
    # @param data [Hash<Symbol, Object>] Additional data to store about the
    #   error, such as the expected type or the min/max values of the expected
    #   range. Optional; defaults to an empty Hash.
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
    # @return [Stannum::Errors] the errors object.
    def add(type, message: nil, **data)
      type = normalize_type(type)
      msg  = normalize_message(message)
      err  = { data: data, message: msg, type: type }

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
    #     is a hash containing the keys :data, :message, :path and :type.
    def each
      return to_enum(:each) { size } unless block_given?

      @errors.each { |item| yield item.merge(path: []) }
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
    # Each error is a hash containing the keys :data, :message, :path and :type.
    #
    # @return [Array<Hash>] the error objects.
    def to_a
      each.to_a
    end

    private

    def compare_hashed_errors(other_errors)
      hashes       = Set.new(map(&:hash))
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
