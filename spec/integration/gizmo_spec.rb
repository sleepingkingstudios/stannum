# frozen_string_literal: true

require 'support/structs/gizmo'

# @note Integration spec for a subclassed Stannum::Struct.
RSpec.describe Spec::Gizmo do
  shared_context 'when initialized with attribute values' do
    let(:attributes) do
      {
        name:        'Self-Sealing Stem Bolt',
        description: 'No one is sure what a self-sealing stem bolt is.',
        quantity:    1_000,
        size:        'Small'
      }
    end
  end

  subject(:gadget) { described_class.new(attributes) }

  let(:attributes) { {} }

  def tools
    SleepingKingStudios::Tools::Toolbelt.instance
  end

  describe '.attributes' do
    it 'should define the class method' do
      expect(described_class.attributes).to be_a Stannum::Schema
    end

    describe '.[]' do
      it 'should return the attribute' do
        expect(described_class.attributes[:name])
          .to be_a(Stannum::Attribute)
          .and(
            have_attributes(
              name:    'name',
              options: { required: true },
              type:    'String'
            )
          )
      end
    end

    describe '.each' do
      let(:expected_keys) { %w[name description quantity size] }
      let(:expected_values) do
        [
          {
            name:    'name',
            type:    'String',
            options: { required: true }
          },
          {
            name:    'description',
            type:    'String',
            options: { required: false }
          },
          {
            name:    'quantity',
            type:    'Integer',
            options: { default: 0, required: true }
          },
          {
            name:    'size',
            type:    'String',
            options: { required: true }
          }
        ].map do |attributes|
          an_instance_of(Stannum::Attribute).and(
            have_attributes(attributes)
          )
        end
      end

      it { expect(described_class.attributes.each).to be_a Enumerator }

      it { expect(described_class.attributes.each.size).to be 4 }

      it 'should yield the attributes' do
        expect { |block| described_class.attributes.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end
  end

  describe '.contract' do
    let(:contract) { described_class.contract }

    it { expect(contract).to be_a Stannum::Contract }

    describe 'with an empty struct' do
      let(:expected_errors) do
        [
          {
            data:    { required: true, type: String },
            message: nil,
            path:    [:name],
            type:    'stannum.constraints.is_not_type'
          },
          {
            data:    { required: true, type: String },
            message: nil,
            path:    [:size],
            type:    'stannum.constraints.is_not_type'
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    'stannum.constraints.invalid'
          },
          {
            data:    {},
            message: nil,
            path:    [:size],
            type:    'stannum.constraints.invalid'
          }
        ]
      end

      it { expect(contract.errors_for(gadget)).to be == expected_errors }

      it { expect(contract.matches?(gadget)).to be false }
    end

    describe 'with a struct with invalid attributes' do
      let(:attributes) do
        {
          name:        'Self-Sealing Stem Bolt',
          description: :invalid_description,
          quantity:    -10,
          size:        'Lilliputian'
        }
      end
      let(:expected_errors) do
        [
          {
            data:    { required: false, type: String },
            message: nil,
            path:    [:description],
            type:    'stannum.constraints.is_not_type'
          },
          {
            data:    {},
            message: nil,
            path:    [],
            type:    'stannum.constraints.invalid'
          },
          {
            data:    {},
            message: nil,
            path:    [:quantity],
            type:    'stannum.constraints.invalid'
          },
          {
            data:    {},
            message: nil,
            path:    [:size],
            type:    'stannum.constraints.invalid'
          }
        ]
      end

      it { expect(contract.errors_for(gadget)).to be == expected_errors }

      it { expect(contract.matches?(gadget)).to be false }
    end

    describe 'with a struct with valid attributes' do
      let(:attributes) do
        {
          name:        'Self-Sealing Stem Bolt',
          description: 'No one is sure what a self-sealing stem bolt is.',
          quantity:    0,
          size:        'Small'
        }
      end

      it { expect(contract.errors_for(gadget)).to be == [] }

      it { expect(contract.matches?(gadget)).to be true }
    end
  end

  describe '#[]' do
    it { expect(gadget).to respond_to(:[]).with(1).argument }

    describe 'with a string key' do
      it { expect(gadget['size']).to be nil }
    end

    describe 'with a symbol key' do
      it { expect(gadget[:size]).to be nil }
    end

    describe 'with a string key for a parent attribute' do
      it { expect(gadget['name']).to be nil }
    end

    describe 'with a symbol key for a parent attribute' do
      it { expect(gadget[:name]).to be nil }
    end

    wrap_context 'when initialized with attribute values' do
      describe 'with a string key' do
        it { expect(gadget['size']).to be == attributes[:size] }
      end

      describe 'with a symbol key' do
        it { expect(gadget[:size]).to be == attributes[:size] }
      end

      describe 'with a string key for a parent attributes' do
        it { expect(gadget['name']).to be == attributes[:name] }
      end

      describe 'with a symbol key for a parent attribute' do
        it { expect(gadget[:name]).to be == attributes[:name] }
      end
    end

    context 'when the attribute has a default value' do
      describe 'with a string key' do
        it { expect(gadget['quantity']).to be 0 }
      end

      describe 'with a symbol key' do
        it { expect(gadget[:quantity]).to be 0 }
      end

      wrap_context 'when initialized with attribute values' do
        describe 'with a string key' do
          it { expect(gadget['quantity']).to be == attributes[:quantity] }
        end

        describe 'with a symbol key' do
          it { expect(gadget[:quantity]).to be == attributes[:quantity] }
        end
      end
    end
  end

  describe '#[]=' do
    let(:value) { 'Colossal' }

    it { expect(gadget).to respond_to(:[]=).with(2).arguments }

    describe 'with a string key' do
      it 'should update the value' do
        expect { gadget['size'] = value }
          .to change(gadget, :size)
          .to be == value
      end
    end

    describe 'with a symbol key' do
      it 'should update the value' do
        expect { gadget[:size] = value }
          .to change(gadget, :size)
          .to be == value
      end
    end

    describe 'with a string key for a parent attribute' do
      let(:value) { 'Inverse Chronoton Emitter' }

      it 'should update the value' do
        expect { gadget['name'] = value }
          .to change(gadget, :name)
          .to be == value
      end
    end

    describe 'with a symbol key for a parent attribute' do
      let(:value) { 'Inverse Chronoton Emitter' }

      it 'should update the value' do
        expect { gadget[:name] = value }
          .to change(gadget, :name)
          .to be == value
      end
    end

    wrap_context 'when initialized with attribute values' do
      describe 'with a string key' do
        it 'should update the value' do
          expect { gadget['size'] = value }
            .to change(gadget, :size)
            .to be == value
        end
      end

      describe 'with a symbol key' do
        it 'should update the value' do
          expect { gadget[:size] = value }
            .to change(gadget, :size)
            .to be == value
        end
      end

      describe 'with a string key for a parent attribute' do
        let(:value) { 'Inverse Chronoton Emitter' }

        it 'should update the value' do
          expect { gadget['name'] = value }
            .to change(gadget, :name)
            .to be == value
        end
      end

      describe 'with a symbol key for a parent attribute' do
        let(:value) { 'Inverse Chronoton Emitter' }

        it 'should update the value' do
          expect { gadget[:name] = value }
            .to change(gadget, :name)
            .to be == value
        end
      end
    end

    context 'when the attribute has a default value' do
      let(:value) { 100 }

      describe 'with a nil value' do
        it 'should not change the value' do
          expect { gadget[:quantity] = nil }.not_to change(gadget, :quantity)
        end
      end

      describe 'with a string key' do
        it 'should update the value' do
          expect { gadget['quantity'] = value }
            .to change(gadget, :quantity)
            .to be == value
        end
      end

      describe 'with a symbol key' do
        it 'should update the value' do
          expect { gadget[:quantity] = value }
            .to change(gadget, :quantity)
            .to be == value
        end
      end

      wrap_context 'when initialized with attribute values' do
        describe 'with a nil value' do
          it 'should reset the value' do
            expect { gadget[:quantity] = nil }
              .to change(gadget, :quantity)
              .to be 0
          end
        end

        describe 'with a string key' do
          it 'should update the value' do
            expect { gadget['quantity'] = value }
              .to change(gadget, :quantity)
              .to be == value
          end
        end

        describe 'with a symbol key' do
          it 'should update the value' do
            expect { gadget[:quantity] = value }
              .to change(gadget, :quantity)
              .to be == value
          end
        end
      end
    end
  end

  describe '#assign_attributes' do
    let(:description) do
      'A self-sealing stem bolt is the entrepreneurial opportunity of a' \
      ' lifetime.'
    end
    let(:expected) do
      {
        'name'        => nil,
        'description' => description,
        'quantity'    => 0,
        'size'        => nil
      }
    end

    it { expect(gadget).to respond_to(:assign_attributes).with(1).argument }

    it 'should update the included values' do
      expect { gadget.assign_attributes(description: description) }
        .to change(gadget, :attributes)
        .to be == expected
    end

    wrap_context 'when initialized with attribute values' do
      let(:expected) do
        tools
          .hash_tools
          .convert_keys_to_strings(attributes)
          .merge('description' => description)
      end

      it 'should update the included values' do
        expect { gadget.assign_attributes(description: description) }
          .to change(gadget, :attributes)
          .to be == expected
      end
    end
  end

  describe '#attributes' do
    let(:expected) do
      {
        'name'        => nil,
        'description' => nil,
        'quantity'    => 0,
        'size'        => nil
      }
    end

    it { expect(gadget).to respond_to(:attributes).with(0).arguments }

    it { expect(gadget.attributes).to be == expected }

    wrap_context 'when initialized with attribute values' do
      let(:expected) { tools.hash_tools.convert_keys_to_strings(attributes) }

      it { expect(gadget.attributes).to be == expected }
    end
  end

  describe '#attributes=' do
    let(:description) do
      'A self-sealing stem bolt is the entrepreneurial opportunity of a' \
      ' lifetime.'
    end
    let(:hsh) { { description: description, quantity: nil } }
    let(:expected) do
      {
        'name'        => nil,
        'description' => description,
        'quantity'    => 0,
        'size'        => nil
      }
    end

    it { expect(gadget).to respond_to(:attributes=).with(1).argument }

    it 'should set the attributes' do
      expect { gadget.attributes = hsh }
        .to change(gadget, :attributes)
        .to be == expected
    end

    wrap_context 'when initialized with attribute values' do
      it 'should set the attributes' do
        expect { gadget.attributes = hsh }
          .to change(gadget, :attributes)
          .to be == expected
      end
    end
  end

  describe '#description' do
    include_examples 'should have reader', :description, nil

    wrap_context 'when initialized with attribute values' do
      it 'should return the value' do
        expect(gadget.description)
          .to be == 'No one is sure what a self-sealing stem bolt is.'
      end
    end
  end

  describe '#description=' do
    let(:value) do
      'A self-sealing stem bolt is the entrepreneurial opportunity of a' \
      ' lifetime.'
    end

    include_examples 'should have writer', :description=

    it 'should update the description' do
      expect { gadget.description = value }
        .to change(gadget, :description)
        .to be == value
    end

    wrap_context 'when initialized with attribute values' do
      it 'should update the description' do
        expect { gadget.description = value }
          .to change(gadget, :description)
          .to be == value
      end
    end
  end

  describe '#name' do
    include_examples 'should have reader', :name, nil

    wrap_context 'when initialized with attribute values' do
      it { expect(gadget.name).to be == 'Self-Sealing Stem Bolt' }
    end
  end

  describe '#name=' do
    let(:value) { 'Inverse Chronoton Emitter' }

    include_examples 'should have writer', :name=

    it 'should update the value' do
      expect { gadget.name = value }
        .to change(gadget, :name)
        .to be == value
    end

    wrap_context 'when initialized with attribute values' do
      it 'should update the value' do
        expect { gadget.name = value }
          .to change(gadget, :name)
          .to be == value
      end
    end
  end

  describe '#quantity' do
    include_examples 'should have reader', :quantity, 0

    wrap_context 'when initialized with attribute values' do
      it { expect(gadget.quantity).to be == 1_000 }
    end
  end

  describe '#quantity=' do
    include_examples 'should have writer', :quantity=

    describe 'with nil' do
      it { expect { gadget.quantity = nil }.not_to change(gadget, :quantity) }
    end

    describe 'with a value' do
      it 'should update the value' do
        expect { gadget.quantity = 100 }
          .to change(gadget, :quantity)
          .to be 100
      end
    end

    wrap_context 'when initialized with attribute values' do
      describe 'with nil' do
        it 'should reset the value' do
          expect { gadget.quantity = nil }
            .to change(gadget, :quantity)
            .to be 0
        end
      end

      describe 'with a value' do
        it 'should update the value' do
          expect { gadget.quantity = 100 }
            .to change(gadget, :quantity)
            .to be 100
        end
      end
    end
  end

  describe '#size' do
    include_examples 'should have reader', :size

    wrap_context 'when initialized with attribute values' do
      it { expect(gadget.size).to be == 'Small' }
    end
  end

  describe '#size=' do
    let(:value) { 'Colossal' }

    include_examples 'should have writer', :size=

    it 'should update the value' do
      expect { gadget.size = value }
        .to change(gadget, :size)
        .to be == value
    end

    wrap_context 'when initialized with attribute values' do
      it 'should update the value' do
        expect { gadget.size = value }
          .to change(gadget, :size)
          .to be == value
      end
    end
  end
end
