# frozen_string_literal: true

require 'bigdecimal'

require 'stannum/structs/attributes'

RSpec.describe Stannum::Structs::Attributes do
  shared_context 'when there are many defined attributes' do
    let(:defined_attributes) do
      [
        {
          name:    'name',
          options: {},
          type:    'String'
        },
        {
          name:    'description',
          options: { required: false },
          type:    'String'
        },
        {
          name:    'quantity',
          options: { default: 0 },
          type:    'Integer'
        }
      ]
    end

    before(:example) do
      defined_attributes.each do |attribute|
        attributes.define_attribute(**attribute)
      end
    end
  end

  shared_context 'when parent attributes are included' do
    include_context 'when there are many defined attributes'

    let(:parent_defined_attributes) do
      [
        {
          name:    'size',
          options: {},
          type:    'String'
        }
      ]
    end
    let(:parent_attributes) do
      described_class.new.tap do |parent_attributes|
        if defined?(grandparent_attributes)
          parent_attributes.include(grandparent_attributes)
        end
      end
    end

    before(:example) do
      parent_defined_attributes.each do |attribute|
        parent_attributes.define_attribute(**attribute)
      end
    end
  end

  shared_context 'when grandparent attributes are included' do
    include_context 'when parent attributes are included'

    let(:grandparent_defined_attributes) do
      [
        {
          name:    'price',
          options: {},
          type:    'BigDecimal'
        }
      ]
    end
    let(:grandparent_attributes) { described_class.new }

    before(:example) do
      grandparent_defined_attributes.each do |attribute|
        grandparent_attributes.define_attribute(**attribute)
      end
    end
  end

  subject(:attributes) do
    described_class.new.tap do |attributes|
      attributes.include(parent_attributes) if defined?(parent_attributes)
    end
  end

  let(:struct) { Spec::BasicStruct.new }

  example_class 'Spec::BasicStruct' do |klass|
    klass.send(:define_method, :initialize) { @attributes = {} }

    klass.send(:attr_reader, :attributes)

    klass.const_set(:Attributes, attributes)

    klass.send(:include, attributes)
  end

  it { expect(attributes).to be_a Enumerable }

  describe '::Contract' do
    let(:constraints) { attributes::Contract.send(:constraints) }

    it 'should define the constant' do
      expect(attributes)
        .to define_constant(:Contract)
        .with_value(an_instance_of(Stannum::Contracts::LegacyHashContract))
    end

    it { expect(constraints.size).to be 0 }

    describe 'with an empty hash' do
      it { expect(attributes::Contract.errors_for({})).to be == [] }

      it { expect(attributes::Contract.matches?({})).to be true }
    end

    describe 'with a hash with extra keys' do
      let(:hsh) { { price: '9.99' } }
      let(:expected_errors) do
        [
          {
            data:    { keys: %i[price] },
            message: nil,
            path:    [],
            type:    'stannum.constraints.hash_with_extra_keys'
          }
        ]
      end

      it 'should return the errors' do
        expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
      end

      it { expect(attributes::Contract.matches?(hsh)).to be false }
    end

    wrap_context 'when there are many defined attributes' do
      it { expect(constraints.size).to be defined_attributes.size }

      it 'should define the constraints', :aggregate_failures do
        defined_attributes.each do |attribute|
          attr_name = attribute[:name].intern
          attr_type = Object.const_get(attribute[:type])

          expect(constraints).to include(
            constraint: an_instance_of(Stannum::Constraints::Type)
              .and(have_attributes expected_type: attr_type),
            property:   attr_name
          )
        end
      end

      describe 'with an empty hash' do
        let(:expected_errors) do
          [
            {
              data:    { type: String },
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:description],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: Integer },
              message: nil,
              path:    [:quantity],
              type:    'stannum.constraints.is_not_type'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for({})).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?({})).to be false }
      end

      describe 'with a partially matching hash' do
        let(:hsh) do
          { description: 'No one is quite sure what this does or why.' }
        end
        let(:expected_errors) do
          [
            {
              data:    { type: String },
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: Integer },
              message: nil,
              path:    [:quantity],
              type:    'stannum.constraints.is_not_type'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?(hsh)).to be false }
      end

      describe 'with a matching hash' do
        let(:hsh) do
          {
            name:        'Self-Sealing Stem Bolt',
            description: 'No one is quite sure what this does or why.',
            quantity:    10
          }
        end

        it { expect(attributes::Contract.errors_for(hsh)).to be == [] }

        it { expect(attributes::Contract.matches?(hsh)).to be true }
      end

      describe 'with a hash with extra keys' do
        let(:hsh) do
          {
            name:        'Self-Sealing Stem Bolt',
            description: 'No one is quite sure what this does or why.',
            quantity:    10,
            price:       '9.99'
          }
        end
        let(:expected_errors) do
          [
            {
              data:    { keys: %i[price] },
              message: nil,
              path:    [],
              type:    'stannum.constraints.hash_with_extra_keys'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?(hsh)).to be false }
      end
    end

    wrap_context 'when parent attributes are included' do
      describe 'with an empty hash' do
        let(:expected_errors) do
          [
            {
              data:    { type: String },
              message: nil,
              path:    [:size],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:description],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: Integer },
              message: nil,
              path:    [:quantity],
              type:    'stannum.constraints.is_not_type'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for({})).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?({})).to be false }
      end

      describe 'with a partially matching hash' do
        let(:hsh) do
          { description: 'No one is quite sure what this does or why.' }
        end
        let(:expected_errors) do
          [
            {
              data:    { type: String },
              message: nil,
              path:    [:size],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: Integer },
              message: nil,
              path:    [:quantity],
              type:    'stannum.constraints.is_not_type'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?(hsh)).to be false }
      end

      describe 'with a matching hash' do
        let(:hsh) do
          {
            name:        'Self-Sealing Stem Bolt',
            description: 'No one is quite sure what this does or why.',
            quantity:    10,
            size:        'Colossal'
          }
        end

        it { expect(attributes::Contract.errors_for(hsh)).to be == [] }

        it { expect(attributes::Contract.matches?(hsh)).to be true }
      end

      describe 'with a hash with extra keys' do
        let(:hsh) do
          {
            name:         'Self-Sealing Stem Bolt',
            description:  'No one is quite sure what this does or why.',
            manufacturer: 'StrutCo',
            quantity:     10,
            size:         'Colossal'
          }
        end
        let(:expected_errors) do
          [
            {
              data:    { keys: %i[manufacturer] },
              message: nil,
              path:    [],
              type:    'stannum.constraints.hash_with_extra_keys'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?(hsh)).to be false }
      end
    end

    wrap_context 'when grandparent attributes are included' do
      describe 'with an empty hash' do
        let(:expected_errors) do
          [
            {
              data:    { type: BigDecimal },
              message: nil,
              path:    [:price],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:size],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:description],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: Integer },
              message: nil,
              path:    [:quantity],
              type:    'stannum.constraints.is_not_type'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for({})).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?({})).to be false }
      end

      describe 'with a partially matching hash' do
        let(:hsh) do
          { description: 'No one is quite sure what this does or why.' }
        end
        let(:expected_errors) do
          [
            {
              data:    { type: BigDecimal },
              message: nil,
              path:    [:price],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:size],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: String },
              message: nil,
              path:    [:name],
              type:    'stannum.constraints.is_not_type'
            },
            {
              data:    { type: Integer },
              message: nil,
              path:    [:quantity],
              type:    'stannum.constraints.is_not_type'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?(hsh)).to be false }
      end

      describe 'with a matching hash' do
        let(:hsh) do
          {
            name:        'Self-Sealing Stem Bolt',
            description: 'No one is quite sure what this does or why.',
            price:       BigDecimal('10.0'),
            quantity:    10,
            size:        'Colossal'
          }
        end

        it { expect(attributes::Contract.errors_for(hsh)).to be == [] }

        it { expect(attributes::Contract.matches?(hsh)).to be true }
      end

      describe 'with a hash with extra keys' do
        let(:hsh) do
          {
            name:         'Self-Sealing Stem Bolt',
            description:  'No one is quite sure what this does or why.',
            manufacturer: 'StrutCo',
            price:        BigDecimal('10.0'),
            quantity:     10,
            size:         'Colossal'
          }
        end
        let(:expected_errors) do
          [
            {
              data:    { keys: %i[manufacturer] },
              message: nil,
              path:    [],
              type:    'stannum.constraints.hash_with_extra_keys'
            }
          ]
        end

        it 'should return the errors' do
          expect(attributes::Contract.errors_for(hsh)).to be == expected_errors
        end

        it { expect(attributes::Contract.matches?(hsh)).to be false }
      end
    end
  end

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }

    it { expect(described_class.new).to be_a Module }
  end

  describe '#:attribute' do
    shared_examples 'should define the attribute reader' \
    do |attr_name:, attr_value:|
      it { expect(struct).to respond_to(attr_name).with(0).arguments }

      it { expect(struct.send(attr_name)).to be nil }

      context 'when the attribute has a value' do
        before(:example) do
          struct.attributes[attr_name.to_s] = attr_value
        end

        it { expect(struct.send(attr_name)).to be == attr_value }
      end
    end

    it { expect(struct).not_to respond_to(:name) }

    it { expect(struct).not_to respond_to(:price) }

    it { expect(struct).not_to respond_to(:size) }

    wrap_context 'when there are many defined attributes' do
      include_examples 'should define the attribute reader',
        attr_name:  :name,
        attr_value: 'Self-Sealing Stem Bolt'

      it { expect(struct).not_to respond_to(:price) }

      it { expect(struct).not_to respond_to(:size) }
    end

    wrap_context 'when parent attributes are included' do
      include_examples 'should define the attribute reader',
        attr_name:  :size,
        attr_value: 'Colossal'

      it { expect(struct).not_to respond_to(:price) }
    end

    wrap_context 'when grandparent attributes are included' do
      include_examples 'should define the attribute reader',
        attr_name:  :price,
        attr_value: BigDecimal('10.0')
    end
  end

  describe '#:attribute=' do
    shared_examples 'should define the attribute writer' \
    do |attr_name:, new_value:, old_value:|
      writer_name = :"#{attr_name}="

      it { expect(struct).to respond_to(writer_name).with(1).argument }

      it 'should update the attribute' do
        expect { struct.send(writer_name, new_value) }
          .to change { struct.attributes[attr_name.to_s] }
          .to be new_value
      end

      context 'when the attribute has a value' do
        before(:example) do
          struct.attributes[attr_name.to_s] = old_value
        end

        it 'should update the attribute' do
          expect { struct.send(writer_name, new_value) }
            .to change { struct.attributes[attr_name.to_s] }
            .from(old_value)
            .to be new_value
        end
      end
    end

    it { expect(struct).not_to respond_to(:name=) }

    it { expect(struct).not_to respond_to(:price=) }

    it { expect(struct).not_to respond_to(:size=) }

    wrap_context 'when there are many defined attributes' do
      include_examples 'should define the attribute writer',
        attr_name: :name,
        old_value: 'Self-Sealing Stem Bolt',
        new_value: 'Can of Headlight Fluid'

      it { expect(struct).not_to respond_to(:price=) }

      it { expect(struct).not_to respond_to(:size=) }

      context 'when the attribute has a default' do
        let(:default_value) { 0 }
        let(:old_value)     { 1_000 }
        let(:new_value)     { 100 }

        before(:example) { struct.quantity = default_value }

        describe 'with nil' do
          it 'should not change the attribute' do
            expect { struct.quantity = nil }
              .not_to(change { struct.attributes['quantity'] })
          end
        end

        describe 'with a value' do
          it 'should update the attribute' do
            expect { struct.quantity = new_value }
              .to change { struct.attributes['quantity'] }
              .from(default_value)
              .to be new_value
          end
        end

        context 'when the attribute has a value' do
          before(:example) do
            struct.attributes['quantity'] = old_value
          end

          describe 'with nil' do # rubocop:disable RSpec/NestedGroups
            it 'should reset the attribute' do
              expect { struct.quantity = nil }
                .to change { struct.attributes['quantity'] }
                .to be default_value
            end
          end

          describe 'with a value' do # rubocop:disable RSpec/NestedGroups
            it 'should update the attribute' do
              expect { struct.quantity = new_value }
                .to change { struct.attributes['quantity'] }
                .from(old_value)
                .to be new_value
            end
          end
        end
      end
    end

    wrap_context 'when parent attributes are included' do
      include_examples 'should define the attribute writer',
        attr_name: :size,
        old_value: 'Gargantuan',
        new_value: 'Colossal'

      it { expect(struct).not_to respond_to(:price=) }
    end

    wrap_context 'when grandparent attributes are included' do
      include_examples 'should define the attribute writer',
        attr_name: :price,
        old_value: BigDecimal('5.0'),
        new_value: BigDecimal('10.0')
    end
  end

  describe '#[]' do
    it { expect(attributes).to respond_to(:[]).with(1).argument }

    describe 'with nil' do
      it 'should raise an error' do
        expect { attributes[nil] }
          .to raise_error ArgumentError, "key can't be blank"
      end
    end

    describe 'with an Object' do
      it 'should raise an error' do
        expect { attributes[Object.new.freeze] }
          .to raise_error ArgumentError, 'key must be a String or Symbol'
      end
    end

    describe 'with an empty String' do
      it 'should raise an error' do
        expect { attributes[''] }
          .to raise_error ArgumentError, "key can't be blank"
      end
    end

    describe 'with an empty Symbol' do
      it 'should raise an error' do
        expect { attributes[:''] }
          .to raise_error ArgumentError, "key can't be blank"
      end
    end

    describe 'with an undefined String' do
      it 'should raise an error' do
        expect { attributes['unknown'] }
          .to raise_error KeyError, 'key not found: "unknown"'
      end
    end

    describe 'with an undefined Symbol' do
      it 'should raise an error' do
        expect { attributes[:unknown] }
          .to raise_error KeyError, 'key not found: "unknown"'
      end
    end

    wrap_context 'when there are many defined attributes' do
      describe 'with an undefined String' do
        it 'should raise an error' do
          expect { attributes['unknown'] }
            .to raise_error KeyError, 'key not found: "unknown"'
        end
      end

      describe 'with an undefined Symbol' do
        it 'should raise an error' do
          expect { attributes[:unknown] }
            .to raise_error KeyError, 'key not found: "unknown"'
        end
      end

      describe 'with a valid String' do
        def be_the_expected_attribute
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes name: 'name', options: {}, type: 'String')
        end

        it { expect(attributes['name']).to be_the_expected_attribute }
      end

      describe 'with a valid Symbol' do
        def be_the_expected_attribute
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes name: 'name', options: {}, type: 'String')
        end

        it { expect(attributes[:name]).to be_the_expected_attribute }
      end
    end

    wrap_context 'when parent attributes are included' do
      describe 'with a valid String' do
        def be_the_expected_attribute
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes name: 'size', options: {}, type: 'String')
        end

        it { expect(attributes['size']).to be_the_expected_attribute }
      end

      describe 'with a valid Symbol' do
        def be_the_expected_attribute
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes name: 'size', options: {}, type: 'String')
        end

        it { expect(attributes[:size]).to be_the_expected_attribute }
      end
    end

    wrap_context 'when grandparent attributes are included' do
      describe 'with a valid String' do
        def be_the_expected_attribute
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes name: 'price', options: {}, type: 'BigDecimal')
        end

        it { expect(attributes['price']).to be_the_expected_attribute }
      end

      describe 'with a valid Symbol' do
        def be_the_expected_attribute
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes name: 'price', options: {}, type: 'BigDecimal')
        end

        it { expect(attributes[:price]).to be_the_expected_attribute }
      end
    end
  end

  describe '#contract' do
    include_examples 'should have reader',
      :contract,
      -> { attributes::Contract }
  end

  describe '#define_attribute' do
    let(:name)    { :price }
    let(:options) { { default: BigDecimal('9.99') } }
    let(:type)    { BigDecimal }
    let(:attribute) do
      attributes.define_attribute(name: name, options: options, type: type)
    end

    it 'should define the method' do
      expect(attributes)
        .to respond_to(:define_attribute)
        .with(0).arguments
        .and_keywords(:name, :options, :type)
    end

    it { expect(attribute).to be_a Stannum::Structs::Attribute }

    it { expect(attribute.name).to be == name.to_s }

    it { expect(attribute.options).to be == options }

    it { expect(attribute.type).to be == type.to_s }

    it 'should add the attribute to @attributes' do
      expect do
        attributes.define_attribute(name: name, options: options, type: type)
      end
        .to change(attributes.each, :size)
        .by 1
    end

    context 'when the attribute is already defined' do
      before(:example) do
        attributes.define_attribute(name: name, options: {}, type: 'Object')
      end

      it 'should raise an error' do
        expect do
          attributes.define_attribute(name: name, options: options, type: type)
        end
          .to raise_error ArgumentError,
            "attribute #{name.inspect} already exists"
      end
    end

    wrap_context 'when there are many defined attributes' do
      it 'should add the attribute to @attributes' do
        expect do
          attributes.define_attribute(name: name, options: options, type: type)
        end
          .to change(attributes.each, :size)
          .by 1
      end
    end
  end

  describe '#each' do
    it { expect(attributes).to respond_to(:each).with(0).arguments }

    it { expect(attributes.each).to be_a Enumerator }

    it { expect(attributes.each.size).to be 0 }

    it { expect { |block| attributes.each(&block) }.not_to yield_control }

    wrap_context 'when there are many defined attributes' do
      let(:expected_attributes) { defined_attributes }
      let(:expected_keys) do
        expected_attributes.map { |hsh| hsh[:name] }
      end
      let(:expected_values) do
        expected_attributes.map do |attribute|
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes(**attribute))
        end
      end

      it { expect(attributes.each.size).to be expected_attributes.size }

      it 'should yield the attribute names and attributes' do
        expect { |block| attributes.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end

    wrap_context 'when parent attributes are included' do
      let(:expected_attributes) do
        parent_defined_attributes + defined_attributes
      end
      let(:expected_keys) do
        expected_attributes.map { |hsh| hsh[:name] }
      end
      let(:expected_values) do
        expected_attributes.map do |attribute|
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes(**attribute))
        end
      end

      it { expect(attributes.each.size).to be expected_attributes.size }

      it 'should yield the attribute names and attributes' do
        expect { |block| attributes.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end

    wrap_context 'when grandparent attributes are included' do
      let(:expected_attributes) do
        grandparent_defined_attributes +
          parent_defined_attributes +
          defined_attributes
      end
      let(:expected_keys) do
        expected_attributes.map { |hsh| hsh[:name] }
      end
      let(:expected_values) do
        expected_attributes.map do |attribute|
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes(**attribute))
        end
      end

      it { expect(attributes.each.size).to be expected_attributes.size }

      it 'should yield the attribute names and attributes' do
        expect { |block| attributes.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end
  end

  describe '#each_key' do
    it { expect(attributes).to respond_to(:each_key).with(0).arguments }

    it { expect(attributes.each_key).to be_a Enumerator }

    it { expect(attributes.each_key.size).to be 0 }

    it { expect { |block| attributes.each_key(&block) }.not_to yield_control }

    wrap_context 'when there are many defined attributes' do
      let(:expected_attributes) { defined_attributes }
      let(:expected_keys) do
        expected_attributes.map { |hsh| hsh[:name] }
      end

      it { expect(attributes.each_key.size).to be expected_attributes.size }

      it 'should yield the attribute names' do
        expect { |block| attributes.each_key(&block) }
          .to yield_successive_args(*expected_keys)
      end
    end

    wrap_context 'when parent attributes are included' do
      let(:expected_attributes) do
        parent_defined_attributes + defined_attributes
      end
      let(:expected_keys) do
        expected_attributes.map { |hsh| hsh[:name] }
      end

      it { expect(attributes.each_key.size).to be expected_attributes.size }

      it 'should yield the attribute names' do
        expect { |block| attributes.each_key(&block) }
          .to yield_successive_args(*expected_keys)
      end
    end

    wrap_context 'when grandparent attributes are included' do
      let(:expected_attributes) do
        grandparent_defined_attributes +
          parent_defined_attributes +
          defined_attributes
      end
      let(:expected_keys) do
        expected_attributes.map { |hsh| hsh[:name] }
      end

      it { expect(attributes.each_key.size).to be expected_attributes.size }

      it 'should yield the attribute names' do
        expect { |block| attributes.each_key(&block) }
          .to yield_successive_args(*expected_keys)
      end
    end
  end

  describe '#each_value' do
    it { expect(attributes).to respond_to(:each_value).with(0).arguments }

    it { expect(attributes.each_value).to be_a Enumerator }

    it { expect(attributes.each_value.size).to be 0 }

    it { expect { |block| attributes.each_value(&block) }.not_to yield_control }

    wrap_context 'when there are many defined attributes' do
      let(:expected_attributes) { defined_attributes }
      let(:expected_values) do
        expected_attributes.map do |attribute|
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes(**attribute))
        end
      end

      it { expect(attributes.each_value.size).to be expected_attributes.size }

      it 'should yield the attributes' do
        expect { |block| attributes.each_value(&block) }
          .to yield_successive_args(*expected_values)
      end
    end

    wrap_context 'when parent attributes are included' do
      let(:expected_attributes) do
        parent_defined_attributes + defined_attributes
      end
      let(:expected_values) do
        expected_attributes.map do |attribute|
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes(**attribute))
        end
      end

      it { expect(attributes.each_value.size).to be expected_attributes.size }

      it 'should yield the attributes' do
        expect { |block| attributes.each_value(&block) }
          .to yield_successive_args(*expected_values)
      end
    end

    wrap_context 'when grandparent attributes are included' do
      let(:expected_attributes) do
        grandparent_defined_attributes +
          parent_defined_attributes +
          defined_attributes
      end
      let(:expected_values) do
        expected_attributes.map do |attribute|
          an_instance_of(Stannum::Structs::Attribute)
            .and(have_attributes(**attribute))
        end
      end

      it { expect(attributes.each_value.size).to be expected_attributes.size }

      it 'should yield the attributes' do
        expect { |block| attributes.each_value(&block) }
          .to yield_successive_args(*expected_values)
      end
    end
  end

  describe '#key?' do
    it { expect(attributes).to respond_to(:key?).with(1).argument }

    it { expect(attributes.key? 'name').to be false }

    it { expect(attributes.key? :name).to be false }

    wrap_context 'when there are many defined attributes' do
      it { expect(attributes.key? 'other').to be false }

      it { expect(attributes.key? :other).to be false }

      it { expect(attributes.key? 'name').to be true }

      it { expect(attributes.key? :name).to be true }
    end

    wrap_context 'when parent attributes are included' do
      it { expect(attributes.key? 'other').to be false }

      it { expect(attributes.key? :other).to be false }

      it { expect(attributes.key? 'name').to be true }

      it { expect(attributes.key? :name).to be true }

      it { expect(attributes.key? 'size').to be true }

      it { expect(attributes.key? :size).to be true }
    end

    wrap_context 'when grandparent attributes are included' do
      it { expect(attributes.key? 'other').to be false }

      it { expect(attributes.key? :other).to be false }

      it { expect(attributes.key? 'name').to be true }

      it { expect(attributes.key? :name).to be true }

      it { expect(attributes.key? 'price').to be true }

      it { expect(attributes.key? :price).to be true }

      it { expect(attributes.key? 'size').to be true }

      it { expect(attributes.key? :size).to be true }
    end
  end
end
