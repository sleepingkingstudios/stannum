# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/entities/generic_properties'
require 'support/examples/entities'
require 'support/examples/entity_examples'

module Spec::Support::Examples::Entities
  module PropertiesExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    include Spec::Support::Examples::EntityExamples

    shared_context 'when the entity class defines properties' do
      before(:example) do
        entity_class.include(Spec::Support::Entities::GenericProperties)
      end
    end

    shared_context 'when the entity has property values' do
      let(:properties) do
        {
          'amplitude' => '1 TW',
          'frequency' => '1 Hz'
        }
      end
    end

    shared_examples 'should implement the Properties methods' do
      describe '.new' do
        it 'should define the constructor' do
          expect(described_class)
            .to be_constructible
            .with(0).arguments
            .and_any_keywords
        end

        describe 'with empty properties' do
          let(:properties) { {} }

          it { expect { described_class.new(**properties) }.not_to raise_error }

          it 'should not set the entity properties' do
            expect(described_class.new(**properties).properties).to be == {}
          end
        end

        describe 'with invalid String keys' do
          let(:properties)    { super().merge('phase_angle' => 'π') }
          let(:error_message) { 'unknown property "phase_angle"' }

          it 'should raise an exception' do
            expect { described_class.new(**properties) }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with invalid Symbol keys' do
          let(:properties)    { super().merge(phase_angle: 'π') }
          let(:error_message) { 'unknown property :phase_angle' }

          it 'should raise an exception' do
            expect { described_class.new(**properties) }
              .to raise_error ArgumentError, error_message
          end
        end

        wrap_context 'when the entity class defines properties' do
          describe 'with invalid String keys' do
            let(:properties)    { super().merge('phase_angle' => 'π') }
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with invalid Symbol keys' do
            let(:properties)    { super().merge(phase_angle: 'π') }
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:properties) do
              {
                'amplitude'   => '1 TW',
                'frequency'   => '1 Hz',
                'phase_angle' => 'π'
              }
            end
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:properties) do
              {
                amplitude:   '1 TW',
                frequency:   '1 Hz',
                phase_angle: 'π'
              }
            end
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { described_class.new(**properties) }
                .to raise_error ArgumentError, error_message
            end
          end

          describe 'with valid String keys' do
            let(:properties) do
              {
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it { expect(entity.properties).to be == properties }
          end

          describe 'with valid Symbol keys' do
            let(:properties) do
              {
                amplitude: '1 TW',
                frequency: '1 Hz'
              }
            end
            let(:expected) do
              {
                'amplitude' => '1 TW',
                'frequency' => '1 Hz'
              }
            end

            it 'should not raise an exception' do
              expect { described_class.new(**properties) }.not_to raise_error
            end

            it { expect(entity.properties).to be == expected }
          end
        end
      end

      describe '#==' do
        describe 'with nil' do
          it { expect(entity == nil).to be false } # rubocop:disable Style/NilComparison
        end

        describe 'with an Object' do
          it { expect(entity == Object.new.freeze).to be false }
        end

        describe 'with an attributes hash' do
          it { expect(entity == {}).to be false }
        end

        describe 'with an entity' do
          let(:other) { described_class.new }

          it { expect(entity == other).to be true }
        end

        wrap_context 'with an entity subclass' do
          let(:other) { entity_class.new }

          it { expect(entity == other).to be false }
        end

        describe 'with another entity class' do
          let(:other) { Spec::OtherEntityClass.new }

          example_class 'Spec::OtherEntityClass' do |klass|
            self.class.define_entity(klass)
          end

          it { expect(entity == other).to be false }
        end

        describe 'with an entity with non-matching properties' do
          let(:other_properties) { { 'key' => 'value' } }
          let(:other) do
            described_class.new.tap do |obj|
              allow(obj).to receive(:properties).and_return(other_properties)
            end
          end

          it { expect(entity == other).to be false }
        end

        wrap_context 'when the entity class defines properties' do
          describe 'with an entity with matching properties' do
            let(:other) { described_class.new }

            it { expect(entity == other).to be true }
          end

          describe 'with an entity with non-matching properties' do
            let(:other_properties) do
              { 'amplitude' => '1.21 GW' }
            end
            let(:other) { described_class.new(**other_properties) }

            it { expect(entity == other).to be false }
          end

          wrap_context 'when the entity has property values' do
            describe 'with an entity with matching properties' do
              let(:other) { described_class.new(**properties) }

              it { expect(entity == other).to be true }
            end

            describe 'with an entity with non-matching properties' do
              let(:other_properties) do
                properties.merge('amplitude' => '1.21 GW')
              end
              let(:other) { described_class.new(**other_properties) }

              it { expect(entity == other).to be false }
            end
          end
        end
      end

      describe '#[]' do
        it { expect(entity).to respond_to(:[]).with(1).argument }

        describe 'with nil' do
          let(:error_message) { "key can't be blank" }

          it 'should raise an exception' do
            expect { entity[nil] }
              .to raise_error(ArgumentError, error_message)
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'key is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity[Object.new.freeze] }
              .to raise_error(ArgumentError, error_message)
          end
        end

        describe 'with an empty String' do
          let(:error_message) { "key can't be blank" }

          it 'should raise an exception' do
            expect { entity[''] }
              .to raise_error(ArgumentError, error_message)
          end
        end

        describe 'with an empty Symbol' do
          let(:error_message) { "key can't be blank" }

          it 'should raise an exception' do
            expect { entity[:''] }
              .to raise_error(ArgumentError, error_message)
          end
        end

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

        wrap_context 'when the entity class defines properties' do
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
            it { expect(entity['amplitude']).to be nil }
          end

          describe 'with a valid Symbol' do
            it { expect(entity[:amplitude]).to be nil }
          end

          wrap_context 'when the entity has property values' do
            describe 'with a valid String' do
              it { expect(entity['amplitude']).to be == '1 TW' }
            end

            describe 'with a valid Symbol' do
              it { expect(entity[:amplitude]).to be == '1 TW' }
            end
          end
        end
      end

      describe '#[]=' do
        it { expect(entity).to respond_to(:[]=).with(2).arguments }

        describe 'with nil' do
          let(:error_message) { "key can't be blank" }

          it 'should raise an exception' do
            expect { entity[nil] = 'value' }
              .to raise_error(ArgumentError, error_message)
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'key is not a String or a Symbol' }

          it 'should raise an exception' do
            expect { entity[Object.new.freeze] = 'value' }
              .to raise_error(ArgumentError, error_message)
          end
        end

        describe 'with an empty String' do
          let(:error_message) { "key can't be blank" }

          it 'should raise an exception' do
            expect { entity[''] = 'value' }
              .to raise_error(ArgumentError, error_message)
          end
        end

        describe 'with an empty Symbol' do
          let(:error_message) { "key can't be blank" }

          it 'should raise an exception' do
            expect { entity[:''] = 'value' }
              .to raise_error(ArgumentError, error_message)
          end
        end

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

        wrap_context 'when the entity class defines properties' do
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
            it 'should change the property value' do
              expect { entity['amplitude'] = '2 TW' }
                .to change { entity['amplitude'] }
                .to be == '2 TW'
            end
          end

          describe 'with a valid Symbol' do
            it 'should change the property value' do
              expect { entity[:amplitude] = '2 TW' }
                .to change { entity['amplitude'] }
                .to be == '2 TW'
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

        it { expect(entity).to respond_to(:assign_properties).with(1).argument }

        it 'should alias the method' do
          expect(entity).to have_aliased_method(:assign_properties).as(:assign)
        end

        describe 'with nil' do
          let(:error_message) { 'properties must be a Hash' }

          it 'should raise an exception' do
            expect { entity.assign_properties nil }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'properties must be a Hash' }

          it 'should raise an exception' do
            expect { entity.assign_properties Object.new.freeze }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with empty properties' do
          let(:values) { {} }

          it { expect { entity.assign_properties(values) }.not_to raise_error }

          it 'should not change the entity properties' do
            expect { entity.assign_properties(values) }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid String keys' do
          let(:values)        { { 'phase_angle' => 'π' } }
          let(:error_message) { 'unknown property "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.assign_properties(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the properties' do
            expect { rescue_exception { entity.assign_properties(values) } }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid Symbol keys' do
          let(:values)        { { phase_angle: 'π' } }
          let(:error_message) { 'unknown property :phase_angle' }

          it 'should raise an exception' do
            expect { entity.assign_properties(values) }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the properties' do
            expect { rescue_exception { entity.assign_properties(values) } }
              .not_to change(entity, :properties)
          end
        end

        wrap_context 'when the entity class defines properties' do
          describe 'with invalid String keys' do
            let(:values)        { { 'phase_angle' => 'π' } }
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { phase_angle: 'π' } }
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'amplitude'   => '1 TW',
                'frequency'   => '1 Hz',
                'phase_angle' => 'π'
              }
            end
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                amplitude:   '1 TW',
                frequency:   '1 Hz',
                phase_angle: 'π'
              }
            end
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity.assign_properties(values) }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.assign_properties(values) } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'amplitude' => '1 TW'
              }
            end
            let(:expected) do
              {
                'amplitude' => '1 TW',
                'frequency' => properties['frequency']
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should change the properties' do
              expect { entity.assign_properties(values) }
                .to change(entity, :properties)
                .to be == expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                amplitude: '1 TW'
              }
            end
            let(:expected) do
              {
                'amplitude' => '1 TW',
                'frequency' => properties['frequency']
              }
            end

            it 'should not raise an exception' do
              expect { entity.assign_properties(values) }.not_to raise_error
            end

            it 'should change the properties' do
              expect { entity.assign_properties(values) }
                .to change(entity, :properties)
                .to be == expected
            end
          end

          wrap_context 'when the entity has property values' do
            describe 'with valid String keys' do
              let(:values) do
                {
                  'amplitude' => '1.21 GW'
                }
              end
              let(:expected) do
                {
                  'amplitude' => '1.21 GW',
                  'frequency' => properties['frequency']
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should change the properties' do
                expect { entity.assign_properties(values) }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  amplitude: '1.21 GW'
                }
              end
              let(:expected) do
                {
                  'amplitude' => '1.21 GW',
                  'frequency' => properties['frequency']
                }
              end

              it 'should not raise an exception' do
                expect { entity.assign_properties(values) }.not_to raise_error
              end

              it 'should change the properties' do
                expect { entity.assign_properties(values) }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end
          end
        end
      end

      describe '#inspect' do
        let(:expected) { "#<#{described_class.name}>" }

        it { expect(entity).to respond_to(:inspect).with(0).arguments }

        it { expect(entity.inspect).to be == expected }

        wrap_context 'when the entity class defines properties' do
          let(:expected) do
            "#<#{described_class.name} amplitude: nil frequency: nil>"
          end

          it { expect(entity.inspect).to be == expected }

          wrap_context 'when the entity has property values' do
            let(:expected) do
              %(#<#{described_class.name} amplitude: "1 TW" frequency: "1 Hz">)
            end

            it { expect(entity.inspect).to be == expected }
          end
        end
      end

      describe '#properties' do
        include_examples 'should define reader', :properties, {}

        wrap_context 'when the entity class defines properties' do
          let(:expected) do
            {
              'amplitude' => nil,
              'frequency' => nil
            }
          end

          it { expect(entity.properties).to be == expected }

          wrap_context 'when the entity has property values' do
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

        include_examples 'should define writer', :properties=

        describe 'with nil' do
          let(:error_message) { 'properties must be a Hash' }

          it 'should raise an exception' do
            expect { entity.properties = nil }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with an Object' do
          let(:error_message) { 'properties must be a Hash' }

          it 'should raise an exception' do
            expect { entity.properties = Object.new.freeze }
              .to raise_error ArgumentError, error_message
          end
        end

        describe 'with empty properties' do
          let(:values) { {} }

          it { expect { entity.properties = values }.not_to raise_error }

          it 'should not change the entity properties' do
            expect { entity.properties = values }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid String keys' do
          let(:values)        { { 'phase_angle' => 'π' } }
          let(:error_message) { 'unknown property "phase_angle"' }

          it 'should raise an exception' do
            expect { entity.properties = values }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the properties' do
            expect { rescue_exception { entity.properties = values } }
              .not_to change(entity, :properties)
          end
        end

        describe 'with invalid Symbol keys' do
          let(:values)        { { phase_angle: 'π' } }
          let(:error_message) { 'unknown property :phase_angle' }

          it 'should raise an exception' do
            expect { entity.properties = values }
              .to raise_error ArgumentError, error_message
          end

          it 'should not change the properties' do
            expect { rescue_exception { entity.properties = values } }
              .not_to change(entity, :properties)
          end
        end

        wrap_context 'when the entity class defines properties' do
          describe 'with invalid String keys' do
            let(:values)        { { 'phase_angle' => 'π' } }
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with invalid Symbol keys' do
            let(:values)        { { phase_angle: 'π' } }
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid String keys' do
            let(:values) do
              {
                'amplitude'   => '1 TW',
                'frequency'   => '1 Hz',
                'phase_angle' => 'π'
              }
            end
            let(:error_message) { 'unknown property "phase_angle"' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with mixed valid and invalid Symbol keys' do
            let(:values) do
              {
                amplitude:   '1 TW',
                frequency:   '1 Hz',
                phase_angle: 'π'
              }
            end
            let(:error_message) { 'unknown property :phase_angle' }

            it 'should raise an exception' do
              expect { entity.properties = values }
                .to raise_error ArgumentError, error_message
            end

            it 'should not change the properties' do
              expect { rescue_exception { entity.properties = values } }
                .not_to change(entity, :properties)
            end
          end

          describe 'with valid String keys' do
            let(:values) do
              {
                'amplitude' => '1 TW'
              }
            end
            let(:expected) do
              {
                'amplitude' => '1 TW',
                'frequency' => nil
              }
            end

            it { expect { entity.properties = values }.not_to raise_error }

            it 'should change the properties' do
              expect { entity.properties = values }
                .to change(entity, :properties)
                .to be == expected
            end
          end

          describe 'with valid Symbol keys' do
            let(:values) do
              {
                amplitude: '1 TW'
              }
            end
            let(:expected) do
              {
                'amplitude' => '1 TW',
                'frequency' => nil
              }
            end

            it { expect { entity.properties = values }.not_to raise_error }

            it 'should change the properties' do
              expect { entity.properties = values }
                .to change(entity, :properties)
                .to be == expected
            end
          end

          wrap_context 'when the entity has property values' do
            describe 'with valid String keys' do
              let(:values) do
                {
                  'amplitude' => '1 TW'
                }
              end
              let(:expected) do
                {
                  'amplitude' => '1 TW',
                  'frequency' => nil
                }
              end

              it { expect { entity.properties = values }.not_to raise_error }

              it 'should change the properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end

            describe 'with valid Symbol keys' do
              let(:values) do
                {
                  amplitude: '1 TW'
                }
              end
              let(:expected) do
                {
                  'amplitude' => '1 TW',
                  'frequency' => nil
                }
              end

              it { expect { entity.properties = values }.not_to raise_error }

              it 'should change the properties' do
                expect { entity.properties = values }
                  .to change(entity, :properties)
                  .to be == expected
              end
            end
          end
        end
      end
    end
  end
end
