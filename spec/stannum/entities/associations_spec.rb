# frozen_string_literal: true

require 'stannum/entities/associations'
require 'stannum/entities/properties'

require 'support/examples/entities/associations_examples'
require 'support/examples/entities/properties_examples'

RSpec.describe Stannum::Entities::Associations do
  include Spec::Support::Examples::Entities::AssociationsExamples
  include Spec::Support::Examples::Entities::PropertiesExamples

  subject(:entity) { described_class.new(**properties) }

  let(:properties) { {} }

  def self.define_entity(mod)
    mod.include Stannum::Entities::Properties
    mod.include Stannum::Entities::Associations # rubocop:disable RSpec/DescribedClass
  end

  include_context 'with an entity class'

  include_examples 'should implement the Associations methods'

  include_examples 'should implement the Properties methods'
end
