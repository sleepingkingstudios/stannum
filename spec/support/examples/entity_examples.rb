# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module EntityExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup
    shared_context 'with an entity class' do
      let(:entity_class)    { Spec::EntityClass }
      let(:described_class) { Spec::EntityClass }

      example_class 'Spec::EntityClass' do |klass|
        self.class.define_entity(klass)
      end
    end

    shared_context 'with an entity subclass' do
      let(:entity_superclass) { Spec::EntityClass }
      let(:described_class)   { Spec::EntitySubclass }

      example_class 'Spec::EntitySubclass', 'Spec::EntityClass'
    end
  end
end
