# frozen_string_literal: true

require 'stannum/constraints/types/symbol_type'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::SymbolType do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_type: Symbol, required: true } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      Stannum::Constraints::Type::NEGATED_TYPE
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      Stannum::Constraints::Type::TYPE
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_any_keywords
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#expected_type' do
    include_examples 'should have reader', :expected_type, Symbol
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Symbol },
        type: constraint.type
      }
    end
    let(:matching) { :symbol }
    let(:expected_messages) do
      message =
        if constraint.required?
          'is not a Symbol'
        else
          'is not a Symbol or nil'
        end

      expected_errors.merge(message: message)
    end

    include_examples 'should match the type constraint'
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Symbol },
        type: constraint.negated_type
      }
    end
    let(:matching) { :symbol }
    let(:expected_messages) do
      message =
        if constraint.required?
          'is a Symbol'
        else
          'is a Symbol or nil'
        end

      expected_errors.merge(message: message)
    end

    include_examples 'should match the negated type constraint'
  end
end
