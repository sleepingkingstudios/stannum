# frozen_string_literal: true

require 'stannum/entities/primary_key'

require 'support/examples/entities/attributes_examples'
require 'support/examples/entities/primary_key_examples'
require 'support/examples/entities/properties_examples'

RSpec.describe Stannum::Entities::PrimaryKey do
  include Spec::Support::Examples::Entities::AttributesExamples
  include Spec::Support::Examples::Entities::PrimaryKeyExamples
  include Spec::Support::Examples::Entities::PropertiesExamples

  subject(:entity) { described_class.new(**properties) }

  let(:properties) { {} }

  def self.define_entity(mod)
    mod.include Stannum::Entities::Properties
    mod.include Stannum::Entities::Attributes
    mod.include Stannum::Entities::PrimaryKey # rubocop:disable RSpec/DescribedClass
  end

  include_context 'with an entity class'

  describe '::PrimaryKeyAlreadyExists' do
    include_examples 'should define constant',
      :PrimaryKeyAlreadyExists,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::PrimaryKeyMissing' do
    include_examples 'should define constant',
      :PrimaryKeyMissing,
      -> { be_a(Class).and(be < StandardError) }
  end

  include_examples 'should implement the Attributes methods'

  include_examples 'should implement the Properties methods'

  include_examples 'should implement the PrimaryKey methods'
end
