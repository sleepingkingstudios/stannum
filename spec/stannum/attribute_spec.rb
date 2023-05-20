# frozen_string_literal: true

require 'stannum/attribute'

require 'support/examples/optional_examples'

RSpec.describe Stannum::Attribute do
  include Spec::Support::Examples::OptionalExamples

  shared_context 'with default: Proc' do
    let(:default) { -> { 'No one is quite sure what this does.' } }

    before(:example) { options.update(default: default) }
  end

  shared_context 'with default: value' do
    let(:default) { 'No one is quite sure what this does.' }

    before(:example) { options.update(default: default) }
  end

  shared_context 'with primary_key: false' do
    before(:example) { options.update(primary_key: false) }
  end

  shared_context 'with primary_key: true' do
    before(:example) { options.update(primary_key: true) }
  end

  subject(:attribute) do
    described_class.new(name: name, type: type, options: options)
  end

  let(:constructor_options) do
    {}
  end
  let(:name)    { 'description' }
  let(:type)    { String }
  let(:options) { constructor_options }

  describe '::Builder' do
    subject(:builder) do
      described_class::Builder.new(entity_class)
    end

    let(:entity_class) { Spec::Entity }

    example_class 'Spec::Entity' do |klass|
      klass.include Stannum::Entities::Properties
      klass.include Stannum::Entities::Attributes

      klass.define_method(:set_properties) do |values, **|
        @attributes = values
      end
    end

    describe '.new' do
      it 'should be constructible' do
        expect(described_class::Builder).to be_constructible.with(1).argument
      end
    end

    describe '#call' do
      let(:attribute) do
        described_class.new(name: name, type: type, options: options)
      end
      let(:values) { {} }
      let(:entity) { entity_class.new(**values) }

      it { expect(builder).to respond_to(:call).with(1).argument }

      describe '#:attribute' do
        before(:example) { builder.call(attribute) }

        it { expect(entity).to define_reader(attribute.name) }

        it { expect(entity.send(attribute.name)).to be nil }

        context 'when the attribute has a value' do
          let(:values) do
            { 'description' => 'No one is quite sure what this does.' }
          end

          it 'should get the attribute value' do
            expect(entity.send(attribute.name)).to be == values[attribute.name]
          end
        end
      end

      describe '#:attribute=' do
        let(:value) { 'A mechanical mystery.' }

        before(:example) { builder.call(attribute) }

        it { expect(entity).to define_writer("#{attribute.name}=") }

        it 'should set the attribute value' do
          expect { entity.send("#{attribute.name}=", value) }
            .to change(entity, attribute.name)
            .to be == value
        end

        # rubocop:disable RSpec/NestedGroups
        context 'when the attribute has a value' do
          let(:values) do
            { 'description' => 'No one is quite sure what this does.' }
          end

          describe 'with nil' do
            it 'should clear the attribute value' do
              expect { entity.send("#{attribute.name}=", nil) }
                .to change(entity, attribute.name)
                .to be nil
            end
          end

          describe 'with a value' do
            it 'should set the attribute value' do
              expect { entity.send("#{attribute.name}=", value) }
                .to change(entity, attribute.name)
                .to be == value
            end
          end
        end

        context 'when the attribute has a default Proc' do
          let(:name)    { 'quantity' }
          let(:default) { -> { 0 } }
          let(:value)   { 500 }
          let(:options) { super().merge(default: default) }

          context 'when the attribute has a value' do
            let(:values) do
              { 'quantity' => 1_000 }
            end

            describe 'with nil' do
              it 'should set the attribute value to the default' do
                expect { entity.send("#{attribute.name}=", nil) }
                  .to change(entity, attribute.name)
                  .to be == default.call
              end
            end

            describe 'with a value' do
              it 'should set the attribute value' do
                expect { entity.send("#{attribute.name}=", value) }
                  .to change(entity, attribute.name)
                  .to be == value
              end
            end
          end
        end

        context 'when the attrbute has a default value' do
          let(:name)    { 'quantity' }
          let(:default) { 0 }
          let(:value)   { 500 }
          let(:options) { super().merge(default: default) }

          context 'when the attribute has a value' do
            let(:values) do
              { 'quantity' => 1_000 }
            end

            describe 'with nil' do
              it 'should set the attribute value to the default' do
                expect { entity.send("#{attribute.name}=", nil) }
                  .to change(entity, attribute.name)
                  .to be == default
              end
            end

            describe 'with a value' do
              it 'should set the attribute value' do
                expect { entity.send("#{attribute.name}=", value) }
                  .to change(entity, attribute.name)
                  .to be == value
              end
            end
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end
    end

    describe '#entity_class' do
      include_examples 'should define reader',
        :entity_class,
        -> { entity_class }
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:name, :options, :type)
    end

    describe 'with name: nil' do
      it 'should raise an error' do
        expect { described_class.new(name: nil, type: type, options: options) }
          .to raise_error ArgumentError, "name can't be blank"
      end
    end

    describe 'with name: an Object' do
      it 'should raise an error' do
        expect do
          described_class.new(
            name:    Object.new.freeze,
            type:    type,
            options: options
          )
        end
          .to raise_error ArgumentError, 'name is not a String or a Symbol'
      end
    end

    describe 'with name: empty String' do
      it 'should raise an error' do
        expect { described_class.new(name: '', type: type, options: options) }
          .to raise_error ArgumentError, "name can't be blank"
      end
    end

    describe 'with name: empty Symbol' do
      it 'should raise an error' do
        expect { described_class.new(name: :'', type: type, options: options) }
          .to raise_error ArgumentError, "name can't be blank"
      end
    end

    describe 'with options: nil' do
      it 'should set the options to a default hash' do
        expect(
          described_class.new(name: name, type: type, options: nil).options
        ).to be == { required: true }
      end
    end

    describe 'with options: an Object' do
      it 'should raise an error' do
        expect do
          described_class.new(
            name:    name,
            type:    type,
            options: Object.new.freeze
          )
        end
          .to raise_error ArgumentError, 'options must be a Hash or nil'
      end
    end

    describe 'with type: nil' do
      it 'should raise an error' do
        expect { described_class.new(name: name, type: nil, options: options) }
          .to raise_error ArgumentError, "type can't be blank"
      end
    end

    describe 'with type: an Object' do
      it 'should raise an error' do
        expect do
          described_class.new(
            name:    name,
            type:    Object.new.freeze,
            options: options
          )
        end
          .to raise_error ArgumentError,
            'type must be a Class, a Module, or the name of a class or module'
      end
    end

    describe 'with type: an empty String' do
      it 'should raise an error' do
        expect { described_class.new(name: name, type: '', options: options) }
          .to raise_error ArgumentError, "type can't be blank"
      end
    end
  end

  include_examples 'should implement the Optional interface'

  include_examples 'should implement the Optional methods'

  describe '#default' do
    it { expect(attribute).to respond_to(:default).with(0).arguments }

    it { expect(attribute.default).to be nil }

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'with default: Proc' do
      it { expect(attribute.default).to be default }
    end

    wrap_context 'with default: value' do
      it { expect(attribute.default).to be default }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#default?' do
    include_examples 'should define predicate', :default?, false

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'with default: Proc' do
      it { expect(attribute.default?).to be true }
    end

    wrap_context 'with default: value' do
      it { expect(attribute.default?).to be true }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#default_value_for' do
    let(:context) do
      Struct.new(:first_name, :last_name).new('Alan', 'Bradley')
    end

    it { expect(attribute).to respond_to(:default_value_for).with(1).argument }

    it { expect(attribute.default_value_for(context)).to be nil }

    wrap_context 'with default: Proc' do
      context 'when the Proc does not accept a context argument' do
        let(:default) { -> { 'Alan Bradley' } }

        it 'should generate the default value' do
          expect(attribute.default_value_for(context)).to be == 'Alan Bradley'
        end
      end

      context 'when the Proc accepts a context argument' do
        let(:default) do
          ->(context) { "#{context.first_name} #{context.last_name}" }
        end

        it 'should generate the default value' do
          expect(attribute.default_value_for(context)).to be == 'Alan Bradley'
        end
      end
    end

    wrap_context 'with default: value' do
      it { expect(attribute.default_value_for(context)).to be default }
    end
  end

  describe '#name' do
    include_examples 'should define reader', :name, -> { name }

    context 'when the name is a symbol' do
      let(:name) { :description }

      it { expect(attribute.name).to be == name.to_s }
    end
  end

  describe '#options' do
    let(:expected) do
      SleepingKingStudios::Tools::HashTools
        .convert_keys_to_symbols(options)
        .merge(required: true)
    end

    include_examples 'should define reader', :options, -> { expected }

    context 'with options: a Hash with String keys' do
      let(:options) { { 'key' => 'value' } }

      it { expect(attribute.options).to be == expected }
    end

    context 'with options: a Hash with Symbol keys' do
      let(:options) { { key: 'value' } }

      it { expect(attribute.options).to be == expected }
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    wrap_context 'with default: value' do
      it { expect(attribute.options).to be == expected }
    end

    wrap_context 'with primary_key: false' do
      it { expect(attribute.options).to be == expected }
    end

    wrap_context 'with primary_key: true' do
      it { expect(attribute.options).to be == expected }
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end

  describe '#primary_key?' do
    include_examples 'should define predicate', :primary_key?, false

    wrap_context 'with primary_key: false' do
      it { expect(attribute.primary_key?).to be false }
    end

    wrap_context 'with primary_key: true' do
      it { expect(attribute.primary_key?).to be true }
    end
  end

  describe '#reader_name' do
    include_examples 'should define reader', :reader_name, -> { name.intern }

    context 'when the name is a symbol' do
      let(:name) { :description }

      it { expect(attribute.reader_name).to be == name }
    end
  end

  describe '#resolved_type' do
    include_examples 'should define reader', :resolved_type, -> { type }

    context 'when the type is an invalid constant name' do
      let(:type) { 'Foo' }

      it 'should raise an error' do
        expect { attribute.resolved_type }
          .to raise_error NameError, /uninitialized constant Foo/
      end
    end

    context 'when the type is an invalid module name' do
      let(:type) { 'RUBY_VERSION' }

      it 'should raise an error' do
        expect { attribute.resolved_type }
          .to raise_error NameError,
            /constant RUBY_VERSION is not a Class or Module/
      end
    end

    context 'when the type is a valid module name' do
      let(:type) { 'String' }

      it { expect(attribute.resolved_type).to be == String }
    end
  end

  describe '#type' do
    include_examples 'should define reader', :type, -> { type.to_s }

    context 'when the type is a String' do
      let(:type) { 'String' }

      it { expect(attribute.type).to be == type }
    end
  end

  describe '#writer_name' do
    include_examples 'should define reader', :writer_name, -> { :"#{name}=" }

    context 'when the name is a symbol' do
      let(:name) { :description }

      it { expect(attribute.writer_name).to be == :"#{name}=" }
    end
  end
end
