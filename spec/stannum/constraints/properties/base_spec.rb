# frozen_string_literal: true

require 'stannum/constraints/properties/base'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Properties::Base do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(*property_names, **constructor_options)
  end

  shared_context 'when initialized with multiple property names' do
    let(:property_names) { %w[confirmation verification] }
  end

  let(:property_names)      { %w[confirmation] }
  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_empty:    false,
      allow_nil:      false,
      property_names: property_names
    }
  end

  describe '::FILTERED_PARAMETERS' do
    let(:expected) do
      %i[
        passw
        secret
        token
        _key
        crypt
        salt
        certificate
        otp
        ssn
      ]
    end

    include_examples 'should define constant',
      :FILTERED_PARAMETERS,
      -> { be == expected }
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_unlimited_arguments
        .and_keywords(:allow_empty, :allow_nil)
        .and_any_keywords
    end

    describe 'with property_names: an empty Array' do
      let(:error_message) { "property names can't be empty" }

      it 'should raise an error' do
        expect { described_class.new }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with nil' do
      let(:error_message) { "property name at 1 can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(*property_names, nil) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with an Object' do
      let(:object)        { Object.new.freeze }
      let(:error_message) { 'property name at 1 is not a String or a Symbol' }

      it 'should raise an error' do
        expect { described_class.new(*property_names, object) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with an empty String' do
      let(:error_message) { "property name at 1 can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(*property_names, '') }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with an empty Symbol' do
      let(:error_message) { "property name at 1 can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(*property_names, :'') }
          .to raise_error(ArgumentError, error_message)
      end
    end
  end

  include_examples 'should implement the Constraint interface'

  include_examples 'should implement the Constraint methods'

  describe '#allow_empty?' do
    include_examples 'should define predicate', :allow_empty?, false

    context 'when initialized with allow_empty: false' do
      let(:constructor_options) { super().merge(allow_empty: false) }

      it { expect(constraint.allow_empty?).to be false }
    end

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }

      it { expect(constraint.allow_empty?).to be true }
    end
  end

  describe '#allow_nil?' do
    include_examples 'should define predicate', :allow_nil?, false

    context 'when initialized with allow_nil: false' do
      let(:constructor_options) { super().merge(allow_nil: false) }

      it { expect(constraint.allow_nil?).to be false }
    end

    context 'when initialized with allow_nil: true' do
      let(:constructor_options) { super().merge(allow_nil: true) }

      it { expect(constraint.allow_nil?).to be true }
    end
  end

  describe '#each_property' do
    shared_examples 'should iterate over the properties' do
      it 'should enumerate the properties and values' do
        expect(constraint.send(:each_property, actual).to_a).to be == expected
      end

      describe 'with a block' do
        it 'should yield the properties and values' do
          expect { |block| constraint.send(:each_property, actual, &block) }
            .to yield_successive_args(*expected)
        end
      end
    end

    let(:actual) do
      {
        'confirmation' => true,
        'ignored'      => false
      }
    end
    let(:expected) { [['confirmation', true]] }

    it 'should define the private method' do
      expect(constraint)
        .to respond_to(:each_property, true)
        .with(1).argument
    end

    it { expect(constraint.send :each_property, actual).to be_a Enumerator }

    include_examples 'should iterate over the properties'

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }

      include_examples 'should iterate over the properties'

      context 'when the object has empty properties' do
        include_context 'when initialized with multiple property names'

        let(:actual) do
          {
            'confirmation' => '',
            'verification' => :ok,
            'ignored'      => false
          }
        end
        let(:expected) { [['confirmation', ''], ['verification', :ok]] }

        include_examples 'should iterate over the properties'
      end
    end

    context 'when initialized with allow_nil: true' do
      let(:constructor_options) { super().merge(allow_nil: true) }

      include_examples 'should iterate over the properties'

      context 'when the object has nil properties' do
        include_context 'when initialized with multiple property names'

        let(:actual) do
          {
            'confirmation' => nil,
            'verification' => :ok,
            'ignored'      => false
          }
        end
        let(:expected) { [['confirmation', nil], ['verification', :ok]] }

        include_examples 'should iterate over the properties'
      end
    end

    wrap_context 'when initialized with multiple property names' do
      let(:actual) do
        {
          'confirmation' => true,
          'verification' => true,
          'ignored'      => false
        }
      end
      let(:expected) { [['confirmation', true], ['verification', true]] }

      include_examples 'should iterate over the properties'
    end
  end

  describe '#empty?' do
    it { expect(constraint).to respond_to(:empty?, true).with(1).argument }

    describe 'with nil' do
      it { expect(constraint.send :empty?, nil).to be false }
    end

    describe 'with an object' do
      let(:object) { Object.new.freeze }

      it { expect(constraint.send :empty?, object).to be false }
    end

    describe 'with an empty string' do
      it { expect(constraint.send :empty?, '').to be true }
    end

    describe 'with a non-empty string' do
      let(:string) { 'Greetings, programs!' }

      it { expect(constraint.send :empty?, string).to be false }
    end
  end

  describe '#filter_parameters?' do
    it 'should define the private predicate' do
      expect(constraint)
        .to respond_to(:filter_parameters?, true)
        .with(0).arguments
    end

    it { expect(constraint.send(:filter_parameters?)).to be false }

    context 'when a property name matches a filter' do
      let(:property_names) { ['password', *super()] }

      it { expect(constraint.send(:filter_parameters?)).to be true }
    end
  end

  describe '#filtered_parameters' do
    include_examples 'should define private reader',
      :filtered_parameters,
      described_class::FILTERED_PARAMETERS

    context 'when Rails.configuration is defined' do
      let(:parameters)    { %i[password secret] }
      let(:configuration) { Struct.new(:filter_parameters).new(parameters) }
      let(:rails)         { Struct.new(:configuration).new(configuration) }
      let(:expected)      { Rails.configuration.filter_parameters }

      around(:example) do |example|
        return example.call if defined?(Rails)

        stub_rails { example.call }
      end

      def stub_rails
        Object.const_set(:Rails, rails)

        yield
      ensure
        Object.send(:remove_const, :Rails) if rails == Rails
      end

      it { expect(constraint.send :filtered_parameters).to be == expected }
    end
  end

  describe '#property_names' do
    include_examples 'should define reader',
      :property_names,
      -> { property_names }

    wrap_context 'when initialized with multiple property names' do
      it { expect(constraint.property_names).to be == property_names }
    end
  end

  describe '#skip_property?' do
    it 'should define the private method' do
      expect(constraint).to respond_to(:skip_property?, true).with(1).argument
    end

    describe 'with nil' do
      it { expect(constraint.send :skip_property?, nil).to be false }
    end

    describe 'with an object' do
      let(:object) { Object.new.freeze }

      it { expect(constraint.send :skip_property?, object).to be false }
    end

    describe 'with an empty string' do
      it { expect(constraint.send :skip_property?, '').to be false }
    end

    describe 'with a non-empty string' do
      let(:string) { 'Greetings, programs!' }

      it { expect(constraint.send :skip_property?, string).to be false }
    end

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }

      describe 'with nil' do
        it { expect(constraint.send :skip_property?, nil).to be false }
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }

        it { expect(constraint.send :skip_property?, object).to be false }
      end

      describe 'with an empty string' do
        it { expect(constraint.send :skip_property?, '').to be true }
      end

      describe 'with a non-empty string' do
        let(:string) { 'Greetings, programs!' }

        it { expect(constraint.send :skip_property?, string).to be false }
      end
    end

    context 'when initialized with allow_nil: true' do
      let(:constructor_options) { super().merge(allow_nil: true) }

      describe 'with nil' do
        it { expect(constraint.send :skip_property?, nil).to be true }
      end

      describe 'with an object' do
        let(:object) { Object.new.freeze }

        it { expect(constraint.send :skip_property?, object).to be false }
      end

      describe 'with an empty string' do
        it { expect(constraint.send :skip_property?, '').to be false }
      end

      describe 'with a non-empty string' do
        let(:string) { 'Greetings, programs!' }

        it { expect(constraint.send :skip_property?, string).to be false }
      end
    end
  end
end
