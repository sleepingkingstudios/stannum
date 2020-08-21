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
  #
  # @example Accessing Nested Errors via a Key
  #   errors = Stannum::Errors.new
  #   child  = errors[:spell]
  #   child.size #=> 0
  #   child.to_a #=> []
  #
  #   child.add(:insufficient_mana)
  #   child.size # 1
  #   child.to_a # [{ type: :insufficient_mana, path: [] }]
  #
  #   # Adding an error to a child makes it available on a parent.
  #   errors.size # 1
  #   errors.to_a # [{ type: :insufficient_mana, path: [:spell] }]
  #
  # @example Accessing Nested Errors via an Index
  #   errors = Stannum::Errors.new
  #   child  = errors[1]
  #
  #   child.size #=> 0
  #   child.to_a #=> []
  #
  #   child.add(:unknown_monster)
  #   child.size # 1
  #   child.to_a # [{ type: :unknown_monster, path: [] }]
  #
  #   # Adding an error to a child makes it available on a parent.
  #   errors.size # 1
  #   errors.to_a # [{ type: :unknown_monster, path: [1] }]
  #
  # @example Accessing Deeply Nested Errors
  #   errors = Stannum::Errors.new
  #
  #   errors[:towns][1][:name].add(:unpronounceable)
  #   errors.size #=> 1
  #   errors.to_a #=> [{ type: :unpronounceable, path: [:towns, 1, :name] }]
  #
  #   errors[:towns].size #=> 1
  #   errors[:towns].to_a #=> [{ type: :unpronounceable, path: [1, :name] }]
  #
  #   errors[:towns][1].size #=> 1
  #   errors[:towns][1].to_a #=> [{ type: :unpronounceable, path: [:name] }]
  #
  #   errors[:towns][1][:name].size #=> 1
  #   errors[:towns][1][:name].to_a #=> [{ type: :unpronounceable, path: [] }]
  #
  #   # Can also access nested properties via #dig.
  #   errors.dig(:towns, 1, :name).to_a #=> [{ type: :unpronounceable, path: [] }]
  #
  # @example Replacing Errors
  #   errors = Cuprum::Errors.new
  #   errors[:potions][:ingredients].add(:missing_rabbits_foot)
  #   errors.size #=> 1
  #
  #   other = Cuprum::Errors.new.add(:too_hot, :brew_longer, :foul_smelling)
  #   errors[:potions] = other
  #   errors.size #=> 3
  #   errors.to_a
  #   #=> [
  #   #     { type: :brew_longer, path: [:potions] },
  #   #     { type: :foul_smelling, path: [:potions] },
  #   #     { type: :too_hot, path: [:potions] }
  #   #   ]
  #
  # @example Replacing Nested Errors
  #   errors = Cuprum::Errors.new
  #   errors[:armory].add(:empty)
  #
  #   other = Cuprum::Errors.new
  #   other.dig(:weapons, 0).add(:needs_sharpening)
  #   other.dig(:weapons, 1).add(:rusty).add(:out_of_ammo)
  #
  #   errors[:armory] = other
  #   errors.size #=> 3
  #   errors.to_a
  #   #=> [
  #   #     { type: needs_sharpening, path: [:armory, :weapons, 0] },
  #   #     { type: out_of_ammo, path: [:armory, :weapons, 1] },
  #   #     { type: rusty, path: [:armory, :weapons, 1] }
  #   #   ]
  class Errors # rubocop:disable Metrics/ClassLength
    include Enumerable

    def initialize
      @children = Hash.new { |hsh, key| hsh[key] = self.class.new }
      @cache    = Set.new
      @errors   = []
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

    # Accesses a nested errors object.
    #
    # Each errors object can have one or more children, each of which is itself
    # an errors object. These nested errors represent errors on some subset of
    # the main object - for example, a failed validation of a named property,
    # of the value in a key-value pair, or of an indexed value in an ordered
    # collection.
    #
    # The children are created as needed and are stored with either an integer
    # or a symbol key. Calling errors[1] multiple times will always return the
    # same errors object. Likewise, calling errors[:some_key] multiple times
    # will return the same object, and calling errors['some_key'] will return
    # that same errors object as well.
    #
    # @param key [Integer, String, Symbol] The key or index of the referenced
    #   value, item, or property.
    #
    # @return [Stannum::Errors] an Errors object.
    #
    # @raise [ArgumentError] if the key is not a String, Symbol or Integer.
    #
    # @example Accessing Nested Errors via a Key
    #   errors = Stannum::Errors.new
    #   child  = errors[:spell]
    #   child.size #=> 0
    #   child.to_a #=> []
    #
    #   child.add(:insufficient_mana)
    #   child.size # 1
    #   child.to_a # [{ type: :insufficient_mana, path: [] }]
    #
    #   # Adding an error to a child makes it available on a parent.
    #   errors.size # 1
    #   errors.to_a # [{ type: :insufficient_mana, path: [:spell] }]
    #
    # @example Accessing Nested Errors via an Index
    #   errors = Stannum::Errors.new
    #   child  = errors[1]
    #
    #   child.size #=> 0
    #   child.to_a #=> []
    #
    #   child.add(:unknown_monster)
    #   child.size # 1
    #   child.to_a # [{ type: :unknown_monster, path: [] }]
    #
    #   # Adding an error to a child makes it available on a parent.
    #   errors.size # 1
    #   errors.to_a # [{ type: :unknown_monster, path: [1] }]
    #
    # @example Accessing Deeply Nested Errors
    #   errors = Stannum::Errors.new
    #
    #   errors[:towns][1][:name].add(:unpronounceable)
    #   errors.size #=> 1
    #   errors.to_a #=> [{ type: :unpronounceable, path: [:towns, 1, :name] }]
    #
    #   errors[:towns].size #=> 1
    #   errors[:towns].to_a #=> [{ type: :unpronounceable, path: [1, :name] }]
    #
    #   errors[:towns][1].size #=> 1
    #   errors[:towns][1].to_a #=> [{ type: :unpronounceable, path: [:name] }]
    #
    #   errors[:towns][1][:name].size #=> 1
    #   errors[:towns][1][:name].to_a #=> [{ type: :unpronounceable, path: [] }]
    #
    # @see #[]=
    #
    # @see #dig
    def [](key)
      key = normalize_key(key)

      @children[key]
    end

    # Replaces the child errors with the specified errors object or Array.
    #
    # If the given value is nil or an empty array, the #[]= operator will remove
    # the child errors object at the given key, removing all errors within that
    # namespace and all namespaces nested inside it.
    #
    # If the given value is an errors object or an Array of errors object, the
    # #[]= operation will replace the child errors object at the given key,
    # removing all existing errors and adding the new errors. Each added error
    # will use its nested path (if any) as a relative path from the given key.
    #
    # @param key [Integer, String, Symbol] The key or index of the referenced
    #   value, item, or property.
    #
    # @param value [Stannum::Errors, Array[Hash], nil] The errors to insert with
    #   the specified path.
    #
    # @return [Object] the value passed in.
    #
    # @raise [ArgumentError] if the key is not a String, Symbol or Integer.
    #
    # @raise [ArgumentError] if the value is not a valid errors object, Array of
    #   errors hashes, empty Array, or nil.
    #
    # @example Replacing Errors
    #   errors = Cuprum::Errors.new
    #   errors[:potions][:ingredients].add(:missing_rabbits_foot)
    #   errors.size #=> 1
    #
    #   other = Cuprum::Errors.new.add(:too_hot, :brew_longer, :foul_smelling)
    #   errors[:potions] = other
    #   errors.size #=> 3
    #   errors.to_a
    #   #=> [
    #   #     { type: :brew_longer, path: [:potions] },
    #   #     { type: :foul_smelling, path: [:potions] },
    #   #     { type: :too_hot, path: [:potions] }
    #   #   ]
    #
    # @example Replacing Nested Errors
    #   errors = Cuprum::Errors.new
    #   errors[:armory].add(:empty)
    #
    #   other = Cuprum::Errors.new
    #   other.dig(:weapons, 0).add(:needs_sharpening)
    #   other.dig(:weapons, 1).add(:rusty).add(:out_of_ammo)
    #
    #   errors[:armory] = other
    #   errors.size #=> 3
    #   errors.to_a
    #   #=> [
    #   #     { type: needs_sharpening, path: [:armory, :weapons, 0] },
    #   #     { type: out_of_ammo, path: [:armory, :weapons, 1] },
    #   #     { type: rusty, path: [:armory, :weapons, 1] }
    #   #   ]
    #
    # @see #[]
    def []=(key, value)
      key   = normalize_key(key)
      value = normalize_value(value, allow_nil: true)

      @children[key] = value
    end

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
    # @return [Stannum::Errors] the errors object.
    #
    # @raise [ArgumentError] if the type or message are invalid.
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
    def add(type, message: nil, **data)
      error  = build_error(data: data, message: message, type: type)
      hashed = error.hash

      return self if @cache.include?(hashed)

      @errors << error
      @cache  << hashed

      self
    end

    # Accesses a (possibly deeply) nested errors object.
    #
    # Similiar to the #[] method, but can access a deeply nested errors object
    # as well. The #dig method can take either a list of one or more keys
    # (Integers, Strings, and Symbols) as arguments, or an Array of keys.
    # Calling errors.dig is equivalent to calling errors[] with each key in
    # sequence.
    #
    # @return [Stannum::Errors] the nested error object at the specified path.
    #
    # @raise [ArgumentError] if the keys are not Strings, Symbols or Integers.
    #
    # @overload dig(keys)
    #   @param keys [Array<Integer, String, Symbol>] The path to the nested
    #     errors object, as an array of Integers, Strings, and Symbols.
    #
    # @overload dig(*keys)
    #   @param keys [Array<Integer, String, Symbol>] The path to the nested
    #     errors object, as individual Integers, Strings, and Symbols.
    #
    # @example Accessing Nested Errors via a Key
    #   errors = Stannum::Errors.new
    #   child  = errors.dig(:spell)
    #   child.size #=> 0
    #   child.to_a #=> []
    #
    #   child.add(:insufficient_mana)
    #   child.size # 1
    #   child.to_a # [{ type: :insufficient_mana, path: [] }]
    #
    #   # Adding an error to a child makes it available on a parent.
    #   errors.size # 1
    #   errors.to_a # [{ type: :insufficient_mana, path: [:spell] }]
    #
    # @example Accessing Nested Errors via an Index
    #   errors = Stannum::Errors.new
    #   child  = errors.dig(1)
    #
    #   child.size #=> 0
    #   child.to_a #=> []
    #
    #   child.add(:unknown_monster)
    #   child.size # 1
    #   child.to_a # [{ type: :unknown_monster, path: [] }]
    #
    #   # Adding an error to a child makes it available on a parent.
    #   errors.size # 1
    #   errors.to_a # [{ type: :unknown_monster, path: [1] }]
    #
    # @example Accessing Deeply Nested Errors
    #   errors = Stannum::Errors.new
    #
    #   errors.dig(:towns, 1, :name).add(:unpronounceable)
    #   errors.size #=> 1
    #   errors.to_a #=> [{ type: :unpronounceable, path: [:towns, 1, :name] }]
    #
    #   errors.dig(:towns).size #=> 1
    #   errors.dig(:towns).to_a #=> [{ type: :unpronounceable, path: [1, :name] }]
    #
    #   errors.dig(:towns, 1).size #=> 1
    #   errors.dig(:towns, 1).to_a #=> [{ type: :unpronounceable, path: [:name] }]
    #
    #   errors.dig(:towns, 1, :name).size #=> 1
    #   errors.dig(:towns, 1, :name).to_a #=> [{ type: :unpronounceable, path: [] }]
    #
    # @see #[]
    def dig(first, *rest)
      path = first.is_a?(Array) ? first : [first, *rest]

      path.reduce(self) { |errors, segment| errors[segment] }
    end

    # Creates a deep copy of the errors object.
    #
    # @return [Stannum::Errors] the copy of the errors object.
    def dup # rubocop:disable Metrics/MethodLength
      child = self.class.new

      each do |error|
        child
          .dig(error.fetch(:path, []))
          .add(
            error.fetch(:type),
            message: error[:message],
            **error.fetch(:data, {})
          )
      end

      child
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

      @children.each do |path, child|
        child.each do |item|
          yield item.merge(path: item.fetch(:path, []).dup.unshift(path))
        end
      end
    end

    # Checks if the errors object contains any errors.
    #
    # @return [true, false] true if the errors object has no errors, otherwise
    #   false.
    def empty?
      @errors.empty? && @children.all?(&:empty?)
    end
    alias blank? empty?

    # Adds the given errors to a copy of the errors object.
    #
    # Creates a copy of the errors object, and then adds each error in the
    # passed in errors object or array to the copy. The copy will thus contain
    # all of the errors from the original object and all of the errors from the
    # passed in object. The original object is not changed.
    #
    # @param value [Stannum::Errors, Array[Hash]] The errors to add to the
    #   copied errors object.
    #
    # @return [Stannum::Errors] the copied errors object.
    #
    # @raise [ArgumentError] if the value is not a valid errors object or Array
    #   of errors hashes.
    #
    # @see #update.
    def merge(value)
      value = normalize_value(value, allow_nil: false)

      dup.update_errors(value)
    end

    # The number of errors in the errors object.
    #
    # @return [Integer] the number of errors.
    def size
      @errors.size + @children.each_value.reduce(0) do |total, child|
        total + child.size
      end
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

    # Adds the given errors to the errors object.
    #
    # Adds each error in the passed in errors object or array to the current
    # errors object. It will then contain all of the original errors and all of
    # the errors from the passed in object. This changes the current object.
    #
    # @param value [Stannum::Errors, Array[Hash]] The errors to add to the
    #   current errors object.
    #
    # @return [self] the current errors object.
    #
    # @raise [ArgumentError] if the value is not a valid errors object or Array
    #   of errors hashes.
    #
    # @see #merge.
    def update(value)
      value = normalize_value(value, allow_nil: false)

      update_errors(value)
    end

    protected

    def update_errors(other_errors)
      other_errors.each do |error|
        dig(error.fetch(:path, []))
          .add(
            error.fetch(:type),
            message: error[:message],
            **error.fetch(:data, {})
          )
      end

      self
    end

    private

    def build_error(data:, message:, type:)
      type = normalize_type(type)
      msg  = normalize_message(message)

      { data: data, message: msg, type: type }
    end

    def compare_hashed_errors(other_errors)
      hashes       = Set.new(map(&:hash))
      other_hashes = Set.new(other_errors.map(&:hash))

      hashes == other_hashes
    end

    def invalid_value_error(allow_nil)
      values = ['an instance of Stannum::Errors', 'an array of error hashes']
      values << 'nil' if allow_nil

      'value must be ' +
        tools.array_tools.humanize_list(values, last_separator: ' or ')
    end

    def normalize_array_item(item, allow_nil:)
      unless item.is_a?(Hash) && item.key?(:type)
        raise ArgumentError, invalid_value_error(allow_nil)
      end

      item
    end

    def normalize_array_value(ary, allow_nil:)
      child = self.class.new

      ary.each do |item|
        err  = normalize_array_item(item, allow_nil: allow_nil)
        data = err.fetch(:data, {})
        path = err.fetch(:path, [])

        child.dig(path).add(err[:type], message: err[:message], **data)
      end

      child
    end

    def normalize_key(key)
      return key if key.is_a?(Integer) || key.is_a?(Symbol)

      return key.intern if key.is_a?(String)

      raise ArgumentError, 'key must be an Integer, a String or a Symbol'
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

    def normalize_value(value, allow_nil: false)
      return self.class.new if value.nil? && allow_nil

      return value.dup if value.is_a?(self.class)

      if value.is_a?(Array)
        return normalize_array_value(value, allow_nil: allow_nil)
      end

      raise ArgumentError, invalid_value_error(allow_nil)
    end

    def tools
      SleepingKingStudios::Tools::Toolbelt.instance
    end
  end
end
