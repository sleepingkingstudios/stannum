# frozen_string_literal: true

require 'stannum/constraints/types/time_type'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Types::TimeType do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_type: Time, required: true } }

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
    include_examples 'should have reader', :expected_type, Time
  end

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Time },
        type: constraint.type
      }
    end
    let(:matching) { Time.new }
    let(:expected_messages) do
      message =
        if constraint.required?
          'is not a Time'
        else
          'is not a Time or nil'
        end

      expected_errors.merge(message: message)
    end

    include_examples 'should match the type constraint'
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_errors) do
      {
        data: { required: constraint.required?, type: Time },
        type: constraint.negated_type
      }
    end
    let(:matching) { Time.new }
    let(:expected_messages) do
      message =
        if constraint.required?
          'is a Time'
        else
          'is a Time or nil'
        end

      expected_errors.merge(message: message)
    end

    include_examples 'should match the negated type constraint'
  end
end
