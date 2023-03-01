# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module EntityExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_context 'with an abstract entity class' do
      let(:abstract_class)  { Spec::AbstractEntityClass }
      let(:described_class) { Spec::ConcreteClass }
      let(:entity_class)    { Spec::ConcreteClass }

      example_class 'Spec::AbstractEntityClass' do |klass|
        self.class.define_entity(klass)
      end

      example_class 'Spec::ConcreteClass', 'Spec::AbstractEntityClass'
    end

    shared_context 'with an abstract entity module' do
      let(:described_class) { Spec::ConcreteClass }
      let(:entity_class)    { Spec::ConcreteClass }

      example_constant 'Spec::AbstractEntityModule' do
        mod = Module.new do
          class << self
            # :nocov:
            def name
              'Spec::AbstractEntityModule'
            end
            alias_method :inspect, :name
            alias_method :to_s, :name
            # :nocov:
          end
        end

        self.class.define_entity(mod)

        mod
      end

      example_class 'Spec::ConcreteClass' do |klass|
        klass.include Spec::AbstractEntityModule
      end
    end

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
