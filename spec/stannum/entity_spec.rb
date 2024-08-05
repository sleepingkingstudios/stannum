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

  describe '#inspect' do
    def inspect_association(associated_entity)
      return 'nil' if associated_entity.nil?

      associated_entity.inspect_with_options(associations: false)
    end

    context 'when the entity class defines properties' do
      include_context 'when the entity class defines associations'
      include_context 'when the entity class defines attributes'
      include_context 'when the entity class defines properties'

      let(:expected) do
        "#<#{described_class.name} " \
          "name: #{entity.name.inspect} " \
          "description: #{entity.description.inspect} " \
          "quantity: #{entity.quantity.inspect} " \
          "parent: #{inspect_association(entity.parent)} " \
          "sibling: #{inspect_association(entity.sibling)} " \
          "child: #{inspect_association(entity.child)} " \
          "amplitude: #{entity['amplitude'].inspect} " \
          "frequency: #{entity['frequency'].inspect}" \
          '>'
      end

      it { expect(entity.inspect).to be == expected }

      context 'when the entity has values' do
        include_context 'when the entity has attribute values'
        include_context 'when the entity has association values'
        include_context 'when the entity has property values'

        let(:properties) do
          generic_properties.merge(attributes).merge(associations)
        end

        it { expect(entity.inspect).to be == expected }
      end
    end
  end

  describe '#inspect_with_options' do
    let(:options) { {} }

    def inspect_association(associated_entity)
      return 'nil' if associated_entity.nil?

      associated_entity.inspect_with_options(**options, associations: false)
    end

    context 'when the entity class defines properties' do
      include_context 'when the entity class defines associations'
      include_context 'when the entity class defines attributes'
      include_context 'when the entity class defines properties'

      let(:expected) do
        "#<#{described_class.name} " \
          "name: #{entity.name.inspect} " \
          "description: #{entity.description.inspect} " \
          "quantity: #{entity.quantity.inspect} " \
          "parent: #{inspect_association(entity.parent)} " \
          "sibling: #{inspect_association(entity.sibling)} " \
          "child: #{inspect_association(entity.child)} " \
          "amplitude: #{entity['amplitude'].inspect} " \
          "frequency: #{entity['frequency'].inspect}" \
          '>'
      end

      it 'should format the entity' do
        expect(entity.inspect_with_options(**options)).to be == expected
      end

      context 'when the entity has values' do
        include_context 'when the entity has attribute values'
        include_context 'when the entity has association values'
        include_context 'when the entity has property values'

        let(:properties) do
          generic_properties.merge(attributes).merge(associations)
        end

        it 'should format the entity' do
          expect(entity.inspect_with_options(**options)).to be == expected
        end
      end

      describe 'with attributes: false' do
        let(:options) { super().merge(attributes: false) }
        let(:expected) do
          "#<#{described_class.name} " \
            "parent: #{inspect_association(entity.parent)} " \
            "sibling: #{inspect_association(entity.sibling)} " \
            "child: #{inspect_association(entity.child)} " \
            "amplitude: #{entity['amplitude'].inspect} " \
            "frequency: #{entity['frequency'].inspect}" \
            '>'
        end

        it 'should format the entity' do
          expect(entity.inspect_with_options(**options)).to be == expected
        end

        context 'when the entity has values' do
          include_context 'when the entity has attribute values'
          include_context 'when the entity has association values'
          include_context 'when the entity has property values'

          let(:properties) do
            generic_properties.merge(attributes).merge(associations)
          end

          it 'should format the entity' do
            expect(entity.inspect_with_options(**options)).to be == expected
          end
        end
      end

      describe 'with associations: false' do
        let(:options) { super().merge(associations: false) }
        let(:expected) do
          "#<#{described_class.name} " \
            "name: #{entity.name.inspect} " \
            "description: #{entity.description.inspect} " \
            "quantity: #{entity.quantity.inspect} " \
            "amplitude: #{entity['amplitude'].inspect} " \
            "frequency: #{entity['frequency'].inspect}" \
            '>'
        end

        it 'should format the entity' do
          expect(entity.inspect_with_options(**options)).to be == expected
        end

        context 'when the entity has values' do
          include_context 'when the entity has attribute values'
          include_context 'when the entity has association values'
          include_context 'when the entity has property values'

          let(:properties) do
            generic_properties.merge(attributes).merge(associations)
          end

          it 'should format the entity' do
            expect(entity.inspect_with_options(**options)).to be == expected
          end
        end
      end

      describe 'with properties: false' do
        let(:options) { super().merge(properties: false) }
        let(:expected) do
          "#<#{described_class.name} " \
            "name: #{entity.name.inspect} " \
            "description: #{entity.description.inspect} " \
            "quantity: #{entity.quantity.inspect} " \
            "parent: #{inspect_association(entity.parent)} " \
            "sibling: #{inspect_association(entity.sibling)} " \
            "child: #{inspect_association(entity.child)}" \
            '>'
        end

        it 'should format the entity' do
          expect(entity.inspect_with_options(**options)).to be == expected
        end

        context 'when the entity has values' do
          include_context 'when the entity has attribute values'
          include_context 'when the entity has association values'
          include_context 'when the entity has property values'

          let(:properties) do
            generic_properties.merge(attributes).merge(associations)
          end

          it 'should format the entity' do
            expect(entity.inspect_with_options(**options)).to be == expected
          end
        end
      end
    end
  end
end
