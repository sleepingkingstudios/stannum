# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/constraints/lights_constraint'

# @note Integration spec for Stannum::Constraints::Delegator.
RSpec.describe Spec::LightsConstraint do
  include Stannum::RSpec::Matchers

  subject(:constraint) { described_class.new(count) }

  let(:count) { 4 }

  describe '::NEGATED_TYPE' do
    include_examples 'should define constant',
      :NEGATED_TYPE,
      'stannum.constraints.valid'
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'stannum.constraints.invalid'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#does_not_match?' do
    describe 'with nil' do
      it { expect(constraint.does_not_match? nil).to be true }
    end

    describe 'with a non-matching value' do
      it { expect(constraint.does_not_match? 5).to be true }
    end

    describe 'with a matching value' do
      it { expect(constraint.does_not_match? 4).to be false }
    end
  end

  describe '#errors_for' do
    let(:errors) { constraint.errors_for(actual) }
    let(:expected_errors) do
      [
        {
          data:    {},
          message: nil,
          path:    [],
          type:    constraint.type
        }
      ]
    end

    describe 'with nil' do
      let(:actual) { nil }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a non-matching value' do
      let(:actual) { 5 }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a matching value' do
      let(:actual) { 4 }

      it { expect(errors).to be == expected_errors }
    end
  end

  describe '#match' do
    let(:status) { Array(constraint.match(actual))[0] }
    let(:errors) { Array(constraint.match(actual))[1] }
    let(:expected_errors) do
      [
        {
          data:    {},
          message: nil,
          path:    [],
          type:    constraint.type
        }
      ]
    end

    describe 'with nil' do
      let(:actual) { nil }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a non-matching value' do
      let(:actual) { 5 }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a matching value' do
      let(:actual) { 4 }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end
  end

  describe '#matches?' do
    describe 'with nil' do
      it { expect(constraint.matches? nil).to be false }
    end

    describe 'with a non-matching value' do
      it { expect(constraint.matches? 5).to be false }
    end

    describe 'with a matching value' do
      it { expect(constraint.matches? 4).to be true }
    end
  end

  describe '#negated_errors_for' do
    let(:errors) { constraint.negated_errors_for(actual) }
    let(:expected_errors) do
      [
        {
          data:    {},
          message: nil,
          path:    [],
          type:    constraint.negated_type
        }
      ]
    end

    describe 'with nil' do
      let(:actual) { nil }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a non-matching value' do
      let(:actual) { 5 }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a matching value' do
      let(:actual) { 4 }

      it { expect(errors).to be == expected_errors }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(constraint.negated_match(actual))[0] }
    let(:errors) { Array(constraint.negated_match(actual))[1] }
    let(:expected_errors) do
      [
        {
          data:    {},
          message: nil,
          path:    [],
          type:    constraint.negated_type
        }
      ]
    end

    describe 'with nil' do
      let(:actual) { nil }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end

    describe 'with a non-matching value' do
      let(:actual) { 5 }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end

    describe 'with a matching value' do
      let(:actual) { 4 }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end

  describe '#negated_type' do
    include_examples 'should have reader',
      :negated_type,
      'stannum.constraints.is_value'
  end

  describe '#receiver' do
    it { expect(constraint.receiver).to be_a Stannum::Constraints::Identity }

    it { expect(constraint.receiver.expected_value).to be count }
  end

  describe '#type' do
    include_examples 'should have reader',
      :type,
      'stannum.constraints.is_not_value'
  end
end
