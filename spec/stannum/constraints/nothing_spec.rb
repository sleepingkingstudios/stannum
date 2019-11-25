# frozen_string_literal: true

require 'stannum/constraints/nothing'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Nothing do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) { described_class.new }

  let(:expected_errors) do
    Stannum::Errors.new.add(constraint.type)
  end

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      'stannum.constraints.nothing'
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      'stannum.constraints.anything'
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  include_examples 'should implement the Constraint interface'

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

  include_examples 'should not match', {}, as: 'an empty hash', reversible: true

  include_examples 'should not match',
    { a: 'a' },
    as:         'a hash',
    reversible: true

  describe '#negated_type' do
    include_examples 'should define reader',
      :negated_type,
      'stannum.constraints.nothing'
  end

  describe '#type' do
    include_examples 'should define reader',
      :type,
      'stannum.constraints.anything'
  end
end
