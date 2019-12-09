# frozen_string_literal: true

require 'stannum/constraints/anything'
require 'stannum/constraints/nothing'
require 'stannum/contract'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Contract do
  include Spec::Support::Examples::ConstraintExamples

  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#add_constraint' do
    let(:error_message) { 'must be an instance of Stannum::Constraints::Base' }

    it { expect(contract).to respond_to(:add_constraint).with(1).argument }

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
    end
  end

  include_examples 'should implement the Constraint interface'

  describe '#constraints' do
    include_examples 'should have private reader', :constraints, []
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
end
