# frozen_string_literal: true

require 'stannum/constraints/base'

require 'support/matchers'

RSpec.describe Spec::Support::Matchers do
  subject(:example_group) do
    Object.new.extend(described_class)
  end

  describe '#be_a_constraint' do
    it 'should define the method' do
      expect(example_group).to respond_to(:be_a_constraint).with(0..1).arguments
    end

    it 'should return a constraint' do
      expect(example_group.be_a_constraint)
        .to be_a Spec::Support::Matchers::BeAConstraintMatcher
    end

    it { expect(example_group.be_a_constraint.expected).to be nil }

    describe 'with an expected constraint' do
      let(:expected_constraint) { Spec::ExampleConstraint }

      example_class 'Spec::ExampleConstraint', Stannum::Constraints::Base

      it 'should set the expected constraint' do
        expect(example_group.be_a_constraint(expected_constraint).expected)
          .to be expected_constraint
      end
    end
  end
end
