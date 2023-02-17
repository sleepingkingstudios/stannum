# frozen_string_literal: true

require 'stannum/entities/properties'

require 'support/examples/entities/properties_examples'

RSpec.describe Stannum::Entities::Properties do
  include Spec::Support::Examples::EntityExamples
  include Spec::Support::Examples::Entities::PropertiesExamples

  subject(:entity) { described_class.new(**properties) }

  shared_context 'when the entity class defines properties' do
    let(:described_class) { Spec::EntityClassWithProperties }

    example_class 'Spec::EntityClassWithProperties' do |klass|
      klass.include Stannum::Entities::Properties # rubocop:disable RSpec/DescribedClass

      klass.define_method(:initialize) do |**properties|
        @properties = {
          'amplitude' => nil,
          'frequency' => nil
        }

        super(**properties)
      end

      klass.attr_reader(:properties)

      klass.define_method(:get_property) do |key|
        properties.fetch(key.to_s) { super(key) }
      end

      klass.define_method(:inspectable_properties) do
        properties
      end

      klass.define_method(:set_property) do |key, value|
        super(key, value) unless properties.key?(key.to_s)

        properties[key.to_s] = value
      end

      klass.define_method(:set_properties) do |properties, force:|
        matching, non_matching = bisect_properties(properties, self.properties)

        super(non_matching)

        defaults = {
          'amplitude' => nil,
          'frequency' => nil
        }
        values = force ? defaults : self.properties

        @properties = values.merge(matching)
      end
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

  let(:properties) { {} }

  def self.define_entity(mod)
    mod.include Stannum::Entities::Properties # rubocop:disable RSpec/DescribedClass
  end

  def tools
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  include_examples 'should implement the Properties methods'

  describe '.new' do
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

        it { expect { described_class.new(**properties) }.not_to raise_error }

        it { expect(entity.properties).to be == properties }
      end

      describe 'with valid Symbol keys' do
        let(:properties) do
          {
            amplitude: '1 TW',
            frequency: '1 Hz'
          }
        end
        let(:expected) { tools.hsh.convert_keys_to_strings(properties) }

        it { expect { described_class.new(**properties) }.not_to raise_error }

        it { expect(entity.properties).to be == expected }
      end
    end
  end

  describe '#==' do
    wrap_context 'when the entity class defines properties' do
      describe 'with an entity with matching properties' do
        let(:other) { described_class.new }

        it { expect(entity == other).to be true }
      end

      describe 'with an entity with non-matching properties' do
        let(:other_properties) { { 'amplitude' => '1.21 GW' } }
        let(:other)            { described_class.new(**other_properties) }

        it { expect(entity == other).to be false }
      end

      wrap_context 'when the entity has property values' do
        describe 'with an entity with matching properties' do
          let(:other) { described_class.new(**properties) }

          it { expect(entity == other).to be true }
        end

        describe 'with an entity with non-matching properties' do
          let(:other_properties) { properties.merge('amplitude' => '1.21 GW') }
          let(:other)            { described_class.new(**other_properties) }

          it { expect(entity == other).to be false }
        end
      end
    end
  end

  describe '#[]' do
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
