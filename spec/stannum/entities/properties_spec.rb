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

  describe '#assign_properties' do
    def rescue_exception
      yield
    rescue ArgumentError
      # Do nothing.
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

        it { expect { entity.assign_properties(values) }.not_to raise_error }

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

        it { expect { entity.assign_properties(values) }.not_to raise_error }

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

          it { expect { entity.assign_properties(values) }.not_to raise_error }

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

          it { expect { entity.assign_properties(values) }.not_to raise_error }

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
