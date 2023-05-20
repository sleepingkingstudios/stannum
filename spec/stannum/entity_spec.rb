# frozen_string_literal: true

require 'stannum/entity'

require 'support/examples/entities/associations_examples'
require 'support/examples/entities/attributes_examples'
require 'support/examples/entities/constraints_examples'
require 'support/examples/entities/primary_key_examples'
require 'support/examples/entities/properties_examples'

RSpec.describe Stannum::Entity do
  include Spec::Support::Examples::EntityExamples
  include Spec::Support::Examples::Entities::AssociationsExamples
  include Spec::Support::Examples::Entities::AttributesExamples
  include Spec::Support::Examples::Entities::ConstraintsExamples
  include Spec::Support::Examples::Entities::PrimaryKeyExamples
  include Spec::Support::Examples::Entities::PropertiesExamples

  subject(:entity) { described_class.new(**properties) }

  let(:properties) { {} }

  def self.define_entity(mod)
    mod.include Stannum::Entity # rubocop:disable RSpec/DescribedClass
  end

  include_context 'with an entity class'

  include_examples 'should implement the Associations methods'

  include_examples 'should implement the Attributes methods'

  include_examples 'should implement the Constraints methods'

  include_examples 'should implement the PrimaryKey methods'

  include_examples 'should implement the Properties methods'
end
