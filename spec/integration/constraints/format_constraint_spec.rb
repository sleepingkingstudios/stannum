# frozen_string_literal: true

require 'support/constraints/format_constraint'

# @note Integration spec for Stannum::Constraint.
RSpec.describe Spec::FormatConstraint do
  subject(:constraint) { described_class.new(format) }

  let(:format) { /a/ }

  describe '::NEGATED_TYPE' do
    include_examples 'should define constant',
      :NEGATED_TYPE,
      'spec.constraints.right_format'
  end

  describe '::TYPE' do
    include_examples 'should define constant',
      :TYPE,
      'spec.constraints.wrong_format'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(1).argument }
  end

  describe '#does_not_match?' do
    let(:status) { constraint.does_not_match?(actual) }

    describe 'with nil' do
      let(:actual) { nil }

      it { expect(status).to be true }
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(status).to be true }
    end

    describe 'with an a non-matching string' do
      let(:actual) { 'foo' }

      it { expect(status).to be true }
    end

    describe 'with a matching string' do
      let(:actual) { 'bar' }

      it { expect(status).to be false }
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

    describe 'with an a non-matching string' do
      let(:actual) { 'foo' }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a matching string' do
      let(:actual) { 'bar' }

      it { expect(errors).to be == expected_errors }
    end
  end

  describe '#expected' do
    include_examples 'should have reader', :expected, -> { format }
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

    describe 'with an a non-matching string' do
      let(:actual) { 'foo' }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with a matching string' do
      let(:actual) { 'bar' }

      it { expect(errors).to be nil }

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

    describe 'with an a non-matching string' do
      let(:actual) { 'foo' }

      it { expect(status).to be false }
    end

    describe 'with a matching string' do
      let(:actual) { 'bar' }

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

    describe 'with an a non-matching string' do
      let(:actual) { 'foo' }

      it { expect(errors).to be == expected_errors }
    end

    describe 'with a matching string' do
      let(:actual) { 'bar' }

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

      it { expect(errors).to be nil }

      it { expect(status).to be true }
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }

      it { expect(errors).to be nil }

      it { expect(status).to be true }
    end

    describe 'with an a non-matching string' do
      let(:actual) { 'foo' }

      it { expect(errors).to be nil }

      it { expect(status).to be true }
    end

    describe 'with a matching string' do
      let(:actual) { 'bar' }

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end

  describe '#negated_type' do
    include_examples 'should have reader',
      :negated_type,
      'spec.constraints.right_format'
  end

  describe '#type' do
    include_examples 'should have reader',
      :type,
      'spec.constraints.wrong_format'
  end
end
