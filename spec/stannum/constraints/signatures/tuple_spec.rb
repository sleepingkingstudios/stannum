# frozen_string_literal: true

require 'stannum/constraints/signatures/tuple'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Signatures::Tuple do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }
  let(:expected_options)    { { expected_methods: %i[[] each each_index] } }

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      Stannum::Constraints::Signature::NEGATED_TYPE
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      Stannum::Constraints::Signature::TYPE
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#match' do
    let(:match_method) { :match }
    let(:expected_messages) do
      expected_errors.merge(message: 'does not respond to the methods')
    end

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        {
          type: described_class::TYPE,
          data: {
            missing: %i[[] each each_index],
            methods: %i[[] each each_index]
          }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to none of the methods' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        {
          type: described_class::TYPE,
          data: {
            missing: %i[[] each each_index],
            methods: %i[[] each each_index]
          }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to some of the methods' do
      let(:actual) { Spec::Uncountable.new }
      let(:expected_errors) do
        {
          type: described_class::TYPE,
          data: {
            missing: %i[each each_index],
            methods: %i[[] each each_index]
          }
        }
      end

      example_class 'Spec::Uncountable' do |klass|
        klass.define_method(:[]) { nil } # rubocop:disable Naming/MethodName
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to all of the methods' do
      let(:actual) { [] }

      include_examples 'should match the constraint'
    end
  end

  describe '#negated_match' do
    let(:match_method) { :negated_match }
    let(:expected_messages) do
      expected_errors.merge(message: 'responds to the methods')
    end

    describe 'with nil' do
      let(:actual) { nil }

      include_examples 'should match the constraint'
    end

    describe 'with an object that responds to none of the methods' do
      let(:actual) { Object.new.freeze }

      include_examples 'should match the constraint'
    end

    describe 'with an object that responds to some of the methods' do
      let(:actual) { Spec::Uncountable.new }
      let(:expected_errors) do
        {
          type: described_class::NEGATED_TYPE,
          data: {
            missing: %i[each each_index],
            methods: %i[[] each each_index]
          }
        }
      end

      example_class 'Spec::Uncountable' do |klass|
        klass.define_method(:[]) { nil } # rubocop:disable Naming/MethodName
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object that responds to all of the methods' do
      let(:actual) { [] }
      let(:expected_errors) do
        {
          type: described_class::NEGATED_TYPE,
          data: {
            missing: %i[],
            methods: %i[[] each each_index]
          }
        }
      end

      include_examples 'should not match the constraint'
    end
  end
end
