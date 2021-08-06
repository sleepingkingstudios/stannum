# frozen_string_literal: true

require 'stannum/rspec/match_errors'

require 'support/constraints/length_constraint'

# @note Integration spec for Stannum::Constraints::Base.
RSpec.describe Spec::LengthConstraint do
  include Stannum::RSpec::Matchers

  subject(:constraint) { described_class.new(length) }

  let(:length) { 0 }

  describe '::NEGATED_TYPE' do
    include_examples 'should define constant',
      :NEGATED_TYPE,
      'spec.constraints.right_length'
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'spec.constraints.wrong_length'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#does_not_match?' do
    describe 'with nil' do
      it { expect(constraint.does_not_match? nil).to be true }
    end

    describe 'with an Object' do
      it { expect(constraint.does_not_match? Object.new.freeze).to be true }
    end

    describe 'with an Array with non-matching length' do
      it { expect(constraint.does_not_match? %w[ichi ni san]).to be true }
    end

    describe 'with an Array with matching length' do
      it { expect(constraint.does_not_match? []).to be false }
    end

    describe 'with a String with non-matching length' do
      it { expect(constraint.does_not_match? 'foo').to be true }
    end

    describe 'with a String with matching length' do
      it { expect(constraint.does_not_match? '').to be false }
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

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an Array with non-matching length' do
      let(:actual) { %w[ichi ni san] }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an Array with matching length' do
      let(:actual) { [] }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a String with non-matching length' do
      let(:actual) { 'foo' }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a String with matching length' do
      let(:actual) { '' }

      it { expect(errors).to be == expected_errors }
    end
  end

  describe '#expected' do
    include_examples 'should have reader', :expected, -> { length }
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

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an Array with non-matching length' do
      let(:actual) { %w[ichi ni san] }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an Array with matching length' do
      let(:actual) { [] }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end

    describe 'with a String with non-matching length' do
      let(:actual) { 'foo' }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a String with matching length' do
      let(:actual) { '' }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end
  end

  describe '#matches?' do
    let(:status) { constraint.matches?(actual) }

    describe 'with nil' do
      let(:actual) { nil }

      it { expect(status).to be false }
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(status).to be false }
    end

    describe 'with an Array with non-matching length' do
      let(:actual) { %w[ichi ni san] }

      it { expect(status).to be false }
    end

    describe 'with an Array with matching length' do
      let(:actual) { [] }

      it { expect(status).to be true }
    end

    describe 'with a String with non-matching length' do
      let(:actual) { 'foo' }

      it { expect(status).to be false }
    end

    describe 'with a String with matching length' do
      let(:actual) { '' }

      it { expect(status).to be true }
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

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an Array with non-matching length' do
      let(:actual) { %w[ichi ni san] }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an Array with matching length' do
      let(:actual) { [] }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a String with non-matching length' do
      let(:actual) { 'foo' }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a String with matching length' do
      let(:actual) { '' }

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

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end

    describe 'with an Array with non-matching length' do
      let(:actual) { %w[ichi ni san] }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end

    describe 'with an Array with matching length' do
      let(:actual) { [] }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a String with non-matching length' do
      let(:actual) { 'foo' }

      it { expect(errors).to match_errors(Stannum::Errors.new) }

      it { expect(status).to be true }
    end

    describe 'with a String with matching length' do
      let(:actual) { '' }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end

  describe '#negated_type' do
    include_examples 'should have reader',
      :negated_type,
      'spec.constraints.right_length'
  end

  describe '#type' do
    include_examples 'should have reader',
      :type,
      'spec.constraints.wrong_length'
  end
end
