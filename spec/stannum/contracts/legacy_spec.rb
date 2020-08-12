# frozen_string_literal: true

require 'stannum/constraints/anything'
require 'stannum/constraints/nothing'
require 'stannum/constraints/type'
require 'stannum/contracts/legacy'
require 'stannum/constraint'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Contracts::Legacy do
  include Spec::Support::Examples::ConstraintExamples

  subject(:contract) { described_class.new(**options) }

  let(:options) { {} }

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#access_nested_property' do
    let(:factory)      { Spec::Factory.new('123 Example Street') }
    let(:manufacturer) { Spec::Manufacturer.new('ACME Corporation', factory) }
    let(:widget) do
      Spec::Widget.new('Self-sealing Stem Bolt', manufacturer)
    end

    example_class 'Spec::Factory', Struct.new(:address)

    example_class 'Spec::Manufacturer', Struct.new(:name, :factory)

    example_class 'Spec::Widget', Struct.new(:name, :manufacturer)

    it 'should define the private method' do
      expect(contract)
        .to respond_to(:access_nested_property, true)
        .with(2).arguments
    end

    describe 'with nil' do
      it 'should return the object' do
        expect(contract.send :access_nested_property, widget, nil).to be widget
      end
    end

    describe 'with a property name' do
      it 'should return the property value' do
        expect(contract.send :access_nested_property, widget, 'name')
          .to be == widget.name
      end
    end

    describe 'with an array of property names' do
      let(:property) { %w[manufacturer factory address] }

      it 'should return the nested property value' do
        expect(contract.send :access_nested_property, widget, property)
          .to be == factory.address
      end
    end

    context 'when #access_property is overriden' do
      let(:hash) do
        {
          name:    'ACME Corporation',
          widgets: [
            { name: 'Self-sealing Stem Bolt' }
          ]
        }
      end

      before(:example) do
        def contract.access_property(object, property)
          object[property]
        end
      end

      describe 'with nil' do
        it 'should return the object' do
          expect(contract.send :access_nested_property, hash, nil).to be hash
        end
      end

      describe 'with a property name' do
        it 'should return the property value' do
          expect(contract.send :access_nested_property, hash, :name)
            .to be == hash[:name]
        end
      end

      describe 'with an array of property names' do
        it 'should return the nested property value' do
          expect(
            contract.send :access_nested_property, hash, [:widgets, 0, :name]
          )
            .to be == hash.dig(:widgets, 0, :name)
        end
      end
    end
  end

  describe '#access_property' do
    let(:value)    { 'bar' }
    let(:object)   { instance_double(Object, send: value, respond_to?: false) }
    let(:property) { :foo }

    before(:example) do
      allow(object)
        .to receive(:respond_to?)
        .with(property, true)
        .and_return(true)
    end

    it 'should define the private method' do
      expect(contract).to respond_to(:access_property, true).with(2).arguments
    end

    it 'should call send on the object with the property' do
      contract.send :access_property, object, property

      expect(object).to have_received(:send).with(property)
    end

    it { expect(contract.send :access_property, object, property).to be value }

    describe 'with an object and a property' do
      let(:object)   { %w[ichi ni san] }
      let(:property) { :size }

      it { expect(contract.send :access_property, object, property).to be 3 }
    end

    context 'when the object does not respond to the property method' do
      let(:object)   { %w[ichi ni san] }
      let(:property) { :size }

      before(:example) do
        allow(object)
          .to receive(:respond_to?)
          .with(property, true)
          .and_return(false)
      end

      it { expect(contract.send :access_property, object, property).to be nil }
    end
  end

  describe '#add_constraint' do
    let(:error_message) { 'must be an instance of Stannum::Constraints::Base' }

    it 'should define the method' do
      expect(contract)
        .to respond_to(:add_constraint)
        .with(1).argument
        .and_keywords(:property)
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { contract.add_constraint nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { contract.add_constraint Object.new }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a constraint' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:expected) do
        {
          constraint: constraint,
          property:   nil
        }
      end

      it { expect(contract.add_constraint(constraint)).to be contract }

      it 'should add the constraint' do
        expect { contract.add_constraint(constraint) }
          .to change { contract.send :constraints }
          .to include expected
      end
    end

    describe 'with a constraint and property: nil' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:expected) do
        {
          constraint: constraint,
          property:   nil
        }
      end

      it 'should return the contract' do
        expect(contract.add_constraint(constraint, property: nil))
          .to be contract
      end

      it 'should add the constraint' do
        expect { contract.add_constraint(constraint, property: nil) }
          .to change { contract.send :constraints }
          .to include expected
      end
    end

    describe 'with a constraint and property: array' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:property)   { [:foo, 0, :bar] }
      let(:expected) do
        {
          constraint: constraint,
          property:   property
        }
      end

      it 'should return the contract' do
        expect(contract.add_constraint(constraint, property: property))
          .to be contract
      end

      it 'should add the constraint' do
        expect { contract.add_constraint(constraint, property: property) }
          .to change { contract.send :constraints }
          .to include expected
      end
    end

    describe 'with a constraint and property: value' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:property)   { :foo }
      let(:expected) do
        {
          constraint: constraint,
          property:   property
        }
      end

      it 'should return the contract' do
        expect(contract.add_constraint(constraint, property: property))
          .to be contract
      end

      it 'should add the constraint' do
        expect { contract.add_constraint(constraint, property: property) }
          .to change { contract.send :constraints }
          .to include expected
      end
    end

    context 'when the contract has multiple constraints' do
      let(:constraints) do
        Array.new(3) { Stannum::Constraints::Anything.new }
      end

      before(:example) do
        constraints.each { |constraint| contract.add_constraint(constraint) }
      end

      describe 'with a constraint' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:expected) do
          {
            constraint: constraint,
            property:   nil
          }
        end

        it { expect(contract.add_constraint(constraint)).to be contract }

        it 'should add the constraint' do
          expect { contract.add_constraint(constraint) }
            .to change { contract.send :constraints }
            .to include expected
        end
      end

      describe 'with a constraint and property: nil' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:expected) do
          {
            constraint: constraint,
            property:   nil
          }
        end

        it 'should return the contract' do
          expect(contract.add_constraint(constraint, property: nil))
            .to be contract
        end

        it 'should add the constraint' do
          expect { contract.add_constraint(constraint, property: nil) }
            .to change { contract.send :constraints }
            .to include expected
        end
      end

      describe 'with a constraint and property: array' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:property)   { [:foo, 0, :bar] }
        let(:expected) do
          {
            constraint: constraint,
            property:   property
          }
        end

        it 'should return the contract' do
          expect(contract.add_constraint(constraint, property: property))
            .to be contract
        end

        it 'should add the constraint' do
          expect { contract.add_constraint(constraint, property: property) }
            .to change { contract.send :constraints }
            .to include expected
        end
      end

      describe 'with a constraint and property: value' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:property)   { :foo }
        let(:expected) do
          {
            constraint: constraint,
            property:   property
          }
        end

        it 'should return the contract' do
          expect(contract.add_constraint(constraint, property: property))
            .to be contract
        end

        it 'should add the constraint' do
          expect { contract.add_constraint(constraint, property: property) }
            .to change { contract.send :constraints }
            .to include expected
        end
      end
    end
  end

  describe '#constraints' do
    include_examples 'should have private reader', :constraints, []
  end

  describe '#include' do
    let(:error_message) { 'must be an instance of Stannum::Contract' }

    it { expect(contract).to respond_to(:include).with(1).argument }

    describe 'with nil' do
      it 'should raise an error' do
        expect { contract.include nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      it 'should raise an error' do
        expect { contract.include Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a constraint' do
      it 'should raise an error' do
        expect { contract.include Stannum::Constraints::Base.new }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an empty contract' do
      let(:other) { described_class.new }

      it 'should return the contract' do
        expect(contract.include other).to be contract
      end

      it 'should not change the constraints' do
        expect { contract.include other }
          .not_to(change { contract.send(:constraints) })
      end

      context 'when a constraint is added to the other contract' do
        let(:constraint) { Stannum::Constraints::Base.new }

        it 'should add the constraint to the contract' do
          contract.include other

          expect { other.add_constraint(constraint) }
            .to change { contract.send(:constraints) }
            .to include(constraint: constraint, property: nil)
        end
      end
    end

    describe 'with a contract with constraints' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:other)      { described_class.new }

      before(:example) { other.add_constraint(constraint) }

      it 'should add the constraints to the contract' do
        expect { contract.include other }
          .to change { contract.send(:constraints) }
          .to include(constraint: constraint, property: nil)
      end
    end

    context 'when the contract has constraints' do
      let(:existing_constraint) { Stannum::Constraints::Base.new }

      before(:example) { contract.add_constraint(existing_constraint) }

      describe 'with a contract with constraints' do
        let(:constraint) { Stannum::Constraints::Base.new }
        let(:other)      { described_class.new }

        before(:example) { other.add_constraint(constraint) }

        it 'should add the constraints to the contract' do
          expect { contract.include other }
            .to change { contract.send(:constraints) }
            .to include(constraint: constraint, property: nil)
        end
      end
    end
  end

  describe '#included' do
    include_examples 'should have private reader', :included, []

    context 'when the contract includes other contracts' do
      let(:other_contracts) do
        [
          described_class.new,
          described_class.new,
          described_class.new
        ]
      end

      before(:example) do
        other_contracts.each do |other_contract|
          contract.include(other_contract)
        end
      end

      it { expect(contract.send :included).to be == other_contracts }
    end

    context 'when the contract recursively includes other contracts' do
      let(:other_contracts) do
        [
          described_class.new,
          described_class.new,
          described_class.new
        ]
      end

      before(:example) do
        other_contracts.reduce(contract) do |current, other_contract|
          current.include(other_contract)
        end
      end

      it { expect(contract.send :included).to be == other_contracts }
    end
  end

  describe '#options' do
    include_examples 'should have reader', :options, -> { be == {} }

    context 'when the contract defines options' do
      let(:options) do
        {
          language:  'Ada',
          log_level: 'panic',
          strict:    true
        }
      end

      it { expect(contract.options).to be == options }
    end
  end

  context 'when the contract has no constraints' do
    include_examples 'should match', nil

    include_examples 'should match when negated', nil

    include_examples 'should match', true

    include_examples 'should match when negated', true

    include_examples 'should match', false

    include_examples 'should match when negated', false

    include_examples 'should match', 0, as: 'an integer'

    include_examples 'should match when negated', 0, as: 'an integer'

    include_examples 'should match', Object.new.freeze

    include_examples 'should match when negated', Object.new.freeze

    include_examples 'should match', '', as: 'an empty string'

    include_examples 'should match when negated', '', as: 'an empty string'

    include_examples 'should match', 'a string'

    include_examples 'should match when negated', 'a string'

    include_examples 'should match', :a_symbol

    include_examples 'should match when negated', :a_symbol

    include_examples 'should match', [], as: 'an empty array'

    include_examples 'should match when negated', [], as: 'an empty array'

    include_examples 'should match', %w[a b c], as: 'an array'

    include_examples 'should match when negated', %w[a b c], as: 'an array'

    include_examples 'should match', {}, as: 'an empty hash'

    include_examples 'should match when negated', {}, as: 'an empty hash'

    include_examples 'should match', { a: 'a' }, as: 'a hash'

    include_examples 'should match when negated', { a: 'a' }, as: 'a hash'
  end

  context 'when the contract has a constraint that does not match any objects' \
  do
    let(:constraint) { Stannum::Constraints::Nothing.new }
    let(:expected_errors) do
      Stannum::Errors.new.add(constraint.type)
    end

    before(:example) { contract.add_constraint(constraint) }

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match', true, reversible: true

    include_examples 'should not match', false, reversible: true

    include_examples 'should not match', 0, as: 'an integer', reversible: true

    include_examples 'should not match', Object.new.freeze, reversible: true

    include_examples 'should not match',
      '',
      as:         'an empty string',
      reversible: true

    include_examples 'should not match', 'a string', reversible: true

    include_examples 'should not match', :a_symbol, reversible: true

    include_examples 'should not match',
      [],
      as:         'an empty array',
      reversible: true

    include_examples 'should not match',
      %w[a b c],
      as:         'an array',
      reversible: true

    include_examples 'should not match',
      {},
      as:         'an empty hash',
      reversible: true

    include_examples 'should not match',
      { a: 'a' },
      as:         'a hash',
      reversible: true
  end

  context 'when the contract has a constraint that matches all objects' \
  do
    let(:constraint) { Stannum::Constraints::Anything.new }
    let(:negated_errors) do
      Stannum::Errors.new.add(constraint.negated_type)
    end

    before(:example) { contract.add_constraint(constraint) }

    include_examples 'should match', nil, reversible: true

    include_examples 'should match', true, reversible: true

    include_examples 'should match', false, reversible: true

    include_examples 'should match', 0, as: 'an integer', reversible: true

    include_examples 'should match', Object.new.freeze, reversible: true

    include_examples 'should match',
      '',
      as:         'an empty string',
      reversible: true

    include_examples 'should match', 'a string', reversible: true

    include_examples 'should match', :a_symbol, reversible: true

    include_examples 'should match',
      [],
      as:         'an empty array',
      reversible: true

    include_examples 'should match',
      %w[a b c],
      as:         'an array',
      reversible: true

    include_examples 'should match',
      {},
      as:         'an empty hash',
      reversible: true

    include_examples 'should match',
      { a: 'a' },
      as:         'a hash',
      reversible: true
  end

  context 'when the contract has multiple constraints' do
    let(:anything_constraints) do
      Array.new(3) { Stannum::Constraints::Anything.new }
    end
    let(:nothing_constraints) do
      Array.new(3) { Stannum::Constraints::Nothing.new }
    end
    let(:expected_errors) do
      nothing_constraints.reduce(Stannum::Errors.new) do |errors, constraint|
        errors.add(constraint.type)
      end
    end
    let(:negated_errors) do
      anything_constraints.reduce(Stannum::Errors.new) do |errors, constraint|
        errors.add(constraint.negated_type)
      end
    end

    before(:example) do
      0.upto(2) do |index|
        contract.add_constraint(anything_constraints[index])
        contract.add_constraint(nothing_constraints[index])
      end
    end

    include_examples 'should not match', nil

    include_examples 'should not match when negated', nil

    include_examples 'should not match', true

    include_examples 'should not match when negated', true

    include_examples 'should not match', false

    include_examples 'should not match when negated', false

    include_examples 'should not match', 0, as: 'an integer'

    include_examples 'should not match when negated', 0, as: 'an integer'

    include_examples 'should not match', Object.new.freeze

    include_examples 'should not match when negated', Object.new.freeze

    include_examples 'should not match', '', as: 'an empty string'

    include_examples 'should not match when negated', '', as: 'an empty string'

    include_examples 'should not match', 'a string'

    include_examples 'should not match when negated', 'a string'

    include_examples 'should not match', :a_symbol

    include_examples 'should not match when negated', :a_symbol

    include_examples 'should not match', [], as: 'an empty array'

    include_examples 'should not match when negated', [], as: 'an empty array'

    include_examples 'should not match', %w[a b c], as: 'an array'

    include_examples 'should not match when negated', %w[a b c], as: 'an array'

    include_examples 'should not match', {}, as: 'an empty hash'

    include_examples 'should not match when negated', {}, as: 'an empty hash'

    include_examples 'should not match', { a: 'a' }, as: 'a hash'

    include_examples 'should not match when negated', { a: 'a' }, as: 'a hash'
  end

  context 'when the contract has usable constraints' do
    let(:numeric_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.not_numeric',
        type:         'spec.numeric'
      ) \
      do |actual|
        actual.is_a?(Numeric)
      end
    end
    let(:integer_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.not_integer',
        type:         'spec.integer'
      ) \
      do |actual|
        actual.is_a?(Integer)
      end
    end
    let(:range_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.in_range',
        type:         'spec.out_of_range'
      ) \
      do |actual|
        (0...10).include?(actual)
      end
    end
    let(:expected_errors) do
      errors = []

      errors << { type: 'spec.numeric' }      unless actual.is_a?(Numeric)
      errors << { type: 'spec.integer' }      unless actual.is_a?(Integer)
      errors << { type: 'spec.out_of_range' } unless (0...10).include?(actual)

      errors.map { |err| err.merge(data: {}, message: nil, path: []) }
    end
    let(:negated_errors) do
      errors = []

      errors << { type: 'spec.not_numeric' } if actual.is_a?(Numeric)
      errors << { type: 'spec.not_integer' } if actual.is_a?(Integer)
      errors << { type: 'spec.in_range' }    if (0...10).include?(actual)

      errors.map { |err| err.merge(data: {}, message: nil, path: []) }
    end

    before(:example) do
      contract
        .add_constraint(numeric_constraint)
        .add_constraint(integer_constraint)
        .add_constraint(range_constraint)
    end

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match', 3.14, as: 'a float'

    include_examples 'should not match when negated', 3.14, as: 'a float'

    include_examples 'should not match', -1, as: 'an integer out of range'

    include_examples 'should not match when negated',
      -1,
      as: 'an integer out of range'

    include_examples 'should match', 1, as: 'an integer in the range'
  end

  context 'when the contract has property constraints' do
    let(:widget_constraint) do
      Stannum::Constraints::Type.new(Spec::Widget)
    end
    let(:name_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.right_name',
        type:         'spec.wrong_name'
      ) \
      do |actual|
        actual == 'Self-sealing Stem Bolt'
      end
    end
    let(:address_constraint) do
      Stannum::Constraint.new(
        negated_type: 'spec.right_address',
        type:         'spec.wrong_address'
      ) \
      do |actual|
        actual == '123 Example Street'
      end
    end
    let(:expected_errors) do
      errors = []

      unless actual.is_a?(Spec::Widget)
        errors << {
          data: { type: Spec::Widget },
          type: 'stannum.constraints.is_not_type'
        }
      end

      unless actual&.name == 'Self-sealing Stem Bolt'
        errors << { type: 'spec.wrong_name', path: %i[name] }
      end

      unless actual&.manufacturer&.factory&.address == '123 Example Street'
        errors << {
          type: 'spec.wrong_address',
          path: %i[manufacturer factory address]
        }
      end

      errors.map { |err| { data: {}, message: nil, path: [] }.merge(err) }
    end
    let(:negated_errors) do
      errors = []

      if actual.is_a?(Spec::Widget)
        errors << {
          data: { type: Spec::Widget },
          type: 'stannum.constraints.is_type'
        }
      end

      if actual&.name == 'Self-sealing Stem Bolt'
        errors << { type: 'spec.right_name', path: %i[name] }
      end

      if actual&.manufacturer&.factory&.address == '123 Example Street'
        errors << {
          type: 'spec.right_address',
          path: %i[manufacturer factory address]
        }
      end

      errors.map { |err| { data: {}, message: nil, path: [] }.merge(err) }
    end

    let(:factory)      { Spec::Factory.new('123 Example Street') }
    let(:manufacturer) { Spec::Manufacturer.new('ACME Corporation', factory) }
    let(:widget) do
      Spec::Widget.new('Self-sealing Stem Bolt', manufacturer)
    end

    example_class 'Spec::Factory', Struct.new(:address)

    example_class 'Spec::Manufacturer', Struct.new(:name, :factory)

    example_class 'Spec::Widget', Struct.new(:name, :manufacturer)

    before(:example) do
      contract
        .add_constraint(widget_constraint)
        .add_constraint(name_constraint, property: :name)
        .add_constraint(
          address_constraint,
          property: %i[manufacturer factory address]
        )
    end

    include_examples 'should not match', nil, reversible: true

    include_examples 'should not match',
      -> { Spec::Widget.new },
      as: 'a widget with the wrong name'

    include_examples 'should not match when negated',
      -> { Spec::Widget.new },
      as: 'a widget with the wrong name'

    include_examples 'should not match',
      -> { Spec::Widget.new('Self-sealing Stem Bolt') },
      as: 'a widget with the wrong factory address'

    include_examples 'should not match when negated',
      -> { Spec::Widget.new('Self-sealing Stem Bolt') },
      as: 'a widget with the wrong factory address'

    include_examples 'should match',
      -> { widget },
      as:         'a widget with the correct name and manufacturer',
      reversible: true
  end

  context 'when the contract has included contracts' do
    let(:own_constraint) do
      messages = {
        negated_type: 'spec.lte',
        type:         'spec.gt'
      }

      Stannum::Constraint.new(**messages) { |int| int > 5 }
    end
    let(:other_constraint) do
      messages = {
        negated_type: 'spec.gte',
        type:         'spec.lt'
      }

      Stannum::Constraint.new(**messages) { |int| int < 10 }
    end
    let(:other_contract) { described_class.new }
    let(:expected_errors) do
      if actual <= 5
        [{ data: {}, message: nil, path: [], type: 'spec.gt' }]
      elsif actual >= 10
        [{ data: {}, message: nil, path: [], type: 'spec.lt' }]
      end
    end
    let(:negated_errors) do
      errors = []

      if actual > 5
        errors << { data: {}, message: nil, path: [], type: 'spec.lte' }
      end

      if actual < 10
        errors << { data: {}, message: nil, path: [], type: 'spec.gte' }
      end

      errors
    end

    before(:example) do
      contract.add_constraint(own_constraint)

      other_contract.add_constraint(other_constraint)

      contract.include(other_contract)
    end

    include_examples 'should not match', 0

    include_examples 'should not match when negated', 0

    include_examples 'should match', 6, reversible: true

    include_examples 'should match', 9, reversible: true

    include_examples 'should not match', 10

    include_examples 'should not match when negated', 10
  end

  context 'when the contract has recursively included contracts' do
    let(:other_constraint) do
      messages = {
        negated_type: 'spec.gte',
        type:         'spec.lt'
      }

      Stannum::Constraint.new(**messages) { |int| int < 10 }
    end
    let(:nested_constraint) do
      messages = {
        negated_type: 'spec.odd',
        type:         'spec.even'
      }

      Stannum::Constraint.new(**messages, &:odd?)
    end
    let(:other_contract)  { described_class.new }
    let(:nested_contract) { described_class.new }
    let(:expected_errors) do
      errors = []

      if actual.even?
        errors << { data: {}, message: nil, path: [], type: 'spec.even' }
      end

      if actual >= 10
        errors << { data: {}, message: nil, path: [], type: 'spec.lt' }
      end

      errors
    end
    let(:negated_errors) do
      errors = []

      if actual.odd?
        errors << { data: {}, message: nil, path: [], type: 'spec.odd' }
      end

      if actual < 10
        errors << { data: {}, message: nil, path: [], type: 'spec.gte' }
      end

      errors
    end

    before(:example) do
      other_contract.add_constraint(other_constraint)

      contract.include(other_contract)

      nested_contract.add_constraint(nested_constraint)

      other_contract.include(nested_contract)
    end

    include_examples 'should not match', 0

    include_examples 'should not match when negated', 0

    include_examples 'should match', 1, reversible: true

    include_examples 'should not match', 6

    include_examples 'should not match when negated', 6

    include_examples 'should match', 7, reversible: true

    include_examples 'should not match', 8

    include_examples 'should not match when negated', 8

    include_examples 'should match', 9, reversible: true

    include_examples 'should not match', 10, reversible: true
  end
end
