# frozen_string_literal: true

require 'stannum/entities/attributes'
require 'stannum/entities/constraints'
require 'stannum/entities/properties'

require 'support/examples/entities/constraints_examples'

RSpec.describe Stannum::Entities::Constraints do
  include Spec::Support::Examples::Entities::ConstraintsExamples

  subject(:entity) { described_class.new(**properties) }

  let(:properties) { {} }

  def self.define_entity(mod)
    mod.include Stannum::Entities::Properties
    mod.include Stannum::Entities::Attributes
    mod.include Stannum::Entities::Constraints # rubocop:disable RSpec/DescribedClass
  end

  include_context 'with an entity class'

  include_examples 'should implement the Constraints methods'

  describe '.attribute' do
    context 'when the entity does not include attributes' do
      def self.define_entity(mod)
        mod.include Stannum::Entities::Constraints # rubocop:disable RSpec/DescribedClass
      end

      it { expect(described_class).not_to respond_to(:attribute) }
    end
  end
end
