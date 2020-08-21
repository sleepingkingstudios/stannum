# frozen_string_literal: true

require 'forwardable'

require 'stannum/contracts/legacy_hash_contract'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Contracts::LegacyHashContract do
  include Spec::Support::Examples::ConstraintExamples

  shared_context 'when initialized with allow_extra_keys: false' do
    before(:example) { options.update(allow_extra_keys: false) }
  end

  shared_context 'when initialized with allow_hash_like: false' do
    before(:example) { options.update(allow_hash_like: false) }
  end

  shared_context 'when initialized with key_type: :any' do
    before(:example) { options.update(key_type: :any) }
  end

  shared_context 'when initialized with key_type: :indifferent' do
    before(:example) { options.update(key_type: :indifferent) }
  end

  shared_context 'when initialized with key_type: :string' do
    before(:example) { options.update(key_type: :string) }
  end

  shared_context 'when initialized with key_type: :symbol' do
    before(:example) { options.update(key_type: :symbol) }
  end

  subject(:contract) { described_class.new(**options, &block) }

  let(:block)   { -> {} }
  let(:options) { {} }

  example_class 'Spec::HashLike' do |klass|
    klass.class_eval do
      extend Forwardable

      def initialize(properties = {})
        @properties = properties
      end

      def_delegators :@properties, :[], :key?, :keys
    end
  end

  describe '::EXTRA_KEYS_TYPE' do
    include_examples 'should define frozen constant',
      :EXTRA_KEYS_TYPE,
      'stannum.constraints.hash_with_extra_keys'
  end

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.is_hash_like'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.is_not_hash_like'
  end

  describe '::new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:allow_extra_keys, :allow_hash_like, :key_type)
        .and_a_block
    end

    it 'should extend the instance with AnyKeys' do
      expect(contract).to be_a described_class::AnyKeys
    end

    describe 'with key_type: an invalid value' do
      let(:options) { super().merge(key_type: :nil) }
      let(:error_message) do
        'key_type must be :any, :indifferent, :string, or :symbol'
      end

      it 'should raise an error' do
        expect { described_class.new(**options) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with key_type: any' do
      let(:options) { super().merge(key_type: :any) }

      it 'should extend the instance with AnyKeys' do
        expect(contract).to be_a described_class::AnyKeys
      end
    end

    describe 'with key_type: indifferent' do
      let(:options) { super().merge(key_type: :indifferent) }

      it 'should extend the instance with IndifferentKeys' do
        expect(contract).to be_a described_class::IndifferentKeys
      end
    end

    describe 'with key_type: string' do
      let(:options) { super().merge(key_type: :string) }

      it 'should extend the instance with StringKeys' do
        expect(contract).to be_a described_class::StringKeys
      end
    end

    describe 'with key_type: symbol' do
      let(:options) { super().merge(key_type: :symbol) }

      it 'should extend the instance with SymbolKeys' do
        expect(contract).to be_a described_class::SymbolKeys
      end
    end
  end

  describe '#access_property' do
    let(:property_name) { :property }

    context 'when the object does not respond to :[]' do
      let(:actual) { Object.new.freeze }

      it 'should return nil' do
        expect(contract.send(:access_property, actual, property_name))
          .to be nil
      end
    end

    context 'when the object does not have the key' do
      let(:actual) { {} }

      it 'should return nil' do
        expect(contract.send(:access_property, actual, property_name))
          .to be nil
      end
    end

    context 'when the object has the key' do
      let(:actual) { { property_name => value } }
      let(:value)  { 'property_value' }

      it 'should return the value' do
        expect(contract.send(:access_property, actual, property_name))
          .to be value
      end
    end

    wrap_context 'when initialized with key_type: :indifferent' do
      context 'when the object does not respond to :[]' do
        let(:actual) { Object.new.freeze }

        it 'should return nil' do
          expect(contract.send(:access_property, actual, property_name))
            .to be nil
        end
      end

      describe 'with a string' do
        let(:property_name) { 'property' }

        context 'when the object does not have the key' do
          let(:actual) { {} }

          it 'should return nil' do
            expect(contract.send(:access_property, actual, property_name))
              .to be nil
          end
        end

        context 'when the object has the key as a string' do
          let(:actual) { { property_name.to_s => value } }
          let(:value)  { 'property_value' }

          it 'should return the value' do
            expect(contract.send(:access_property, actual, property_name))
              .to be value
          end
        end

        context 'when the object has the key as a symbol' do
          let(:actual) { { property_name.intern => value } }
          let(:value)  { 'property_value' }

          it 'should return the value' do
            expect(contract.send(:access_property, actual, property_name))
              .to be value
          end
        end
      end

      describe 'with a symbol' do
        let(:property_name) { :property }

        context 'when the object does not have the key' do
          let(:actual) { {} }

          it 'should return nil' do
            expect(contract.send(:access_property, actual, property_name))
              .to be nil
          end
        end

        context 'when the object has the key as a string' do
          let(:actual) { { property_name.to_s => value } }
          let(:value)  { 'property_value' }

          it 'should return the value' do
            expect(contract.send(:access_property, actual, property_name))
              .to be value
          end
        end

        context 'when the object has the key as a symbol' do
          let(:actual) { { property_name.intern => value } }
          let(:value)  { 'property_value' }

          it 'should return the value' do
            expect(contract.send(:access_property, actual, property_name))
              .to be value
          end
        end
      end
    end
  end

  describe '#allow_extra_keys?' do
    include_examples 'should have predicate', :allow_extra_keys?, true

    wrap_context 'when initialized with allow_extra_keys: false' do
      it { expect(contract.allow_extra_keys?).to be false }
    end
  end

  describe '#allow_hash_like?' do
    include_examples 'should have predicate', :allow_hash_like?, true

    wrap_context 'when initialized with allow_hash_like: false' do
      it { expect(contract.allow_hash_like?).to be false }
    end
  end

  describe '#key_type' do
    include_examples 'should have reader', :key_type, :any

    wrap_context 'when initialized with key_type: :any' do
      it { expect(contract.key_type).to be :any }
    end

    wrap_context 'when initialized with key_type: :indifferent' do
      it { expect(contract.key_type).to be :indifferent }
    end

    wrap_context 'when initialized with key_type: :string' do
      it { expect(contract.key_type).to be :string }
    end

    wrap_context 'when initialized with key_type: :symbol' do
      it { expect(contract.key_type).to be :symbol }
    end
  end

  describe '#negated_type' do
    include_examples 'should have reader',
      :negated_type,
      'stannum.constraints.is_hash_like'
  end

  describe '#options' do
    let(:expected) do
      {
        allow_extra_keys: true,
        allow_hash_like:  true,
        key_type:         :any
      }.merge(options)
    end

    include_examples 'should have reader', :options, -> { be == expected }

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'when initialized with allow_extra_keys: false' do
      it { expect(contract.options).to be == expected }
    end

    wrap_context 'when initialized with allow_hash_like: false' do
      it { expect(contract.options).to be == expected }
    end

    wrap_context 'when initialized with key_type: :any' do
      it { expect(contract.options).to be == expected }
    end

    wrap_context 'when initialized with key_type: :indifferent' do
      it { expect(contract.options).to be == expected }
    end

    wrap_context 'when initialized with key_type: :string' do
      it { expect(contract.options).to be == expected }
    end

    wrap_context 'when initialized with key_type: :symbol' do
      it { expect(contract.options).to be == expected }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#type' do
    include_examples 'should have reader',
      :type,
      'stannum.constraints.is_not_hash_like'
  end

  describe '#valid_property?' do
    describe 'with nil' do
      it { expect(contract.send :valid_property?, nil).to be true }
    end

    describe 'with an object' do
      let(:object) { Object.new.freeze }

      it { expect(contract.send :valid_property?, object).to be true }
    end

    describe 'with an empty string' do
      it { expect(contract.send :valid_property?, '').to be true }
    end

    describe 'with a string' do
      let(:property) { 'property_name' }

      it { expect(contract.send :valid_property?, property).to be true }
    end

    describe 'with an empty symbol' do
      it { expect(contract.send :valid_property?, :'').to be true }
    end

    describe 'with a symbol' do
      let(:property) { :property_name }

      it { expect(contract.send :valid_property?, property).to be true }
    end

    wrap_context 'when initialized with key_type: :any' do
      describe 'with nil' do
        it { expect(contract.send :valid_property?, nil).to be true }
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }

        it { expect(contract.send :valid_property?, object).to be true }
      end

      describe 'with an empty string' do
        it { expect(contract.send :valid_property?, '').to be true }
      end

      describe 'with a string' do
        let(:property) { 'property_name' }

        it { expect(contract.send :valid_property?, property).to be true }
      end

      describe 'with an empty symbol' do
        it { expect(contract.send :valid_property?, :'').to be true }
      end

      describe 'with a symbol' do
        let(:property) { :property_name }

        it { expect(contract.send :valid_property?, property).to be true }
      end
    end

    wrap_context 'when initialized with key_type: :indifferent' do
      describe 'with nil' do
        it { expect(contract.send :valid_property?, nil).to be false }
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }

        it { expect(contract.send :valid_property?, object).to be false }
      end

      describe 'with an empty string' do
        it { expect(contract.send :valid_property?, '').to be false }
      end

      describe 'with a string' do
        let(:property) { 'property_name' }

        it { expect(contract.send :valid_property?, property).to be true }
      end

      describe 'with an empty symbol' do
        it { expect(contract.send :valid_property?, :'').to be false }
      end

      describe 'with a symbol' do
        let(:property) { :property_name }

        it { expect(contract.send :valid_property?, property).to be true }
      end
    end

    wrap_context 'when initialized with key_type: :string' do
      describe 'with nil' do
        it { expect(contract.send :valid_property?, nil).to be false }
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }

        it { expect(contract.send :valid_property?, object).to be false }
      end

      describe 'with an empty string' do
        it { expect(contract.send :valid_property?, '').to be false }
      end

      describe 'with a string' do
        let(:property) { 'property_name' }

        it { expect(contract.send :valid_property?, property).to be true }
      end

      describe 'with an empty symbol' do
        it { expect(contract.send :valid_property?, :'').to be false }
      end

      describe 'with a symbol' do
        let(:property) { :property_name }

        it { expect(contract.send :valid_property?, property).to be false }
      end
    end

    wrap_context 'when initialized with key_type: :symbol' do
      describe 'with nil' do
        it { expect(contract.send :valid_property?, nil).to be false }
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }

        it { expect(contract.send :valid_property?, object).to be false }
      end

      describe 'with an empty string' do
        it { expect(contract.send :valid_property?, '').to be false }
      end

      describe 'with a string' do
        let(:property) { 'property_name' }

        it { expect(contract.send :valid_property?, property).to be false }
      end

      describe 'with an empty symbol' do
        it { expect(contract.send :valid_property?, :'').to be false }
      end

      describe 'with a symbol' do
        let(:property) { :property_name }

        it { expect(contract.send :valid_property?, property).to be true }
      end
    end
  end

  context 'with no defined constraints' do
    let(:expected_errors) do
      errors = []

      if !contract.allow_hash_like? && !actual.is_a?(Hash)
        errors << {
          data: { type: Hash },
          type: Stannum::Constraints::Type::TYPE
        }
      elsif !(actual.respond_to?(:[]) && actual.respond_to?(:key?))
        errors << { type: described_class::TYPE }
      end

      errors.map do |error|
        {
          data:    {},
          message: nil,
          path:    []
        }.merge(error)
      end
    end
    let(:negated_errors) do
      errors = []

      if !contract.allow_hash_like? && actual.is_a?(Hash)
        errors << {
          data: { type: Hash },
          type: Stannum::Constraints::Type::NEGATED_TYPE
        }
      elsif actual.respond_to?(:[]) && actual.respond_to?(:key?)
        errors << { type: described_class::NEGATED_TYPE }
      end

      errors.map do |error|
        {
          data:    {},
          message: nil,
          path:    []
        }.merge(error)
      end
    end

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should match', {}, as: 'a hash', reversible: true

    include_examples 'should match',
      -> { Spec::HashLike.new },
      as:         'a hash-like object',
      reversible: true

    wrap_context 'when initialized with allow_hash_like: false' do
      include_examples 'should match', {}, as: 'a hash', reversible: true

      include_examples 'should not match',
        -> { Spec::HashLike.new },
        as:         'a hash-like object',
        reversible: true
    end
  end

  context 'with many defined constraints' do
    let(:manufacturer) { Spec::Manufacturer.new }
    let(:name_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.is_name',
        type:         'spec.is_not_name'
      ) \
      do |actual|
        actual.is_a?(String) && !actual.empty?
      end
    end
    let(:block) do
      constraint = name_constraint

      lambda do
        property(:length)       { |actual| actual.is_a?(Integer) }
        property :name,         constraint
        property :manufacturer, Spec::Manufacturer::Contract
      end
    end
    let(:partial_strings) do
      {
        'length' => 10,
        'name'   => 'Self-sealing Stem Bolt'
      }
    end
    let(:partial_symbols) do
      {
        length: 10,
        name:   'Self-sealing Stem Bolt'
      }
    end
    let(:matching_strings) do
      {
        'length'       => 10,
        'manufacturer' => manufacturer,
        'name'         => 'Self-sealing Stem Bolt'
      }
    end
    let(:matching_symbols) do
      {
        length:       10,
        manufacturer: manufacturer,
        name:         'Self-sealing Stem Bolt'
      }
    end
    let(:extra_strings) do
      {
        'length'       => 10,
        'manufacturer' => manufacturer,
        'name'         => 'Self-sealing Stem Bolt',
        'price'        => '$9,999.99',
        'size'         => 'Extra Large'
      }
    end
    let(:extra_symbols) do
      {
        length:       10,
        manufacturer: manufacturer,
        name:         'Self-sealing Stem Bolt',
        price:        '$9,999.99',
        size:         'Extra Large'
      }
    end
    let(:expected_errors) do
      errors = []

      if !contract.allow_hash_like? && !actual.is_a?(Hash)
        return [
          {
            data:    { type: Hash },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      elsif !(actual.respond_to?(:[]) && actual.respond_to?(:key?))
        errors << { type: described_class::TYPE }
      else
        unless fetch(:length).is_a?(Integer)
          errors << { path: %i[length], type: Stannum::Constraints::Base::TYPE }
        end

        unless fetch(:name).is_a?(String) && !fetch(:name).empty?
          errors << { path: %i[name], type: 'spec.is_not_name' }
        end

        unless fetch(:manufacturer).is_a?(Spec::Manufacturer)
          errors << {
            data: { type: Spec::Manufacturer },
            path: %i[manufacturer],
            type: Stannum::Constraints::Type::TYPE
          }
        end
      end

      if actual.respond_to?(:keys) && !contract.allow_extra_keys?
        extra_keys =
          actual.keys - contract.send(:constraints).map { |hsh| hsh[:property] }

        unless extra_keys.empty?
          errors << {
            data: { keys: extra_keys },
            type: described_class::EXTRA_KEYS_TYPE
          }
        end
      end

      errors.map do |error|
        {
          data:    {},
          message: nil,
          path:    []
        }.merge(error)
      end
    end
    let(:negated_errors) do
      errors = []
      strict = !contract.allow_hash_like?

      if strict && actual.is_a?(Hash)
        errors << {
          data: { type: Hash },
          type: Stannum::Constraints::Type::NEGATED_TYPE
        }
      elsif !strict && actual.respond_to?(:[]) && actual.respond_to?(:key?)
        errors << { type: described_class::NEGATED_TYPE }
      else
        if fetch(:length).is_a?(Integer)
          errors << {
            path: %i[length],
            type: Stannum::Constraints::Base::NEGATED_TYPE
          }
        end

        if fetch(:name).is_a?(String) && !fetch(:name).empty?
          errors << { path: %i[name], type: 'spec.is_name' }
        end

        if fetch(:manufacturer).is_a?(Spec::Manufacturer)
          errors << {
            data: { type: Spec::Manufacturer },
            path: %i[manufacturer],
            type: Stannum::Constraints::Type::NEGATED_TYPE
          }
        end
      end

      errors.map do |error|
        {
          data:    {},
          message: nil,
          path:    []
        }.merge(error)
      end
    end

    example_class 'Spec::Manufacturer' do |klass|
      klass.const_set :Contract, Stannum::Constraints::Type.new(klass)
    end

    def fetch(property)
      property = property.to_s   if contract.key_type == :string
      property = property.intern if contract.key_type == :symbol

      contract.send(:access_property, actual, property)
    end

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should not match', {}, as: 'an empty hash'

    include_examples 'should not match when negated', {}, as: 'an empty hash'

    include_examples 'should not match',
      -> { Spec::HashLike.new },
      as: 'an empty hash-like object'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new },
      as: 'an empty hash-like object'

    include_examples 'should not match',
      -> { partial_strings },
      as: 'a hash with partially-matching string keys'

    include_examples 'should not match when negated',
      -> { partial_strings },
      as: 'a hash with partially-matching string keys'

    include_examples 'should not match',
      -> { partial_symbols },
      as: 'a hash with partially-matching symbol keys'

    include_examples 'should not match when negated',
      -> { partial_symbols },
      as: 'a hash with partially-matching symbol keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new partial_strings },
      as: 'a hash-like object with partially-matching string keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new partial_strings },
      as: 'a hash-like object with partially-matching string keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new partial_symbols },
      as: 'a hash-like object with partially-matching symbol keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new partial_symbols },
      as: 'a hash-like object with partially-matching symbol keys'

    include_examples 'should not match',
      -> { matching_strings },
      as: 'a hash with matching string keys'

    include_examples 'should not match when negated',
      -> { matching_strings },
      as: 'a hash with matching string keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new matching_strings },
      as: 'a hash-like object with matching string keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new matching_strings },
      as: 'a hash-like object with matching string keys'

    include_examples 'should match',
      -> { matching_symbols },
      as:         'a hash with matching symbol keys',
      reversible: true

    include_examples 'should match',
      -> { Spec::HashLike.new matching_symbols },
      as:         'a hash-like object with matching symbol keys',
      reversible: true

    include_examples 'should not match',
      -> { extra_strings },
      as: 'a hash with extra string keys'

    include_examples 'should not match when negated',
      -> { extra_strings },
      as: 'a hash with extra string keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new extra_strings },
      as: 'a hash-like object with extra string keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new extra_strings },
      as: 'a hash-like object with extra string keys'

    include_examples 'should match',
      -> { extra_symbols },
      as:         'a hash with extra symbol keys',
      reversible: true

    include_examples 'should match',
      -> { Spec::HashLike.new extra_symbols },
      as:         'a hash-like object with extra symbol keys',
      reversible: true

    wrap_context 'when initialized with allow_extra_keys: false' do
      include_examples 'should not match',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match when negated',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should match',
        -> { Spec::HashLike.new matching_symbols },
        as:         'a hash-like object with matching symbol keys',
        reversible: true

      include_examples 'should not match',
        -> { extra_symbols },
        as: 'a hash with extra symbol keys'

      include_examples 'should not match when negated',
        -> { extra_symbols },
        as: 'a hash with extra symbol keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new extra_symbols },
        as: 'a hash-like object with extra symbol keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new extra_symbols },
        as: 'a hash-like object with extra symbol keys'
    end

    wrap_context 'when initialized with allow_hash_like: false' do
      include_examples 'should not match',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match when negated',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_strings },
        as:         'a hash-like object with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'
    end

    wrap_context 'when initialized with key_type: :any' do
      let(:block) do
        lambda do
          property(1) { |value| value == 'Ichi' }
          property(2) { |value| value == 'Ni' }
          property(3) { |value| value == 'San' }
        end
      end
      let(:partial_keys) do
        { 2 => 'Ni' }
      end
      let(:matching_keys) do
        {
          1 => 'Ichi',
          2 => 'Ni',
          3 => 'San'
        }
      end
      let(:expected_errors) do
        errors = []

        errors << { path: [1] } unless fetch(1) == 'Ichi'
        errors << { path: [2] } unless fetch(2) == 'Ni'
        errors << { path: [3] } unless fetch(3) == 'San'

        errors.map do |error|
          {
            data:    {},
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Base::TYPE
          }.merge(error)
        end
      end
      let(:negated_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::NEGATED_TYPE
          }
        ]
      end

      include_examples 'should not match',
        -> { Spec::HashLike.new },
        as: 'an empty hash-like object'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new },
        as: 'an empty hash-like object'

      include_examples 'should not match',
        -> { partial_keys },
        as: 'a hash with partially-matching keys'

      include_examples 'should not match when negated',
        -> { partial_keys },
        as: 'a hash with partially-matching keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new partial_keys },
        as: 'a hash-like object with partially-matching keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new partial_keys },
        as: 'a hash-like object with partially-matching keys'

      include_examples 'should match',
        -> { matching_keys },
        as:         'a hash with matching keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_keys },
        as:         'a hash-like object with matching keys',
        reversible: true
    end

    wrap_context 'when initialized with key_type: :indifferent' do
      include_examples 'should match',
        -> { matching_strings },
        as:         'a hash with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_strings },
        as:         'a hash-like object with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_symbols },
        as:         'a hash-like object with matching symbol keys',
        reversible: true
    end

    wrap_context 'when initialized with key_type: :string' do
      let(:block) do
        constraint = name_constraint

        lambda do
          property('length')       { |actual| actual.is_a?(Integer) }
          property 'name',         constraint
          property 'manufacturer', Spec::Manufacturer::Contract
        end
      end

      include_examples 'should match',
        -> { matching_strings },
        as:         'a hash with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_strings },
        as:         'a hash-like object with matching string keys',
        reversible: true

      include_examples 'should not match',
        -> { matching_symbols },
        as: 'a hash with matching symbol keys'

      include_examples 'should not match when negated',
        -> { matching_symbols },
        as: 'a hash with matching symbol keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'
    end

    wrap_context 'when initialized with key_type: :symbol' do
      include_examples 'should not match',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match when negated',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_symbols },
        as:         'a hash-like object with matching symbol keys',
        reversible: true
    end
  end

  context 'with defined and included constraints' do
    subject(:contract) do
      described_class.new(**options, &block).tap do |contract|
        contract.include(included_contract)
      end
    end

    let(:string_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.is_a_string',
        type:         'spec.is_not_a_string'
      ) \
      do |actual|
        actual.is_a?(String)
      end
    end
    let(:included_contract) do
      constraint = string_constraint

      described_class.new do
        property :title, constraint
      end
    end
    let(:block) do
      constraint = string_constraint

      lambda do
        property :author, constraint
      end
    end
    let(:partial_strings) do
      {
        'author' => 'Ursula K. Le Guin'
      }
    end
    let(:partial_symbols) do
      {
        author: 'Ursula K. Le Guin'
      }
    end
    let(:matching_strings) do
      {
        'author' => 'Ursula K. Le Guin',
        'title'  => 'A Wizard of Earthsea'
      }
    end
    let(:matching_symbols) do
      {
        author: 'Ursula K. Le Guin',
        title:  'A Wizard of Earthsea'
      }
    end
    let(:extra_strings) do
      {
        'author'    => 'Ursula K. Le Guin',
        'title'     => 'A Wizard of Earthsea',
        'publisher' => 'Parnassus'
      }
    end
    let(:extra_symbols) do
      {
        author:    'Ursula K. Le Guin',
        title:     'A Wizard of Earthsea',
        publisher: 'Parnassus'
      }
    end
    let(:expected_errors) do
      errors = []

      if !contract.allow_hash_like? && !actual.is_a?(Hash)
        return [
          {
            data:    { type: Hash },
            message: nil,
            path:    [],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      elsif !(actual.respond_to?(:[]) && actual.respond_to?(:key?))
        errors << { type: described_class::TYPE }
      else
        unless fetch(:author).is_a?(String)
          errors << {
            path: %i[author],
            type: 'spec.is_not_a_string'
          }
        end

        unless fetch(:title).is_a?(String)
          errors << {
            path: %i[title],
            type: 'spec.is_not_a_string'
          }
        end
      end

      if actual.respond_to?(:keys) && !contract.allow_extra_keys?
        extra_keys =
          actual.keys - contract.send(:constraints).map { |hsh| hsh[:property] }

        unless extra_keys.empty?
          errors << {
            data: { keys: extra_keys },
            type: described_class::EXTRA_KEYS_TYPE
          }
        end
      end

      errors.map do |error|
        {
          data:    {},
          message: nil,
          path:    []
        }.merge(error)
      end
    end
    let(:negated_errors) do
      errors = []
      strict = !contract.allow_hash_like?

      if strict && actual.is_a?(Hash)
        errors << {
          data: { type: Hash },
          type: Stannum::Constraints::Type::NEGATED_TYPE
        }
      elsif !strict && actual.respond_to?(:[]) && actual.respond_to?(:key?)
        errors << { type: described_class::NEGATED_TYPE }
      else
        if fetch(:author).is_a?(String)
          errors << {
            path: %i[author],
            type: 'spec.is_a_string'
          }
        end

        if fetch(:title).is_a?(String)
          errors << {
            path: %i[title],
            type: 'spec.is_a_string'
          }
        end
      end

      errors.map do |error|
        {
          data:    {},
          message: nil,
          path:    []
        }.merge(error)
      end
    end

    def fetch(property)
      property = property.to_s   if contract.key_type == :string
      property = property.intern if contract.key_type == :symbol

      contract.send(:access_property, actual, property)
    end

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      Object.new.freeze,
      as:         'an object',
      reversible: true

    include_examples 'should not match', {}, as: 'an empty hash'

    include_examples 'should not match when negated', {}, as: 'an empty hash'

    include_examples 'should not match', {}, as: 'an empty hash'

    include_examples 'should not match when negated', {}, as: 'an empty hash'

    include_examples 'should not match',
      -> { Spec::HashLike.new },
      as: 'an empty hash-like object'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new },
      as: 'an empty hash-like object'

    include_examples 'should not match',
      -> { partial_strings },
      as: 'a hash with partially-matching string keys'

    include_examples 'should not match when negated',
      -> { partial_strings },
      as: 'a hash with partially-matching string keys'

    include_examples 'should not match',
      -> { partial_symbols },
      as: 'a hash with partially-matching symbol keys'

    include_examples 'should not match when negated',
      -> { partial_symbols },
      as: 'a hash with partially-matching symbol keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new partial_strings },
      as: 'a hash-like object with partially-matching string keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new partial_strings },
      as: 'a hash-like object with partially-matching string keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new partial_symbols },
      as: 'a hash-like object with partially-matching symbol keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new partial_symbols },
      as: 'a hash-like object with partially-matching symbol keys'

    include_examples 'should not match',
      -> { matching_strings },
      as: 'a hash with matching string keys'

    include_examples 'should not match when negated',
      -> { matching_strings },
      as: 'a hash with matching string keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new matching_strings },
      as: 'a hash-like object with matching string keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new matching_strings },
      as: 'a hash-like object with matching string keys'

    include_examples 'should match',
      -> { matching_symbols },
      as:         'a hash with matching symbol keys',
      reversible: true

    include_examples 'should match',
      -> { Spec::HashLike.new matching_symbols },
      as:         'a hash-like object with matching symbol keys',
      reversible: true

    include_examples 'should not match',
      -> { extra_strings },
      as: 'a hash with extra string keys'

    include_examples 'should not match when negated',
      -> { extra_strings },
      as: 'a hash with extra string keys'

    include_examples 'should not match',
      -> { Spec::HashLike.new extra_strings },
      as: 'a hash-like object with extra string keys'

    include_examples 'should not match when negated',
      -> { Spec::HashLike.new extra_strings },
      as: 'a hash-like object with extra string keys'

    include_examples 'should match',
      -> { extra_symbols },
      as:         'a hash with extra symbol keys',
      reversible: true

    include_examples 'should match',
      -> { Spec::HashLike.new extra_symbols },
      as:         'a hash-like object with extra symbol keys',
      reversible: true

    wrap_context 'when initialized with allow_extra_keys: false' do
      include_examples 'should not match',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match when negated',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should match',
        -> { Spec::HashLike.new matching_symbols },
        as:         'a hash-like object with matching symbol keys',
        reversible: true

      include_examples 'should not match',
        -> { extra_symbols },
        as: 'a hash with extra symbol keys'

      include_examples 'should not match when negated',
        -> { extra_symbols },
        as: 'a hash with extra symbol keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new extra_symbols },
        as: 'a hash-like object with extra symbol keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new extra_symbols },
        as: 'a hash-like object with extra symbol keys'
    end

    wrap_context 'when initialized with allow_hash_like: false' do
      include_examples 'should not match',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match when negated',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_strings },
        as:         'a hash-like object with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'
    end

    wrap_context 'when initialized with key_type: :indifferent' do
      include_examples 'should match',
        -> { matching_strings },
        as:         'a hash with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_strings },
        as:         'a hash-like object with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_symbols },
        as:         'a hash-like object with matching symbol keys',
        reversible: true
    end

    wrap_context 'when initialized with key_type: :string' do
      let(:included_contract) do
        constraint = string_constraint

        described_class.new do
          property 'title', constraint
        end
      end
      let(:block) do
        constraint = string_constraint

        lambda do
          property 'author', constraint
        end
      end

      include_examples 'should match',
        -> { matching_strings },
        as:         'a hash with matching string keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_strings },
        as:         'a hash-like object with matching string keys',
        reversible: true

      include_examples 'should not match',
        -> { matching_symbols },
        as: 'a hash with matching symbol keys'

      include_examples 'should not match when negated',
        -> { matching_symbols },
        as: 'a hash with matching symbol keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_symbols },
        as: 'a hash-like object with matching symbol keys'
    end

    wrap_context 'when initialized with key_type: :symbol' do
      include_examples 'should not match',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match when negated',
        -> { matching_strings },
        as: 'a hash with matching string keys'

      include_examples 'should not match',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should not match when negated',
        -> { Spec::HashLike.new matching_strings },
        as: 'a hash-like object with matching string keys'

      include_examples 'should match',
        -> { matching_symbols },
        as:         'a hash with matching symbol keys',
        reversible: true

      include_examples 'should match',
        -> { Spec::HashLike.new matching_symbols },
        as:         'a hash-like object with matching symbol keys',
        reversible: true
    end
  end
end
