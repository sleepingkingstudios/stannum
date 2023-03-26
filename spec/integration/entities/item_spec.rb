# frozen_string_literal: true

require 'support/entities/item'

# @note Integration spec for Stannum::Entity with string primary key.
RSpec.describe Spec::Item do
  shared_context 'when initialized with attribute values' do
    let(:attributes) do
      {
        uuid:  '00000000-0000-0000-0000-000000000000',
        name:  'Philter of Filtering',
        price: 10_000
      }
    end
  end

  subject(:item) { described_class.new(**attributes) }

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
      let(:expected_keys) { %w[uuid name price] }
      let(:expected_values) do
        [
          {
            name:    'uuid',
            type:    'String',
            options: { primary_key: true, required: true }
          },
          {
            name:    'name',
            type:    'String',
            options: { required: true }
          },
          {
            name:    'price',
            type:    'Integer',
            options: { required: false }
          }
        ].map do |attributes|
          an_instance_of(Stannum::Attribute).and(
            have_attributes(attributes)
          )
        end
      end

      it { expect(described_class.attributes.each).to be_a Enumerator }

      it { expect(described_class.attributes.each.size).to be 3 }

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
            path:    [:uuid],
            type:    'stannum.constraints.is_not_type'
          },
          {
            data:    {},
            message: nil,
            path:    [:uuid],
            type:    'stannum.constraints.invalid'
          },
          {
            data:    { required: true, type: String },
            message: nil,
            path:    [:name],
            type:    'stannum.constraints.is_not_type'
          }
        ]
      end

      it { expect(contract.errors_for(item)).to be == expected_errors }

      it { expect(contract.matches?(item)).to be false }
    end

    describe 'with a struct with invalid attributes' do
      let(:attributes) do
        {
          uuid: 'nope',
          name: nil
        }
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [:uuid],
            type:    'stannum.constraints.invalid'
          },
          {
            data:    { required: true, type: String },
            message: nil,
            path:    [:name],
            type:    'stannum.constraints.is_not_type'
          }
        ]
      end

      it { expect(contract.errors_for(item)).to be == expected_errors }

      it { expect(contract.matches?(item)).to be false }
    end

    describe 'with a struct with valid attributes' do
      let(:attributes) do
        {
          uuid:  '00000000-0000-0000-0000-000000000000',
          name:  'Philter of Filtering',
          price: 10_000
        }
      end

      it { expect(contract.errors_for(item)).to be == [] }

      it { expect(contract.matches?(item)).to be true }
    end
  end

  describe '#[]' do
    it { expect(item).to respond_to(:[]).with(1).argument }

    describe 'with a string key' do
      it { expect(item['name']).to be nil }
    end

    describe 'with a symbol key' do
      it { expect(item[:name]).to be nil }
    end

    wrap_context 'when initialized with attribute values' do
      describe 'with a string key' do
        it { expect(item['name']).to be == attributes[:name] }
      end

      describe 'with a symbol key' do
        it { expect(item[:name]).to be == attributes[:name] }
      end
    end
  end

  describe '#[]=' do
    let(:value) { 'Draught of Drafts' }

    it { expect(item).to respond_to(:[]=).with(2).arguments }

    describe 'with a string key' do
      it 'should update the value' do
        expect { item['name'] = value }
          .to change(item, :name)
          .to be == value
      end
    end

    describe 'with a symbol key' do
      it 'should update the value' do
        expect { item[:name] = value }
          .to change(item, :name)
          .to be == value
      end
    end

    wrap_context 'when initialized with attribute values' do
      describe 'with a string key' do
        it 'should update the value' do
          expect { item['name'] = value }
            .to change(item, :name)
            .to be == value
        end
      end

      describe 'with a symbol key' do
        it 'should update the value' do
          expect { item[:name] = value }
            .to change(item, :name)
            .to be == value
        end
      end
    end
  end

  describe '#assign_attributes' do
    let(:price) { 100_000 }
    let(:expected) do
      {
        'uuid'  => nil,
        'name'  => nil,
        'price' => price
      }
    end

    it { expect(item).to respond_to(:assign_attributes).with(1).argument }

    it 'should update the included values' do
      expect { item.assign_attributes(price: price) }
        .to change(item, :attributes)
        .to be == expected
    end

    wrap_context 'when initialized with attribute values' do
      let(:expected) do
        tools
          .hash_tools
          .convert_keys_to_strings(attributes)
          .merge('price' => price)
      end

      it 'should update the included values' do
        expect { item.assign_attributes(price: price) }
          .to change(item, :attributes)
          .to be == expected
      end
    end
  end

  describe '#attributes' do
    let(:expected) do
      {
        'uuid'  => nil,
        'name'  => nil,
        'price' => nil
      }
    end

    it { expect(item).to respond_to(:attributes).with(0).arguments }

    it { expect(item.attributes).to be == expected }

    wrap_context 'when initialized with attribute values' do
      let(:expected) { tools.hash_tools.convert_keys_to_strings(attributes) }

      it { expect(item.attributes).to be == expected }
    end
  end

  describe '#attributes=' do
    let(:price) { 100_000 }
    let(:hsh)   { { price: price } }
    let(:expected) do
      {
        'uuid'  => nil,
        'name'  => nil,
        'price' => price
      }
    end

    it { expect(item).to respond_to(:attributes=).with(1).argument }

    it 'should set the attributes' do
      expect { item.attributes = hsh }
        .to change(item, :attributes)
        .to be == expected
    end

    wrap_context 'when initialized with attribute values' do
      it 'should set the attributes' do
        expect { item.attributes = hsh }
          .to change(item, :attributes)
          .to be == expected
      end
    end
  end

  describe '#name' do
    include_examples 'should have reader', :name, nil

    wrap_context 'when initialized with attribute values' do
      it { expect(item.name).to be == 'Philter of Filtering' }
    end
  end

  describe '#name=' do
    let(:value) { 'Draught of Drafts' }

    include_examples 'should have writer', :name=

    it 'should update the value' do
      expect { item.name = value }
        .to change(item, :name)
        .to be == value
    end

    wrap_context 'when initialized with attribute values' do
      it 'should update the value' do
        expect { item.name = value }
          .to change(item, :name)
          .to be == value
      end
    end
  end

  describe '#price' do
    include_examples 'should have reader', :price, nil

    wrap_context 'when initialized with attribute values' do
      it { expect(item.price).to be == 10_000 }
    end
  end

  describe '#price=' do
    let(:value) { 100_000 }

    include_examples 'should have writer', :price=

    it 'should update the value' do
      expect { item.price = value }
        .to change(item, :price)
        .to be == value
    end

    wrap_context 'when initialized with attribute values' do
      it 'should update the value' do
        expect { item.price = value }
          .to change(item, :price)
          .to be == value
      end
    end
  end

  describe '#uuid' do
    include_examples 'should have reader', :uuid, nil

    wrap_context 'when initialized with attribute values' do
      it { expect(item.uuid).to be == '00000000-0000-0000-0000-000000000000' }
    end
  end

  describe '#uuid=' do
    let(:uuid) { '01234567-89ab-cdef-0123-456789abcdef' }

    include_examples 'should have writer', :uuid=

    it 'should update the value' do
      expect { item.uuid = uuid }
        .to change(item, :uuid)
        .to be == uuid
    end

    wrap_context 'when initialized with attribute values' do
      it 'should update the value' do
        expect { item.uuid = uuid }
          .to change(item, :uuid)
          .to be == uuid
      end
    end
  end
end
