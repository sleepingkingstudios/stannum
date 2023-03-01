# frozen_string_literal: true

require 'bigdecimal'

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples/entities'
require 'support/examples/entity_examples'

module Spec::Support::Examples::Entities
  module AttributesExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    include Spec::Support::Examples::EntityExamples

    shared_context 'when the entity class defines attributes' do
      let(:entity_class) do
        defined?(super()) ? super() : Spec::EntityClass
      end

      before(:example) do
        entity_class.instance_eval do
          attribute :name,        'String'
          attribute :description, 'String',  optional: true
          attribute :quantity,    'Integer', default:  0
        end
      end
    end

    shared_context 'when the subclass defines attributes' do
      before(:example) do
        Spec::EntitySubclass.instance_eval do
          attribute :size, 'String'
        end
      end
    end

    shared_context 'when the entity has attribute values' do
      let(:attributes) do
        {
          'description' => 'No one is quite sure what this thing is.',
          'name'        => 'Self-sealing Stem Bolt',
          'quantity'    => 1_000
        }
      end
      let(:properties) do
        defined?(super()) ? super().merge(attributes) : attributes
      end
    end

    shared_examples 'should implement the Attributes methods' do
      describe '::Attributes' do
        it { expect(described_class).to define_constant(:Attributes) }

        it { expect(described_class::Attributes).to be_a Module }

        it 'should include the Attributes schema' do
          expect(described_class.ancestors)
            .to include described_class::Attributes
        end

        it { expect(described_class::Attributes.keys).to be == [] }

        wrap_context 'when the entity class defines attributes' do
          it 'should define attributes for the entity class' do
            expect(described_class::Attributes.keys)
              .to contain_exactly('name', 'description', 'quantity')
          end
        end

        wrap_context 'with an abstract entity class' do
          it { expect(abstract_class::Attributes.keys).to be == [] }

          it { expect(described_class::Attributes.keys).to be == [] }

          wrap_context 'when the entity class defines attributes' do
            it { expect(abstract_class::Attributes.keys).to be == [] }

            it 'should define attributes for the concrete class' do
              expect(described_class::Attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end
          end
        end

        wrap_context 'with an abstract entity module' do
          it { expect(described_class::Attributes.keys).to be == [] }

          wrap_context 'when the entity class defines attributes' do
            it 'should define attributes for the concrete class' do
              expect(entity_class::Attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end
          end
        end

        wrap_context 'with an entity subclass' do
          let(:attributes) { described_class::Attributes }

          it { expect(described_class).to define_constant(:Attributes) }

          it { expect(attributes).to be_a Stannum::Schema }

          it 'should generate independent attributes for the subclass' do
            expect(attributes).not_to be entity_superclass::Attributes
          end

          wrap_context 'when the entity class defines attributes' do
            it 'should define attributes for the entity class' do
              expect(entity_superclass::Attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end

            it 'should define attributes for the entity subclass' do
              expect(described_class::Attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end
          end

          wrap_context 'when the subclass defines attributes' do
            it { expect(entity_superclass::Attributes.keys).to be == [] }

            it 'should define attributes for the entity subclass' do
              expect(described_class::Attributes.keys)
                .to contain_exactly('size')
            end
          end

          context 'when the struct and the subclass define attributes' do
            include_context 'when the entity class defines attributes'
            include_context 'when the subclass defines attributes'

            it 'should define attributes for the entity class' do
              expect(entity_superclass::Attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end

            it 'should define attributes for the entity subclass' do
              expect(described_class::Attributes.keys)
                .to contain_exactly('name', 'description', 'quantity', 'size')
            end
          end
        end
      end

      describe '.attribute' do
        shared_examples 'should define the attribute' do
          let(:expected) do
            an_instance_of(Stannum::Attribute)
              .and(
                have_attributes(
                  name:    attr_name.to_s,
                  type:    attr_type.to_s,
                  options: { required: true }.merge(options)
                )
              )
          end

          def define_attribute
            described_class.attribute(attr_name, attr_type, **options)
          end

          it 'should add the attribute to ::Attributes' do
            expect { define_attribute }
              .to change { described_class.attributes.count }
              .by(1)
          end

          it 'should add the attribute key to ::Attributes' do
            expect { define_attribute }
              .to change(described_class.attributes, :each_key)
              .to include(attr_name.to_s)
          end

          it 'should add the attribute value to ::Attributes' do
            expect { define_attribute }
              .to change(described_class.attributes, :each_value)
              .to include(expected)
          end
        end

        let(:attr_name) { :price }
        let(:attr_type) { BigDecimal }
        let(:options)   { {} }

        it 'should define the class method' do
          expect(described_class)
            .to respond_to(:attribute)
            .with(2).arguments
            .and_any_keywords
        end

        describe 'with attr_name: a String' do
          let(:attr_name) { 'price' }

          it 'should return the attribute name as a Symbol' do
            expect(described_class.attribute(attr_name, attr_type, **options))
              .to be :price
          end

          include_examples 'should define the attribute'
        end

        describe 'with attr_name: a Symbol' do
          let(:attr_name) { :price }

          it 'should return the attribute name as a Symbol' do
            expect(described_class.attribute(attr_name, attr_type, **options))
              .to be :price
          end

          include_examples 'should define the attribute'
        end

        describe 'with options: value' do
          let(:options) { { key: 'value' } }

          include_examples 'should define the attribute'
        end

        wrap_context 'when the entity class defines attributes' do
          include_examples 'should define the attribute'

          describe 'with options: value' do
            let(:options) { { key: 'value' } }

            include_examples 'should define the attribute'
          end
        end
      end

      describe '.attributes' do
        it { expect(described_class).to have_reader(:attributes) }

        it { expect(described_class.attributes).to be_a Module }

        it { expect(described_class.attributes.keys).to be == [] }

        wrap_context 'when the entity class defines attributes' do
          it 'should define attributes for the entity class' do
            expect(described_class.attributes.keys)
              .to contain_exactly('name', 'description', 'quantity')
          end
        end

        wrap_context 'with an abstract entity class' do
          it { expect(abstract_class.attributes.keys).to be == [] }

          it { expect(described_class.attributes.keys).to be == [] }

          wrap_context 'when the entity class defines attributes' do
            it { expect(abstract_class.attributes.keys).to be == [] }

            it 'should define attributes for the concrete class' do
              expect(described_class.attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end
          end
        end

        wrap_context 'with an abstract entity module' do
          it { expect(described_class.attributes.keys).to be == [] }

          wrap_context 'when the entity class defines attributes' do
            it 'should define attributes for the concrete class' do
              expect(entity_class.attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end
          end
        end

        wrap_context 'with an entity subclass' do
          let(:attributes) { described_class.attributes }

          it { expect(described_class).to define_constant(:Attributes) }

          it { expect(attributes).to be_a Stannum::Schema }

          it 'should generate independent attributes for the subclass' do
            expect(attributes).not_to be entity_superclass.attributes
          end

          wrap_context 'when the entity class defines attributes' do
            it 'should define attributes for the entity class' do
              expect(entity_superclass.attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end

            it 'should define attributes for the entity subclass' do
              expect(described_class.attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end
          end

          wrap_context 'when the subclass defines attributes' do
            it { expect(entity_superclass.attributes.keys).to be == [] }

            it 'should define attributes for the entity subclass' do
              expect(described_class.attributes.keys)
                .to contain_exactly('size')
            end
          end

          context 'when the struct and the subclass define attributes' do
            include_context 'when the entity class defines attributes'
            include_context 'when the subclass defines attributes'

            it 'should define attributes for the entity class' do
              expect(entity_superclass.attributes.keys)
                .to contain_exactly('name', 'description', 'quantity')
            end

            it 'should define attributes for the entity subclass' do
              expect(described_class.attributes.keys)
                .to contain_exactly('name', 'description', 'quantity', 'size')
            end
          end
        end
      end

      describe '.new' do
        wrap_context 'when the entity class defines attributes' do
          describe 'with invalid String keys' do
            let(:properties)    { super().merge('upc' => '12345') }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with invalid Symbol keys' do
            let(:properties)    { super().merge(upc: '12345') }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:properties) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'upc'         => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:properties) do
              {
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt',
                upc:         '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with valid String keys' do
            let(:properties) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt'
              }
            end
            let(:expected) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the attributes' do
              expect(described_class.new(**properties).attributes)
                .to be == expected
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:properties) do
              {
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt'
              }
            end
            let(:expected) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the attributes' do
              expect(described_class.new(**properties).attributes)
                .to be == expected
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with valid String keys' do
            let(:properties) do
              {
                'amplitude'   => '1 TW',
                'frequency'   => '1 Hz',
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt'
              }
            end
            let(:expected_attributes) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the attributes' do
              expect(described_class.new(**properties).attributes)
                .to be == expected_attributes
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:properties) do
              {
                amplitude:   '1 TW',
                frequency:   '1 Hz',
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt'
              }
            end
            let(:expected_attributes) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it 'should set the attributes' do
              expect(described_class.new(**properties).attributes)
                .to be == expected_attributes
            end

            it 'should set the properties' do
              expect(described_class.new(**properties).properties)
                .to be == expected_properties
            end
          end
        end
      end

      describe '#:attribute' do
        it { expect(entity).not_to respond_to(:name) }

        it { expect(entity).not_to respond_to(:quantity) }

        it { expect(entity).not_to respond_to(:size) }

        wrap_context 'when the entity class defines attributes' do
          it { expect(entity).to respond_to(:name).with(0).arguments }

          it { expect(entity.name).to be nil }

          context 'when the attribute has a default value' do
            it { expect(entity.quantity).to be 0 }
          end

          wrap_context 'when the entity has attribute values' do
            it { expect(entity.name).to be == attributes['name'] }
          end
        end

        wrap_context 'with an entity subclass' do
          it { expect(entity).not_to respond_to(:name) }

          it { expect(entity).not_to respond_to(:quantity) }

          it { expect(entity).not_to respond_to(:size) }

          wrap_context 'when the entity class defines attributes' do
            it { expect(entity).to respond_to(:name).with(0).arguments }

            it { expect(entity.name).to be nil }

            context 'when the attribute has a default value' do
              it { expect(entity.quantity).to be 0 }
            end

            wrap_context 'when the entity has attribute values' do
              it { expect(entity.name).to be == attributes['name'] }
            end
          end

          wrap_context 'when the subclass defines attributes' do
            it { expect(entity).to respond_to(:size).with(0).arguments }

            it { expect(entity.size).to be nil }
          end

          context 'when the struct and the subclass define attributes' do
            include_context 'when the entity class defines attributes'
            include_context 'when the subclass defines attributes'

            it { expect(entity.name).to be nil }

            it { expect(entity.size).to be nil }

            wrap_context 'when the entity has attribute values' do
              let(:attributes) { { 'size' => 'XL' } }

              it { expect(entity.size).to be == attributes['size'] }
            end
          end
        end
      end

      describe '#:attribute=' do
        it { expect(entity).not_to respond_to(:name=) }

        it { expect(entity).not_to respond_to(:size=) }

        wrap_context 'when the entity class defines attributes' do
          it { expect(entity).to respond_to(:name=).with(1).argument }

          it 'should update the attribute' do
            expect { entity.name = 'Can of Headlight Fluid' }
              .to change(entity, :name)
              .to be == 'Can of Headlight Fluid'
          end
        end

        wrap_context 'with an entity subclass' do
          it { expect(entity).not_to respond_to(:name=) }

          it { expect(entity).not_to respond_to(:size=) }

          wrap_context 'when the entity class defines attributes' do
            it { expect(entity).to respond_to(:name=).with(1).argument }

            it 'should update the attribute' do
              expect { entity.name = 'Can of Headlight Fluid' }
                .to change(entity, :name)
                .to be == 'Can of Headlight Fluid'
            end
          end

          wrap_context 'when the subclass defines attributes' do
            it { expect(entity).to respond_to(:size=).with(1).argument }

            it 'should update the attribute' do
              expect { entity.size = 'Colossal' }
                .to change(entity, :size)
                .to be == 'Colossal'
            end
          end

          context 'when the struct and the subclass define attributes' do
            include_context 'when the entity class defines attributes'
            include_context 'when the subclass defines attributes'

            it { expect(entity).to respond_to(:name=).with(1).argument }

            it { expect(entity).to respond_to(:quantity=).with(1).argument }
          end
        end
      end

      describe '#==' do
        wrap_context 'when the entity class defines attributes' do
          describe 'with an entity with matching attributes' do
            let(:other) { described_class.new(**properties) }

            it { expect(entity == other).to be true }
          end

          describe 'with an entity with non-matching attributes' do
            let(:other_properties) do
              properties.merge(name: 'Can of Headlight Fluid')
            end
            let(:other) { described_class.new(**other_properties) }

            it { expect(entity == other).to be false }
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with an entity with matching attributes' do
              let(:other) { described_class.new(**properties) }

              it { expect(entity == other).to be true }
            end

            describe 'with an entity with non-matching attributes' do
              let(:other_properties) do
                properties.merge(name: 'Can of Headlight Fluid')
              end
              let(:other) { described_class.new(**other_properties) }

              it { expect(entity == other).to be false }
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with an entity with matching properties' do
            let(:other) { described_class.new(**properties) }

            it { expect(entity == other).to be true }
          end

          describe 'with an entity with non-matching properties' do
            let(:other_properties) do
              properties.merge(
                amplitude: '1.21 GW',
                name:      'Can of Headlight Fluid'
              )
            end
            let(:other) { described_class.new(**other_properties) }

            it { expect(entity == other).to be false }
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with an entity with matching properties' do
              let(:other) { described_class.new(**properties) }

              it { expect(entity == other).to be true }
            end

            describe 'with an entity with non-matching properties' do
              let(:other_properties) do
                properties.merge(
                  amplitude: '1.21 GW',
                  name:      'Can of Headlight Fluid'
                )
              end
              let(:other) { described_class.new(**other_properties) }

              it { expect(entity == other).to be false }
            end
          end
        end
      end

      describe '#[]' do
        wrap_context 'when the entity class defines attributes' do
          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid String' do
            it { expect(entity['name']).to be nil }
          end

          describe 'with a valid Symbol' do
            it { expect(entity[:name]).to be nil }
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with a valid String' do
              it { expect(entity['name']).to be == attributes['name'] }
            end

            describe 'with a valid Symbol' do
              it { expect(entity[:name]).to be == attributes['name'] }
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid attribute String' do
            it { expect(entity['name']).to be nil }
          end

          describe 'with a valid attribute Symbol' do
            it { expect(entity[:name]).to be nil }
          end

          describe 'with a valid property String' do
            it { expect(entity['amplitude']).to be nil }
          end

          describe 'with a valid property Symbol' do
            it { expect(entity[:amplitude]).to be nil }
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with a valid attribute String' do
              it { expect(entity['name']).to be == attributes['name'] }
            end

            describe 'with a valid attribute Symbol' do
              it { expect(entity[:name]).to be == attributes['name'] }
            end

            describe 'with a valid property String' do
              it 'should return the property value' do
                expect(entity['amplitude'])
                  .to be == generic_properties['amplitude']
              end
            end

            describe 'with a valid property Symbol' do
              it 'should return the property value' do
                expect(entity[:amplitude])
                  .to be == generic_properties['amplitude']
              end
            end
          end
        end
      end

      describe '#[]=' do
        wrap_context 'when the entity class defines attributes' do
          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid String' do
            it 'should call the writer method' do
              allow(entity).to receive(:name=)

              entity['name'] = 'Can of Headlight Fluid'

              expect(entity)
                .to have_received(:name=)
                .with('Can of Headlight Fluid')
            end

            it 'should change the property value' do
              expect { entity['name'] = 'Can of Headlight Fluid' }
                .to change { entity['name'] }
                .to be == 'Can of Headlight Fluid'
            end
          end

          describe 'with a valid Symbol' do
            it 'should call the writer method' do
              allow(entity).to receive(:name=)

              entity[:name] = 'Can of Headlight Fluid'

              expect(entity)
                .to have_received(:name=)
                .with('Can of Headlight Fluid')
            end

            it 'should change the property value' do
              expect { entity[:name] = 'Can of Headlight Fluid' }
                .to change { entity['name'] }
                .to be == 'Can of Headlight Fluid'
            end
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with a valid String' do
              it 'should change the property value' do
                expect { entity['name'] = 'Can of Headlight Fluid' }
                  .to change { entity['name'] }
                  .to be == 'Can of Headlight Fluid'
              end
            end

            describe 'with a valid Symbol' do
              it 'should change the property value' do
                expect { entity[:name] = 'Can of Headlight Fluid' }
                  .to change { entity['name'] }
                  .to be == 'Can of Headlight Fluid'
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with an invalid String' do
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity['phase_angle'] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with an invalid Symbol' do
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity[:phase_angle] = 'π' }
                .to raise_error(ArgumentError, error_message)
            end
          end

          describe 'with a valid attribute String' do
            it 'should call the writer method' do
              allow(entity).to receive(:name=)

              entity['name'] = 'Can of Headlight Fluid'

              expect(entity)
                .to have_received(:name=)
                .with('Can of Headlight Fluid')
            end

            it 'should change the property value' do
              expect { entity['name'] = 'Can of Headlight Fluid' }
                .to change { entity['name'] }
                .to be == 'Can of Headlight Fluid'
            end
          end

          describe 'with a valid attribute Symbol' do
            it 'should call the writer method' do
              allow(entity).to receive(:name=)

              entity[:name] = 'Can of Headlight Fluid'

              expect(entity)
                .to have_received(:name=)
                .with('Can of Headlight Fluid')
            end

            it 'should change the property value' do
              expect { entity[:name] = 'Can of Headlight Fluid' }
                .to change { entity['name'] }
                .to be == 'Can of Headlight Fluid'
            end
          end

          describe 'with a valid property String' do
            it 'should change the property value' do
              expect { entity['amplitude'] = '1.21 GW' }
                .to change { entity['amplitude'] }
                .to be == '1.21 GW'
            end
          end

          describe 'with a valid property Symbol' do
            it 'should change the property value' do
              expect { entity[:amplitude] = '1.21 GW' }
                .to change { entity['amplitude'] }
                .to be == '1.21 GW'
            end
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with a valid attribute String' do
              it 'should change the property value' do
                expect { entity['name'] = 'Can of Headlight Fluid' }
                  .to change { entity['name'] }
                  .to be == 'Can of Headlight Fluid'
              end
            end

            describe 'with a valid attribute Symbol' do
              it 'should change the property value' do
                expect { entity[:name] = 'Can of Headlight Fluid' }
                  .to change { entity['name'] }
                  .to be == 'Can of Headlight Fluid'
              end
            end

            describe 'with a valid property String' do
              it 'should change the property value' do
                expect { entity['amplitude'] = '1.21 GW' }
                  .to change { entity['amplitude'] }
                  .to be == '1.21 GW'
              end
            end

            describe 'with a valid property Symbol' do
              it 'should change the property value' do
                expect { entity[:amplitude] = '1.21 GW' }
                  .to change { entity['amplitude'] }
                  .to be == '1.21 GW'
              end
            end
          end
        end
      end

      describe '#assign_attributes' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        it { expect(entity).to respond_to(:assign_attributes).with(1).argument }

        describe 'with nil' do
          let(:error_message) { 'attributes must be a Hash' }

          it 'should raise an exception' do
            expect { entity.assign_attributes nil }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'attributes must be a Hash' }

          it 'should raise an exception' do
            expect { entity.assign_attributes Object.new.freeze }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with nil keys' do
          let(:values)        { { nil => 'value' } }
          let(:error_message) { "attribute can't be blank" }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with Object keys' do
          let(:values)        { { Object.new.freeze => 'value' } }
          let(:error_message) { 'attribute is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty String keys' do
          let(:values)        { { '' => 'value' } }
          let(:error_message) { "attribute can't be blank" }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty Symbol keys' do
          let(:values)        { { '': 'value' } }
          let(:error_message) { "attribute can't be blank" }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with empty attributes' do
          let(:values) { {} }

          it { expect { entity.assign_attributes(values) }.not_to raise_error }

          it 'should not change the entity attributes' do
            expect { entity.assign_attributes(values) }
              .not_to change(entity, :attributes)
          end

          it 'should not change the entity properties' do
            expect { entity.assign_attributes(values) }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid String keys' do
          let(:values)        { { 'phase_angle' => 'π' } }
          let(:error_message) { 'unknown attribute "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity attributes' do
            expect { rescue_exception { entity.assign_attributes(values) } }
              .not_to change(entity, :attributes)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.assign_attributes(values) } }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid Symbol keys' do
          let(:values)        { { phase_angle: 'π' } }
          let(:error_message) { 'unknown attribute :phase_angle' }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity attributes' do
            expect { rescue_exception { entity.assign_attributes(values) } }
              .not_to change(entity, :attributes)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.assign_attributes(values) } }
              .not_to change(entity, :properties)
          end
        end

        wrap_context 'when the entity class defines attributes' do
          describe 'with empty attributes' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_attributes(values) }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.assign_attributes(values) }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_attributes(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown attribute "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown attribute :upc' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'upc'         => '12345'
              }
            end
            let(:error_message) { 'unknown attribute "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt',
                upc:         '12345'
              }
            end
            let(:error_message) { 'unknown attribute :upc' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'name'     => 'Self-sealing Stem Bolt',
                'quantity' => nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_attributes(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_attributes(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                name:     'Self-sealing Stem Bolt',
                quantity: nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_attributes(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_attributes(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with empty attributes' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_attributes(values) }.not_to raise_error
              end

              it 'should not change the entity attributes' do
                expect { entity.assign_attributes(values) }
                  .not_to change(entity, :attributes)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_attributes(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'name'     => 'Can of Headlight Fluid',
                  'quantity' => nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_attributes(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  name:     'Can of Headlight Fluid',
                  quantity: nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_attributes(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with empty attributes' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_attributes(values) }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.assign_attributes(values) }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_attributes(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown attribute "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown attribute :upc' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with String property keys' do
            let(:values)        { { 'amplitude' => '1.21 GW' } }
            let(:error_message) { 'unknown attribute "amplitude"' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with Symbol property keys' do
            let(:values)        { { amplitude: '1.21 GW' } }
            let(:error_message) { 'unknown attribute :amplitude' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'name'     => 'Self-sealing Stem Bolt',
                'quantity' => nil
              }
            end
            let(:expected_attributes) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => nil,
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_attributes(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_attributes(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :attributes)
                .to be == expected_attributes
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                name:     'Self-sealing Stem Bolt',
                quantity: nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_attributes(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_attributes(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with empty attributes' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_attributes(values) }.not_to raise_error
              end

              it 'should not change the entity attributes' do
                expect { entity.assign_attributes(values) }
                  .not_to change(entity, :attributes)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_attributes(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'name'     => 'Can of Headlight Fluid',
                  'quantity' => nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_attributes(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  name:     'Can of Headlight Fluid',
                  quantity: nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_attributes(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_attributes(values) } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#assign_properties' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        wrap_context 'when the entity class defines attributes' do
          describe 'with empty attributes' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'upc'         => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt',
                upc:         '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'name'     => 'Self-sealing Stem Bolt',
                'quantity' => nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                name:     'Self-sealing Stem Bolt',
                quantity: nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with empty attributes' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should not change the entity attributes' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :attributes)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'name'     => 'Can of Headlight Fluid',
                  'quantity' => nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { entity.assign_properties(values) }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { entity.assign_properties(values) }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  name:     'Can of Headlight Fluid',
                  quantity: nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { entity.assign_properties(values) }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { entity.assign_properties(values) }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with empty attributes' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.assign_properties(values) }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'amplitude' => '1 TW',
                'frequency' => '1 Hz',
                'name'      => 'Self-sealing Stem Bolt',
                'quantity'  => nil
              }
            end
            let(:expected_attributes) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :attributes)
                .to be == expected_attributes
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be >= expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                amplitude: '1 TW',
                frequency: '1 Hz',
                name:      'Self-sealing Stem Bolt',
                quantity:  nil
              }
            end
            let(:expected_attributes) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              )
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.assign_properties(values)

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :attributes)
                .to be == expected_attributes
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .to change(entity, :properties)
                .to be >= expected_properties
            end
          end

          context 'when the entity has property values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with empty attributes' do
              let(:values) { {} }

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should not change the entity attributes' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :attributes)
              end

              it 'should not change the entity properties' do
                expect { entity.assign_properties(values) }
                  .not_to change(entity, :properties)
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz',
                  'name'      => 'Self-sealing Stem Bolt',
                  'quantity'  => nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Self-sealing Stem Bolt',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :properties)
                  .to be >= expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  amplitude: '1 TW',
                  frequency: '1 Hz',
                  name:      'Self-sealing Stem Bolt',
                  quantity:  nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Self-sealing Stem Bolt',
                  'description' => 'No one is quite sure what this thing is.',
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => '1 TW',
                  'frequency' => '1 Hz'
                )
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.assign_properties(values) } }
                  .to change(entity, :properties)
                  .to be >= expected_properties
              end
            end
          end
        end
      end

      describe '#attributes' do
        include_examples 'should define reader', :attributes, {}

        it 'should return a copy of the attributes' do
          expect { entity.attributes['name'] = 'Can of Headlight Fluid' }
            .not_to change(entity, :attributes)
        end

        wrap_context 'when the entity class defines attributes' do
          let(:expected) do
            {
              'description' => nil,
              'name'        => nil,
              'quantity'    => 0
            }
          end

          it { expect(entity.attributes).to be == expected }

          wrap_context 'when the entity has attribute values' do
            it { expect(entity.attributes).to be == attributes }
          end
        end
      end

      describe '#attributes=' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        include_examples 'should define writer', :attributes=

        describe 'with nil' do
          let(:error_message) { 'attributes must be a Hash' }

          it 'should raise an exception' do
            expect { entity.attributes = nil }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'attributes must be a Hash' }

          it 'should raise an exception' do
            expect { entity.attributes = Object.new.freeze }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with nil keys' do
          let(:values)        { { nil => 'value' } }
          let(:error_message) { "attribute can't be blank" }

          it 'should raise an exception' do
            expect { entity.attributes = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with Object keys' do
          let(:values)        { { Object.new.freeze => 'value' } }
          let(:error_message) { 'attribute is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity.attributes = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty String keys' do
          let(:values)        { { '' => 'value' } }
          let(:error_message) { "attribute can't be blank" }

          it 'should raise an exception' do
            expect { entity.attributes = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with a Hash with empty Symbol keys' do
          let(:values)        { { '': 'value' } }
          let(:error_message) { "attribute can't be blank" }

          it 'should raise an exception' do
            expect { entity.attributes = values }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with empty attributes' do
          let(:values) { {} }

          it { expect { entity.attributes = values }.not_to raise_error }

          it 'should not change the entity attributes' do
            expect { entity.attributes = values }
              .not_to change(entity, :attributes)
          end

          it 'should not change the entity properties' do
            expect { entity.attributes = values }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid String keys' do
          let(:values)        { { 'phase_angle' => 'π' } }
          let(:error_message) { 'unknown attribute "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.attributes = values }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity attributes' do
            expect { rescue_exception { entity.attributes = values } }
              .not_to change(entity, :attributes)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.attributes = values } }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid Symbol keys' do
          let(:values)        { { phase_angle: 'π' } }
          let(:error_message) { 'unknown attribute :phase_angle' }

          it 'should raise an exception' do
            expect { entity.assign_attributes(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the entity attributes' do
            expect { rescue_exception { entity.assign_attributes(values) } }
              .not_to change(entity, :attributes)
          end

          it 'should not change the entity properties' do
            expect { rescue_exception { entity.assign_attributes(values) } }
              .not_to change(entity, :properties)
          end
        end

        wrap_context 'when the entity class defines attributes' do
          describe 'with empty attributes' do
            let(:values) { {} }

            it { expect { entity.attributes = values }.not_to raise_error }

            it 'should not change the entity attributes' do
              expect { entity.attributes = values }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.attributes = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'phase_angle' => 'π' } }
            let(:error_message) { 'unknown attribute "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { phase_angle: 'π' } }
            let(:error_message) { 'unknown attribute :phase_angle' }

            it 'should raise an exception' do
              expect { entity.assign_attributes(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.assign_attributes(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'upc'         => '12345'
              }
            end
            let(:error_message) { 'unknown attribute "upc"' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt',
                upc:         '12345'
              }
            end
            let(:error_message) { 'unknown attribute :upc' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'name'     => 'Self-sealing Stem Bolt',
                'quantity' => nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.attributes = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.attributes = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                name:     'Self-sealing Stem Bolt',
                quantity: nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.attributes = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.attributes = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with empty attributes' do
              let(:values) { {} }
              let(:expected) do
                {
                  'description' => nil,
                  'name'        => nil,
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.attributes = values }.not_to raise_error
              end

              it 'should clear the entity attributes' do
                expect { entity.attributes = values }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should clear the entity properties' do
                expect { entity.attributes = values }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'name'     => 'Self-sealing Stem Bolt',
                  'quantity' => nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Self-sealing Stem Bolt',
                  'description' => nil,
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.attributes = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  name:     'Self-sealing Stem Bolt',
                  quantity: nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Self-sealing Stem Bolt',
                  'description' => nil,
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.attributes = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with empty attributes' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.attributes = values }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.attributes = values }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.attributes = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown attribute "upc"' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown attribute :upc' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with String property keys' do
            let(:values)        { { 'amplitude' => '1.21 GW' } }
            let(:error_message) { 'unknown attribute "amplitude"' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with Symbol property keys' do
            let(:values)        { { amplitude: '1.21 GW' } }
            let(:error_message) { 'unknown attribute :amplitude' }

            it 'should raise an exception' do
              expect { entity.attributes = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'name'     => 'Self-sealing Stem Bolt',
                'quantity' => nil
              }
            end
            let(:expected_attributes) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => nil,
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.attributes = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.attributes = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :attributes)
                .to be == expected_attributes
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                name:     'Self-sealing Stem Bolt',
                quantity: nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.attributes = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.attributes = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.attributes = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with empty attributes' do
              let(:values) { {} }
              let(:expected_attributes) do
                {
                  'name'        => nil,
                  'description' => nil,
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(generic_properties)
              end

              it 'should not raise an exception' do
                expect { entity.attributes = values }.not_to raise_error
              end

              it 'should clear the entity attributes' do
                expect { entity.attributes = values }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should not change the non-attribute properties' do
                expect { entity.attributes = values }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'name'     => 'Can of Headlight Fluid',
                  'quantity' => nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => nil,
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(generic_properties)
              end

              it 'should not raise an exception' do
                expect { entity.attributes = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should not change the non-attribute properties' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  name:     'Can of Headlight Fluid',
                  quantity: nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => nil,
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(generic_properties)
              end

              it 'should not raise an exception' do
                expect { entity.attributes = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should not change the non-attribute properties' do
                expect { rescue_exception { entity.attributes = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#inspect' do
        wrap_context 'when the entity class defines attributes' do
          let(:expected) do
            "#<#{described_class.name} " \
              "name: #{entity.name.inspect} " \
              "description: #{entity.description.inspect} " \
              "quantity: #{entity.quantity.inspect}" \
              '>'
          end

          it { expect(entity.inspect).to be == expected }

          wrap_context 'when the entity has attribute values' do
            it { expect(entity.inspect).to be == expected }
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          let(:expected) do
            "#<#{described_class.name} " \
              "name: #{entity.name.inspect} " \
              "description: #{entity.description.inspect} " \
              "quantity: #{entity.quantity.inspect} " \
              "amplitude: #{entity['amplitude'].inspect} " \
              "frequency: #{entity['frequency'].inspect}" \
              '>'
          end

          it { expect(entity.inspect).to be == expected }

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            it { expect(entity.inspect).to be == expected }
          end
        end
      end

      describe '#properties' do
        wrap_context 'when the entity class defines attributes' do
          let(:expected) do
            {
              'description' => nil,
              'name'        => nil,
              'quantity'    => 0
            }
          end

          it { expect(entity.properties).to be == expected }

          wrap_context 'when the entity has attribute values' do
            it { expect(entity.properties).to be == attributes }
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          let(:expected) do
            {
              'description' => nil,
              'name'        => nil,
              'quantity'    => 0,
              'amplitude'   => nil,
              'frequency'   => nil
            }
          end

          it { expect(entity.properties).to be == expected }

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            it { expect(entity.properties).to be == properties }
          end
        end
      end

      describe '#properties=' do
        def rescue_exception
          yield
        rescue ArgumentError
          # Do nothing.
        end

        wrap_context 'when the entity class defines attributes' do
          describe 'with empty properties' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.properties = values }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.properties = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'description' => 'No one is quite sure what this thing is.',
                'name'        => 'Self-sealing Stem Bolt',
                'upc'         => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                description: 'No one is quite sure what this thing is.',
                name:        'Self-sealing Stem Bolt',
                upc:         '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'name'     => 'Self-sealing Stem Bolt',
                'quantity' => nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.properties = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                name:     'Self-sealing Stem Bolt',
                quantity: nil
              }
            end
            let(:expected) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.properties = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :attributes)
                .to be == expected
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be >= expected
            end
          end

          wrap_context 'when the entity has attribute values' do
            describe 'with empty attributes' do
              let(:values) { {} }
              let(:expected) do
                {
                  'description' => nil,
                  'name'        => nil,
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should clear the entity attributes' do
                expect { entity.properties = values }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should clear the entity properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'name'     => 'Can of Headlight Fluid',
                  'quantity' => nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => nil,
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { entity.properties = values }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  name:     'Can of Headlight Fluid',
                  quantity: nil
                }
              end
              let(:expected) do
                {
                  'name'        => 'Can of Headlight Fluid',
                  'description' => nil,
                  'quantity'    => 0
                }
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { entity.properties = values }
                  .to change(entity, :attributes)
                  .to be == expected
              end

              it 'should change the entity properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be >= expected
              end
            end
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          describe 'with empty properties' do
            let(:values) { {} }

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should not change the entity attributes' do
              expect { entity.properties = values }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { entity.properties = values }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid String keys' do
            let(:values)        { { 'upc' => '12345' } }
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { upc: '12345' } }
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'amplitude' => '1.21 GW',
                'name'      => 'Self-sealing Stem Bolt',
                'upc'       => '12345'
              }
            end
            let(:error_message) { 'unknown property "upc"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                amplitude: '1.21 GW',
                name:      'Self-sealing Stem Bolt',
                upc:       '12345'
              }
            end
            let(:error_message) { 'unknown property :upc' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :attributes)
            end

            it 'should not change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'amplitude' => '1.21 GW',
                'name'      => 'Self-sealing Stem Bolt',
                'quantity'  => nil
              }
            end
            let(:expected_attributes) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => '1.21 GW',
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.properties = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :attributes)
                .to be == expected_attributes
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                amplitude: '1.21 GW',
                name:      'Self-sealing Stem Bolt',
                quantity:  nil
              }
            end
            let(:expected_attributes) do
              {
                'name'        => 'Self-sealing Stem Bolt',
                'description' => nil,
                'quantity'    => 0
              }
            end
            let(:expected_properties) do
              expected_attributes.merge(
                'amplitude' => '1.21 GW',
                'frequency' => nil
              )
            end

            it 'should not raise an exception' do
              expect { entity.properties = values }.not_to raise_error
            end

            it 'should call the writer methods', :aggregate_failures do
              allow(entity).to receive(:name=)
              allow(entity).to receive(:quantity=)

              entity.properties = values

              expect(entity)
                .to have_received(:name=)
                .with('Self-sealing Stem Bolt')
              expect(entity)
                .to have_received(:quantity=)
                .with(0)
            end

            it 'should change the entity attributes' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :attributes)
                .to be == expected_attributes
            end

            it 'should change the entity properties' do
              expect { rescue_exception { entity.properties = values } }
                .to change(entity, :properties)
                .to be == expected_properties
            end
          end

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            describe 'with empty properties' do
              let(:values) { {} }
              let(:expected_attributes) do
                {
                  'description' => nil,
                  'name'        => nil,
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => nil,
                  'frequency' => nil
                )
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should clear the entity attributes' do
                expect { entity.properties = values }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should clear the entity properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid String keys' do
              let(:values) do
                {
                  'amplitude' => '1.21 GW',
                  'name'      => 'Self-sealing Stem Bolt',
                  'quantity'  => nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Self-sealing Stem Bolt',
                  'description' => nil,
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => '1.21 GW',
                  'frequency' => nil
                )
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  amplitude: '1.21 GW',
                  name:      'Self-sealing Stem Bolt',
                  quantity:  nil
                }
              end
              let(:expected_attributes) do
                {
                  'name'        => 'Self-sealing Stem Bolt',
                  'description' => nil,
                  'quantity'    => 0
                }
              end
              let(:expected_properties) do
                expected_attributes.merge(
                  'amplitude' => '1.21 GW',
                  'frequency' => nil
                )
              end

              it 'should not raise an exception' do
                expect { entity.properties = values }.not_to raise_error
              end

              it 'should change the entity attributes' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :attributes)
                  .to be == expected_attributes
              end

              it 'should change the entity properties' do
                expect { rescue_exception { entity.properties = values } }
                  .to change(entity, :properties)
                  .to be == expected_properties
              end
            end
          end
        end
      end

      describe '#to_h' do
        wrap_context 'when the entity class defines attributes' do
          let(:expected) do
            {
              'description' => nil,
              'name'        => nil,
              'quantity'    => 0
            }
          end

          it { expect(entity.to_h).to be == expected }

          wrap_context 'when the entity has attribute values' do
            it { expect(entity.to_h).to be == attributes }
          end
        end

        context 'when the entity class defines properties' do
          include_context 'when the entity class defines attributes'
          include_context 'when the entity class defines properties'

          let(:expected) do
            {
              'description' => nil,
              'name'        => nil,
              'quantity'    => 0,
              'amplitude'   => nil,
              'frequency'   => nil
            }
          end

          it { expect(entity.to_h).to be == expected }

          context 'when the entity has attribute values' do
            include_context 'when the entity has attribute values'
            include_context 'when the entity has property values'

            let(:properties) { generic_properties.merge(attributes) }

            it { expect(entity.to_h).to be == properties }
          end
        end
      end
    end
  end
end
