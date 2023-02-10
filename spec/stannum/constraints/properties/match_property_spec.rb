# frozen_string_literal: true

require 'stannum/constraints/properties/match_property'

require 'support/examples/constraint_examples'

RSpec.describe Stannum::Constraints::Properties::MatchProperty do
  include Spec::Support::Examples::ConstraintExamples

  subject(:constraint) do
    described_class.new(reference_name, *property_names, **constructor_options)
  end

  shared_context 'when initialized with multiple property names' do
    let(:property_names) { %w[confirmation verification] }
  end

  let(:reference_name)      { 'launch_date' }
  let(:property_names)      { %w[confirmation] }
  let(:constructor_options) { {} }
  let(:expected_options) do
    {
      allow_empty:    false,
      allow_nil:      false,
      property_names: property_names,
      reference_name: reference_name
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

  describe '::NEGATED_TYPE' do
    include_examples 'should define frozen constant',
      :NEGATED_TYPE,
      Stannum::Constraints::Equality::NEGATED_TYPE
  end

  describe '::TYPE' do
    include_examples 'should define frozen constant',
      :TYPE,
      Stannum::Constraints::Equality::TYPE
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(2).arguments
        .and_unlimited_arguments
        .and_keywords(:allow_empty, :allow_nil)
        .and_any_keywords
    end

    describe 'with property_names: an empty Array' do
      let(:error_message) { "property names can't be empty" }

      it 'should raise an error' do
        expect { described_class.new(reference_name) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with nil' do
      let(:error_message) { "property name at 1 can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(reference_name, *property_names, nil) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with an Object' do
      let(:object)        { Object.new.freeze }
      let(:error_message) { 'property name at 1 is not a String or a Symbol' }

      it 'should raise an error' do
        expect { described_class.new(reference_name, *property_names, object) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with an empty String' do
      let(:error_message) { "property name at 1 can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(reference_name, *property_names, '') }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with property_names: an Array with an empty Symbol' do
      let(:error_message) { "property name at 1 can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(reference_name, *property_names, :'') }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with reference_name: nil' do
      let(:error_message) { "reference name can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(nil, *property_names) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with reference_name: an Object' do
      let(:error_message) { 'reference name is not a String or a Symbol' }

      it 'should raise an error' do
        expect { described_class.new(Object.new.freeze, *property_names) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with reference_name: an empty String' do
      let(:error_message) { "reference name can't be blank" }

      it 'should raise an error' do
        expect { described_class.new('', *property_names) }
          .to raise_error(ArgumentError, error_message)
      end
    end

    describe 'with reference_name: an empty Symbol' do
      let(:error_message) { "reference name can't be blank" }

      it 'should raise an error' do
        expect { described_class.new(:'', *property_names) }
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

    context 'when the reference name matches a filter' do
      let(:reference_name) { 'password' }

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

  describe '#match' do
    example_class 'Spec::ExampleStruct', Struct.new(:launch_date, :confirmation)

    let(:match_method) { :match }
    let(:expected_messages) do
      expected_errors.merge(message: 'is not equal to')
    end

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            methods: %i[[]],
            missing: %i[[]]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            methods: %i[[]],
            missing: %i[[]]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: nil and property: nil' do
      let(:actual) { Spec::ExampleStruct.new(nil, nil) }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: nil and property: empty' do
      let(:actual) { Spec::ExampleStruct.new(nil, '') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: nil, actual: '' }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: nil and property: value' do
      let(:actual) { Spec::ExampleStruct.new(nil, '1982-07-09') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: nil, actual: '1982-07-09' }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: empty and property: nil' do
      let(:actual) { Spec::ExampleStruct.new('', nil) }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: '', actual: nil }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: empty and property: empty' do
      let(:actual) { Spec::ExampleStruct.new('', '') }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: empty and property: value' do
      let(:actual) { Spec::ExampleStruct.new('', '1982-07-09') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: '', actual: '1982-07-09' }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: value and property: nil' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', nil) }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: '1982-07-09', actual: nil }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: value and property: empty' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', '') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: '1982-07-09', actual: '' }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: value and property: other' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', '2010-12-17') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::TYPE,
          path: %w[confirmation],
          data: { expected: '1982-07-09', actual: '2010-12-17' }
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: value and property: value' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', '1982-07-09') }

      include_examples 'should match the constraint'
    end

    context 'when the parameter names are filtered' do
      example_class 'Spec::ExampleLogin', Struct.new(:password, :confirmation)

      describe 'with an object with reference: value and property: other' do
        let(:reference_name) { 'password' }
        let(:actual) do
          Spec::ExampleLogin.new('tronlives', 'ifightfortheusers')
        end
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: '[FILTERED]', actual: '[FILTERED]' }
          }
        end

        include_examples 'should not match the constraint'
      end
    end

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }

      describe 'with an object with reference: nil and property: nil' do
        let(:actual) { Spec::ExampleStruct.new(nil, nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: nil and property: empty' do
        let(:actual) { Spec::ExampleStruct.new(nil, '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: nil and property: value' do
        let(:actual) { Spec::ExampleStruct.new(nil, '1982-07-09') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: nil, actual: '1982-07-09' }
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: empty and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('', nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('', '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: value' do
        let(:actual) { Spec::ExampleStruct.new('', '1982-07-09') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', nil) }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: '1982-07-09', actual: nil }
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: value and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: other' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '2010-12-17') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: '1982-07-09', actual: '2010-12-17' }
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: value and property: value' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '1982-07-09') }

        include_examples 'should match the constraint'
      end
    end

    context 'when initialized with allow_nil: true' do
      let(:constructor_options) { super().merge(allow_nil: true) }

      describe 'with an object with reference: nil and property: nil' do
        let(:actual) { Spec::ExampleStruct.new(nil, nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: nil and property: empty' do
        let(:actual) { Spec::ExampleStruct.new(nil, '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: nil and property: value' do
        let(:actual) { Spec::ExampleStruct.new(nil, '1982-07-09') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('', nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('', '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: value' do
        let(:actual) { Spec::ExampleStruct.new('', '1982-07-09') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: '', actual: '1982-07-09' }
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: value and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: '1982-07-09', actual: '' }
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: value and property: other' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '2010-12-17') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::TYPE,
            path: %w[confirmation],
            data: { expected: '1982-07-09', actual: '2010-12-17' }
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: value and property: value' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '1982-07-09') }

        include_examples 'should match the constraint'
      end
    end

    wrap_context 'when initialized with multiple property names' do
      example_class 'Spec::ComplexStruct',
        Struct.new(:launch_date, :confirmation, :verification)

      describe 'with an object with non-matching property value' do
        let(:actual) do
          Spec::ComplexStruct.new('1982-07-09', '2010-12-17', '2012-05-20')
        end
        let(:expected_errors) do
          [
            {
              type: Stannum::Constraints::Equality::TYPE,
              path: %w[confirmation],
              data: { expected: '1982-07-09', actual: '2010-12-17' }
            },
            {
              type: Stannum::Constraints::Equality::TYPE,
              path: %w[verification],
              data: { expected: '1982-07-09', actual: '2012-05-20' }
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'is not equal to')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with partially-matching property value' do
        let(:actual) do
          Spec::ComplexStruct.new('1982-07-09', '1982-07-09', '2012-05-20')
        end
        let(:expected_errors) do
          [
            {
              type: Stannum::Constraints::Equality::TYPE,
              path: %w[verification],
              data: { expected: '1982-07-09', actual: '2012-05-20' }
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'is not equal to')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with matching property value' do
        let(:actual) do
          Spec::ComplexStruct.new('1982-07-09', '1982-07-09', '1982-07-09')
        end

        include_examples 'should match the constraint'
      end
    end
  end

  describe '#negated_match' do
    example_class 'Spec::ExampleStruct', Struct.new(:launch_date, :confirmation)

    let(:match_method) { :negated_match }
    let(:expected_messages) do
      expected_errors.merge(message: 'is equal to')
    end

    describe 'with nil' do
      let(:actual) { nil }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            methods: %i[[]],
            missing: %i[[]]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an Object' do
      let(:actual) { Object.new.freeze }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Signature::TYPE,
          data: {
            methods: %i[[]],
            missing: %i[[]]
          }
        }
      end
      let(:expected_messages) do
        expected_errors.merge(message: 'does not respond to the methods')
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: nil and property: nil' do
      let(:actual) { Spec::ExampleStruct.new(nil, nil) }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::NEGATED_TYPE,
          path: %w[confirmation]
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: nil and property: empty' do
      let(:actual) { Spec::ExampleStruct.new(nil, '') }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: nil and property: value' do
      let(:actual) { Spec::ExampleStruct.new(nil, '1982-07-09') }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: empty and property: nil' do
      let(:actual) { Spec::ExampleStruct.new('', nil) }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: empty and property: empty' do
      let(:actual) { Spec::ExampleStruct.new('', '') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::NEGATED_TYPE,
          path: %w[confirmation]
        }
      end

      include_examples 'should not match the constraint'
    end

    describe 'with an object with reference: empty and property: value' do
      let(:actual) { Spec::ExampleStruct.new('', '1982-07-09') }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: value and property: nil' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', nil) }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: value and property: empty' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', '') }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: value and property: other' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', '2010-12-17') }

      include_examples 'should match the constraint'
    end

    describe 'with an object with reference: value and property: value' do
      let(:actual) { Spec::ExampleStruct.new('1982-07-09', '1982-07-09') }
      let(:expected_errors) do
        {
          type: Stannum::Constraints::Equality::NEGATED_TYPE,
          path: %w[confirmation]
        }
      end

      include_examples 'should not match the constraint'
    end

    context 'when initialized with allow_empty: true' do
      let(:constructor_options) { super().merge(allow_empty: true) }

      describe 'with an object with reference: nil and property: nil' do
        let(:actual) { Spec::ExampleStruct.new(nil, nil) }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::NEGATED_TYPE,
            path: %w[confirmation]
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: nil and property: empty' do
        let(:actual) { Spec::ExampleStruct.new(nil, '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: nil and property: value' do
        let(:actual) { Spec::ExampleStruct.new(nil, '1982-07-09') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('', nil) }
        let(:expected_errors) do
          { type: Stannum::Constraints::Base::NEGATED_TYPE }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is valid')
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: empty and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('', '') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::NEGATED_TYPE,
            path: %w[confirmation]
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: empty and property: value' do
        let(:actual) { Spec::ExampleStruct.new('', '1982-07-09') }
        let(:expected_errors) do
          { type: Stannum::Constraints::Base::NEGATED_TYPE }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is valid')
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: value and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: other' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '2010-12-17') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: value' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '1982-07-09') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::NEGATED_TYPE,
            path: %w[confirmation]
          }
        end

        include_examples 'should not match the constraint'
      end
    end

    context 'when initialized with allow_nil: true' do
      let(:constructor_options) { super().merge(allow_nil: true) }

      describe 'with an object with reference: nil and property: nil' do
        let(:actual) { Spec::ExampleStruct.new(nil, nil) }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::NEGATED_TYPE,
            path: %w[confirmation]
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: nil and property: empty' do
        let(:actual) { Spec::ExampleStruct.new(nil, '') }
        let(:expected_errors) do
          { type: Stannum::Constraints::Base::NEGATED_TYPE }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is valid')
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: nil and property: value' do
        let(:actual) { Spec::ExampleStruct.new(nil, '1982-07-09') }
        let(:expected_errors) do
          { type: Stannum::Constraints::Base::NEGATED_TYPE }
        end
        let(:expected_messages) do
          expected_errors.merge(message: 'is valid')
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: empty and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('', nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: empty and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('', '') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::NEGATED_TYPE,
            path: %w[confirmation]
          }
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with reference: empty and property: value' do
        let(:actual) { Spec::ExampleStruct.new('', '1982-07-09') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: nil' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', nil) }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: empty' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: other' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '2010-12-17') }

        include_examples 'should match the constraint'
      end

      describe 'with an object with reference: value and property: value' do
        let(:actual) { Spec::ExampleStruct.new('1982-07-09', '1982-07-09') }
        let(:expected_errors) do
          {
            type: Stannum::Constraints::Equality::NEGATED_TYPE,
            path: %w[confirmation]
          }
        end

        include_examples 'should not match the constraint'
      end
    end

    wrap_context 'when initialized with multiple property names' do
      example_class 'Spec::ComplexStruct',
        Struct.new(:launch_date, :confirmation, :verification)

      describe 'with an object with non-matching property value' do
        let(:actual) do
          Spec::ComplexStruct.new('1982-07-09', '2010-12-17', '2012-05-20')
        end

        include_examples 'should match the constraint'
      end

      describe 'with an object with partially-matching property value' do
        let(:actual) do
          Spec::ComplexStruct.new('1982-07-09', '1982-07-09', '2012-05-20')
        end
        let(:expected_errors) do
          [
            {
              type: Stannum::Constraints::Equality::NEGATED_TYPE,
              path: %w[confirmation]
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'is equal to')
          end
        end

        include_examples 'should not match the constraint'
      end

      describe 'with an object with matching property value' do
        let(:actual) do
          Spec::ComplexStruct.new('1982-07-09', '1982-07-09', '1982-07-09')
        end
        let(:expected_errors) do
          [
            {
              type: Stannum::Constraints::Equality::NEGATED_TYPE,
              path: %w[confirmation]
            },
            {
              type: Stannum::Constraints::Equality::NEGATED_TYPE,
              path: %w[verification]
            }
          ]
        end
        let(:expected_messages) do
          expected_errors.map do |err|
            err.merge(message: 'is equal to')
          end
        end

        include_examples 'should not match the constraint'
      end
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

  describe '#reference_name' do
    include_examples 'should define reader',
      :reference_name,
      -> { reference_name }
  end
end
