# frozen_string_literal: true

require 'stannum/constraints/presence'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Presence do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new }

  let(:expected_errors) do
    Stannum::Errors.new.add(constraint.type)
  end
  let(:negated_errors) do
    Stannum::Errors.new.add(constraint.negated_type)
  end

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.present'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.absent'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should not match', nil, reversible: true

  include_examples 'should match', true, reversible: true

  include_examples 'should match', false, reversible: true

  include_examples 'should match', 0, as: 'an integer', reversible: true

  include_examples 'should match', Object.new.freeze, reversible: true

  include_examples 'should not match', '', 'an empty string', reversible: true

  include_examples 'should match', 'a string', reversible: true

  include_examples 'should match', :a_symbol, reversible: true

  include_examples 'should not match', [], 'an empty array', reversible: true

  include_examples 'should match', %w[a b c], 'an array', reversible: true

  include_examples 'should not match', {}, 'an empty hash', reversible: true

  include_examples 'should match', { a: 'a' }, 'a hash', reversible: true

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      'stannum.constraints.present'
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.absent'
  end
end