# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/contracts/uuid_contract'

# @note Integration spec for Stannum::Contracts::Base.
RSpec.describe Spec::UuidContract do
  include Stannum::RSpec::Matchers

  subject(:contract) { described_class.new }

  let(:strategy) do
    default_strategy = Stannum::Messages::DefaultStrategy.new

    lambda do |error_type, **options|
      case error_type
      when Spec::FormatConstraint::NEGATED_TYPE
        'matches the format'
      when Spec::FormatConstraint::TYPE
        'does not match the format'
      when Spec::LengthConstraint::NEGATED_TYPE
        'is the right length'
      when Spec::LengthConstraint::TYPE
        'is the wrong length'
      else
        default_strategy.call(error_type, **options)
      end
    end
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#does_not_match?' do
    let(:status) { contract.does_not_match?(actual) }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(status).to be true }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) { '0-1-2-3' }

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }

      it { expect(status).to be false }
    end
  end

  describe '#errors_for' do
    let(:errors) do
      contract.errors_for(actual).with_messages(strategy:)
    end

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    [],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }
    end

    describe 'with an object that matches the sanity constraints' do
      let(:actual) { '' }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: 'is the wrong length',
            path:    [],
            type:    Spec::LengthConstraint::TYPE
          },
          {
            data:    {},
            message: 'does not match the format',
            path:    [],
            type:    Spec::FormatConstraint::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) { '0-1-2-3' }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: 'is the wrong length',
            path:    [],
            type:    Spec::LengthConstraint::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }

      it { expect(errors).to be == [] }
    end
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) do
      Array(contract.match(actual))[1].with_messages(strategy:)
    end

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is not a String',
            path:    [],
            type:    Stannum::Constraints::Type::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with an object that matches the sanity constraints' do
      let(:actual) { '' }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: 'is the wrong length',
            path:    [],
            type:    Spec::LengthConstraint::TYPE
          },
          {
            data:    {},
            message: 'does not match the format',
            path:    [],
            type:    Spec::FormatConstraint::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) { '0-1-2-3' }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: 'is the wrong length',
            path:    [],
            type:    Spec::LengthConstraint::TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end
  end

  describe '#matches?' do
    let(:status) { contract.matches?(actual) }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(status).to be false }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) { '0-1-2-3' }

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }

      it { expect(status).to be true }
    end
  end

  describe '#negated_errors_for' do
    let(:errors) do
      contract.negated_errors_for(actual).with_messages(strategy:)
    end

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(errors).to be == [] }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) { '0-1-2-3' }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'matches the format',
            path:    [],
            type:    Spec::FormatConstraint::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'is the right length',
            path:    [],
            type:    Spec::LengthConstraint::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'matches the format',
            path:    [],
            type:    Spec::FormatConstraint::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(contract.negated_match(actual))[0] }
    let(:errors) do
      Array(contract.negated_match(actual))[1].with_messages(strategy:)
    end

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) { '0-1-2-3' }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'matches the format',
            path:    [],
            type:    Spec::FormatConstraint::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) { '01234567-89ab-cdef-0123-456789abcdef' }
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: 'is a String',
            path:    [],
            type:    Stannum::Constraints::Type::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'is the right length',
            path:    [],
            type:    Spec::LengthConstraint::NEGATED_TYPE
          },
          {
            data:    {},
            message: 'matches the format',
            path:    [],
            type:    Spec::FormatConstraint::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to match_errors(expected_errors) }

      it { expect(status).to be false }
    end
  end
end
