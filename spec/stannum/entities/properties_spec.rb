# frozen_string_literal: true

require 'stannum/entities/properties'

require 'support/entities/generic_properties'
require 'support/examples/entities/properties_examples'

RSpec.describe Stannum::Entities::Properties do
  include Spec::Support::Examples::EntityExamples
  include Spec::Support::Examples::Entities::PropertiesExamples

  subject(:entity) { described_class.new(**properties) }

  let(:properties) { {} }

  def self.define_entity(mod)
    mod.include Stannum::Entities::Properties # rubocop:disable RSpec/DescribedClass
  end

  include_context 'with an entity class'

  include_examples 'should implement the Properties methods'
end
