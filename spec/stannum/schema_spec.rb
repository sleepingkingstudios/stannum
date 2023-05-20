# frozen_string_literal: true

require 'bigdecimal'

require 'stannum/schema'

require 'support/generic_property'

RSpec.describe Stannum::Schema do
  shared_context 'when there are many defined properties' do
    let(:defined_properties) do
      [
        {
          name:    'name',
          options: {},
          type:    'String'
        },
        {
          name:    'description',
          options: { optional: true },
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
      defined_properties.each do |property|
        schema.define(**property)
      end
    end
  end

  shared_context 'when parent properties are included' do
    include_context 'when there are many defined properties'

    let(:parent_defined_properties) do
      [
        {
          name:    'size',
          options: {},
          type:    'String'
        }
      ]
    end
    let(:parent_properties) do
      described_class
        .new(
          property_class: property_class,
          property_name:  property_name
        )
        .tap do |parent_properties|
          if defined?(grandparent_properties)
            parent_properties.include(grandparent_properties)
          end
        end
    end

    before(:example) do
      parent_defined_properties.each do |property|
        parent_properties.define(**property)
      end
    end
  end

  shared_context 'when grandparent properties are included' do
    include_context 'when parent properties are included'

    let(:grandparent_defined_properties) do
      [
        {
          name:    'price',
          options: {},
          type:    'BigDecimal'
        }
      ]
    end
    let(:grandparent_properties) do
      described_class.new(
        property_class: property_class,
        property_name:  property_name
      )
    end

    before(:example) do
      grandparent_defined_properties.each do |property|
        grandparent_properties.define(**property)
      end
    end
  end

  subject(:schema) do
    described_class
      .new(
        property_class: property_class,
        property_name:  property_name
      )
      .tap do |schema|
        schema.include(parent_properties) if defined?(parent_properties)
      end
  end

  let(:struct)         { Spec::BasicStruct.new }
  let(:property_class) { Spec::GenericProperty }
  let(:property_name)  { 'properties' }

  example_class 'Spec::BasicStruct' do |klass|
    klass.send(:define_method, :initialize) { @attributes = {} }

    klass.send(:attr_reader, :attributes)

    klass.const_set(:Attributes, schema)

    klass.send(:include, schema)
  end

  example_class 'Spec::PropertyBuilder' do |klass|
    klass.define_method(:initialize) { |*| nil }

    klass.define_method(:call) { |*| nil }
  end

  example_class 'Spec::Property',
    Struct.new(:name, :options, :type, keyword_init: true) \
  do |klass|
    klass.const_set(:Builder, Spec::PropertyBuilder)
  end

  it { expect(schema).to be_a Enumerable }

  it { expect(schema).to be_a Module }

  describe '.new' do
    it 'should define the constructor' do
      expect(schema)
        .to respond_to(:initialize, true)
        .with(0).arguments
        .and_keywords(:property_class, :property_name)
    end

    describe 'with property_class: object' do
      let(:error_message) { 'property class is not a Class' }

      it 'should raise an exception' do
        expect do
          described_class.new(
            property_class: Object.new.freeze,
            property_name:  property_name
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with property_name: nil' do
      let(:error_message) { "property name can't be blank" }

      it 'should raise an exception' do
        expect do
          described_class.new(
            property_class: property_class,
            property_name:  nil
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with property_name: an Object' do
      let(:error_message) { 'property name is not a String or a Symbol' }

      it 'should raise an exception' do
        expect do
          described_class.new(
            property_class: property_class,
            property_name:  Object.new.freeze
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with property_name: an empty String' do
      let(:error_message) { "property name can't be blank" }

      it 'should raise an exception' do
        expect do
          described_class.new(
            property_class: property_class,
            property_name:  ''
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with property_name: an empty Symbol' do
      let(:error_message) { "property name can't be blank" }

      it 'should raise an exception' do
        expect do
          described_class.new(
            property_class: property_class,
            property_name:  :''
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '#[]' do
    it { expect(schema).to respond_to(:[]).with(1).argument }

    describe 'with nil' do
      it 'should raise an error' do
        expect { schema[nil] }
          .to raise_error ArgumentError, "key can't be blank"
      end
    end

    describe 'with an Object' do
      it 'should raise an error' do
        expect { schema[Object.new.freeze] }
          .to raise_error ArgumentError, 'key is not a String or a Symbol'
      end
    end

    describe 'with an empty String' do
      it 'should raise an error' do
        expect { schema[''] }
          .to raise_error ArgumentError, "key can't be blank"
      end
    end

    describe 'with an empty Symbol' do
      it 'should raise an error' do
        expect { schema[:''] }
          .to raise_error ArgumentError, "key can't be blank"
      end
    end

    describe 'with an undefined String' do
      it 'should raise an error' do
        expect { schema['unknown'] }
          .to raise_error KeyError, 'key not found: "unknown"'
      end
    end

    describe 'with an undefined Symbol' do
      it 'should raise an error' do
        expect { schema[:unknown] }
          .to raise_error KeyError, 'key not found: "unknown"'
      end
    end

    wrap_context 'when there are many defined properties' do
      describe 'with an undefined String' do
        it 'should raise an error' do
          expect { schema['unknown'] }
            .to raise_error KeyError, 'key not found: "unknown"'
        end
      end

      describe 'with an undefined Symbol' do
        it 'should raise an error' do
          expect { schema[:unknown] }
            .to raise_error KeyError, 'key not found: "unknown"'
        end
      end

      describe 'with a valid String' do
        let(:expected) do
          Spec::GenericProperty.new(
            name:    'name',
            options: {},
            type:    'String'
          )
        end

        it { expect(schema['name']).to be == expected }
      end

      describe 'with a valid Symbol' do
        let(:expected) do
          Spec::GenericProperty.new(
            name:    'name',
            options: {},
            type:    'String'
          )
        end

        it { expect(schema[:name]).to be == expected }
      end
    end

    wrap_context 'when parent properties are included' do
      describe 'with a valid String' do
        let(:expected) do
          Spec::GenericProperty.new(
            name:    'size',
            options: {},
            type:    'String'
          )
        end

        it { expect(schema['size']).to be == expected }
      end

      describe 'with a valid Symbol' do
        let(:expected) do
          Spec::GenericProperty.new(
            name:    'size',
            options: {},
            type:    'String'
          )
        end

        it { expect(schema[:size]).to be == expected }
      end
    end

    wrap_context 'when grandparent properties are included' do
      describe 'with a valid String' do
        let(:expected) do
          Spec::GenericProperty.new(
            name:    'price',
            options: {},
            type:    'BigDecimal'
          )
        end

        it { expect(schema['price']).to be == expected }
      end

      describe 'with a valid Symbol' do
        let(:expected) do
          Spec::GenericProperty.new(
            name:    'price',
            options: {},
            type:    'BigDecimal'
          )
        end

        it { expect(schema[:price]).to be == expected }
      end
    end
  end

  describe '#define' do
    let(:name)     { 'price' }
    let(:options)  { { default: BigDecimal('9.99') } }
    let(:type)     { BigDecimal }
    let(:property) { schema.define(name: name, options: options, type: type) }
    let(:builder)  { instance_double(property_class::Builder, call: nil) }

    before(:example) do
      allow(property_class::Builder).to receive(:new).and_return(builder)
    end

    it 'should define the method' do
      expect(schema)
        .to respond_to(:define)
        .with(0).arguments
        .and_keywords(:name, :options, :type)
    end

    it { expect(property).to be_a property_class }

    it { expect(property.name).to be == name }

    it { expect(property.options).to be == options }

    it { expect(property.type).to be == type }

    it 'should add the property' do
      expect { schema.define(name: name, options: options, type: type) }
        .to change(schema.each, :size)
        .by 1
    end

    it 'should call the builder', :aggregate_failures do
      schema.define(name: name, options: options, type: type)

      property = schema[name]

      expect(property_class::Builder).to have_received(:new).with(schema)
      expect(builder).to have_received(:call).with(property)
    end

    describe 'with definition_class: value' do
      let(:property)       { define_property }
      let(:custom_builder) { instance_double(Spec::CustomBuilder, call: nil) }

      def define_property
        schema.define(
          definition_class: Spec::CustomProperty,
          name:             name,
          options:          options,
          type:             type
        )
      end

      example_class 'Spec::CustomBuilder', 'Spec::Property::Builder'

      example_class 'Spec::CustomProperty', 'Spec::Property' do |klass|
        klass.const_set(:Builder, Spec::CustomBuilder)
      end

      before(:example) do
        allow(Spec::CustomProperty::Builder)
          .to receive(:new)
          .and_return(custom_builder)
      end

      it { expect(property).to be_a Spec::CustomProperty }

      it { expect(property.name).to be == name }

      it { expect(property.options).to be == options }

      it { expect(property.type).to be == type }

      it 'should add the property' do
        expect { define_property }
          .to change(schema.each, :size)
          .by 1
      end

      it 'should call the builder', :aggregate_failures do
        define_property

        property = schema[name]

        expect(Spec::CustomProperty::Builder)
          .to have_received(:new)
          .with(schema)
        expect(custom_builder).to have_received(:call).with(property)
      end
    end

    context 'when the property is already defined' do
      let(:error_message) do
        "#{tools.str.singularize(property_name)} #{name.inspect} already exists"
      end

      def tools
        SleepingKingStudios::Tools::Toolbelt.instance
      end

      before(:example) do
        schema.define(name: name, options: {}, type: 'Object')
      end

      it 'should raise an error' do
        expect { schema.define(name: name, options: options, type: type) }
          .to raise_error ArgumentError, error_message
      end
    end

    wrap_context 'when there are many defined properties' do
      it 'should add the property' do
        expect { schema.define(name: name, options: options, type: type) }
          .to change(schema.each, :size)
          .by 1
      end

      it 'should call the builder', :aggregate_failures do
        schema.define(name: name, options: options, type: type)

        property = schema[name]

        expect(property_class::Builder)
          .to have_received(:new)
          .with(schema)
          .exactly(4).times
        expect(builder).to have_received(:call).with(property)
      end

      describe 'with definition_class: value' do
        let(:property)       { define_property }
        let(:custom_builder) { instance_double(Spec::CustomBuilder, call: nil) }

        def define_property
          schema.define(
            definition_class: Spec::CustomProperty,
            name:             name,
            options:          options,
            type:             type
          )
        end

        example_class 'Spec::CustomBuilder', 'Spec::Property::Builder'

        example_class 'Spec::CustomProperty', 'Spec::Property' do |klass|
          klass.const_set(:Builder, Spec::CustomBuilder)
        end

        before(:example) do
          allow(Spec::CustomProperty::Builder)
            .to receive(:new)
            .and_return(custom_builder)
        end

        it { expect(property).to be_a Spec::CustomProperty }

        it { expect(property.name).to be == name }

        it { expect(property.options).to be == options }

        it { expect(property.type).to be == type }

        it 'should add the property' do
          expect { define_property }
            .to change(schema.each, :size)
            .by 1
        end

        it 'should call the builder', :aggregate_failures do
          define_property

          property = schema[name]

          expect(Spec::CustomProperty::Builder)
            .to have_received(:new)
            .with(schema)
          expect(custom_builder).to have_received(:call).with(property)
        end
      end
    end
  end

  describe '#each' do
    let(:expected_properties) { [] }
    let(:expected_keys) do
      expected_properties.map { |hsh| hsh[:name] }
    end
    let(:expected_values) do
      expected_properties.map do |property|
        Spec::GenericProperty.new(
          name:    property[:name],
          options: property[:options],
          type:    property[:type]
        )
      end
    end

    it { expect(schema).to respond_to(:each).with(0).arguments }

    it { expect(schema.each).to be_a Enumerator }

    it { expect(schema.each.size).to be 0 }

    it { expect { |block| schema.each(&block) }.not_to yield_control }

    wrap_context 'when there are many defined properties' do
      let(:expected_properties) { defined_properties }

      it { expect(schema.each.size).to be defined_properties.size }

      it 'should yield the property names and properties' do
        expect { |block| schema.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end

    wrap_context 'when parent properties are included' do
      let(:expected_properties) do
        parent_defined_properties + defined_properties
      end

      it { expect(schema.each.size).to be expected_properties.size }

      it 'should yield the property names and properties' do
        expect { |block| schema.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end

    wrap_context 'when grandparent properties are included' do
      let(:expected_properties) do
        grandparent_defined_properties +
          parent_defined_properties +
          defined_properties
      end

      it { expect(schema.each.size).to be expected_properties.size }

      it 'should yield the property names and properties' do
        expect { |block| schema.each(&block) }
          .to yield_successive_args(*expected_keys.zip(expected_values))
      end
    end
  end

  describe '#each_key' do
    let(:expected_properties) { [] }
    let(:expected_keys) do
      expected_properties.map { |hsh| hsh[:name] }
    end

    it { expect(schema).to respond_to(:each_key).with(0).arguments }

    it { expect(schema.each_key).to be_a Enumerator }

    it { expect(schema.each_key.size).to be 0 }

    it { expect { |block| schema.each_key(&block) }.not_to yield_control }

    wrap_context 'when there are many defined properties' do
      let(:expected_properties) { defined_properties }

      it { expect(schema.each_key.size).to be expected_properties.size }

      it 'should yield the property names' do
        expect { |block| schema.each_key(&block) }
          .to yield_successive_args(*expected_keys)
      end
    end

    wrap_context 'when parent properties are included' do
      let(:expected_properties) do
        parent_defined_properties + defined_properties
      end

      it { expect(schema.each_key.size).to be expected_properties.size }

      it 'should yield the property names' do
        expect { |block| schema.each_key(&block) }
          .to yield_successive_args(*expected_keys)
      end
    end

    wrap_context 'when grandparent properties are included' do
      let(:expected_properties) do
        grandparent_defined_properties +
          parent_defined_properties +
          defined_properties
      end

      it { expect(schema.each_key.size).to be expected_properties.size }

      it 'should yield the property names' do
        expect { |block| schema.each_key(&block) }
          .to yield_successive_args(*expected_keys)
      end
    end
  end

  describe '#each_value' do
    let(:expected_properties) { [] }
    let(:expected_values) do
      expected_properties.map do |property|
        Spec::GenericProperty.new(
          name:    property[:name],
          options: property[:options],
          type:    property[:type]
        )
      end
    end

    it { expect(schema).to respond_to(:each_value).with(0).arguments }

    it { expect(schema.each_value).to be_a Enumerator }

    it { expect(schema.each_value.size).to be 0 }

    it { expect { |block| schema.each_value(&block) }.not_to yield_control }

    wrap_context 'when there are many defined properties' do
      let(:expected_properties) { defined_properties }

      it { expect(schema.each_value.size).to be expected_properties.size }

      it 'should yield the properties' do
        expect { |block| schema.each_value(&block) }
          .to yield_successive_args(*expected_values)
      end
    end

    wrap_context 'when parent properties are included' do
      let(:expected_properties) do
        parent_defined_properties + defined_properties
      end

      it { expect(schema.each_value.size).to be expected_properties.size }

      it 'should yield the properties' do
        expect { |block| schema.each_value(&block) }
          .to yield_successive_args(*expected_values)
      end
    end

    wrap_context 'when grandparent properties are included' do
      let(:expected_properties) do
        grandparent_defined_properties +
          parent_defined_properties +
          defined_properties
      end

      it { expect(schema.each_value.size).to be expected_properties.size }

      it 'should yield the property' do
        expect { |block| schema.each_value(&block) }
          .to yield_successive_args(*expected_values)
      end
    end
  end

  describe '#key?' do
    it { expect(schema).to respond_to(:key?).with(1).argument }

    it { expect(schema.key? 'name').to be false }

    it { expect(schema.key? :name).to be false }

    wrap_context 'when there are many defined properties' do
      it { expect(schema.key? 'other').to be false }

      it { expect(schema.key? :other).to be false }

      it { expect(schema.key? 'name').to be true }

      it { expect(schema.key? :name).to be true }
    end

    wrap_context 'when parent properties are included' do
      it { expect(schema.key? 'other').to be false }

      it { expect(schema.key? :other).to be false }

      it { expect(schema.key? 'name').to be true }

      it { expect(schema.key? :name).to be true }

      it { expect(schema.key? 'size').to be true }

      it { expect(schema.key? :size).to be true }
    end

    wrap_context 'when grandparent properties are included' do
      it { expect(schema.key? 'other').to be false }

      it { expect(schema.key? :other).to be false }

      it { expect(schema.key? 'name').to be true }

      it { expect(schema.key? :name).to be true }

      it { expect(schema.key? 'price').to be true }

      it { expect(schema.key? :price).to be true }

      it { expect(schema.key? 'size').to be true }

      it { expect(schema.key? :size).to be true }
    end
  end

  describe '#keys' do
    it { expect(schema).to respond_to(:keys).with(0).arguments }

    it { expect(schema.keys).to be == [] }

    wrap_context 'when there are many defined properties' do
      let(:expected_properties) { defined_properties }
      let(:expected_keys) do
        expected_properties.map { |hsh| hsh[:name] }
      end

      it { expect(schema.keys).to be == expected_keys }
    end

    wrap_context 'when parent properties are included' do
      let(:expected_properties) do
        parent_defined_properties + defined_properties
      end
      let(:expected_keys) do
        expected_properties.map { |hsh| hsh[:name] }
      end

      it { expect(schema.keys).to be == expected_keys }
    end

    wrap_context 'when grandparent properties are included' do
      let(:expected_properties) do
        grandparent_defined_properties +
          parent_defined_properties +
          defined_properties
      end
      let(:expected_keys) do
        expected_properties.map { |hsh| hsh[:name] }
      end

      it { expect(schema.keys).to be == expected_keys }
    end
  end

  describe '#property_class' do
    include_examples 'should define reader',
      :property_class,
      -> { property_class }
  end

  describe '#property_name' do
    include_examples 'should define reader',
      :property_name,
      -> { property_name }

    context 'when initialized with property_name: a Symbol' do
      let(:property_name) { :properties }

      it { expect(schema.property_name).to be == property_name.to_s }
    end
  end

  describe '#size' do
    it { expect(schema).to respond_to(:size).with(0).arguments }

    it { expect(schema).to have_aliased_method(:size).as(:count) }

    it { expect(schema.size).to be 0 }

    wrap_context 'when there are many defined properties' do
      let(:expected_properties) { defined_properties }

      it { expect(schema.size).to be expected_properties.size }
    end

    wrap_context 'when parent properties are included' do
      let(:expected_properties) do
        parent_defined_properties + defined_properties
      end

      it { expect(schema.size).to be expected_properties.size }
    end

    wrap_context 'when grandparent properties are included' do
      let(:expected_properties) do
        grandparent_defined_properties +
          parent_defined_properties +
          defined_properties
      end

      it { expect(schema.size).to be expected_properties.size }
    end
  end

  describe '#values' do
    let(:expected_properties) { [] }
    let(:expected_values) do
      expected_properties.map do |property|
        Spec::GenericProperty.new(
          name:    property[:name],
          options: property[:options],
          type:    property[:type]
        )
      end
    end

    it { expect(schema).to respond_to(:values).with(0).arguments }

    it { expect(schema.values).to be == [] }

    wrap_context 'when there are many defined properties' do
      let(:expected_properties) { defined_properties }

      it { expect(schema.values).to deep_match expected_values }
    end

    wrap_context 'when parent properties are included' do
      let(:expected_properties) do
        parent_defined_properties + defined_properties
      end

      it { expect(schema.values).to deep_match expected_values }
    end

    wrap_context 'when grandparent properties are included' do
      let(:expected_properties) do
        grandparent_defined_properties +
          parent_defined_properties +
          defined_properties
      end

      it { expect(schema.values).to deep_match expected_values }
    end
  end
end
