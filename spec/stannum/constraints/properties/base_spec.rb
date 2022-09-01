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
        Object.send(:remove_const, :Rails) if Rails == rails
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
end
