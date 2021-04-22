# frozen_string_literal: true

require 'stannum/rspec/validate_parameter_matcher'

RSpec.describe Stannum::RSpec::ValidateParameterMatcher do
  subject(:matcher) do
    described_class.new(
      method_name:    method_name,
      parameter_name: parameter_name
    )
  end

  let(:method_name)     { :call }
  let(:parameter_name)  { :record_class }
  let(:parameter_value) { nil }
  let(:implementation) do
    ->(
      action,
      record_class = Object,
      resource_id = nil,
      user:,
      auth_token: nil,
      role: 'User',
      &callback
    ) {}
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to respond_to(:new)
        .with(0).arguments
        .and_keywords(:method_name, :parameter_name)
    end
  end

  describe '.add_parameter_mapping' do
    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:add_parameter_mapping)
        .with(0).arguments
        .and_keywords(:map, :match)
    end

    describe 'with map: nil' do
      let(:error_message) do
        'map must be a Proc'
      end

      it 'should raise an exception' do
        expect { described_class.add_parameter_mapping map: nil, match: -> {} }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with map: an Object' do
      let(:error_message) do
        'map must be a Proc'
      end

      it 'should raise an exception' do
        expect do
          described_class.add_parameter_mapping(
            map:   Object.new.freeze,
            match: -> {}
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with match: nil' do
      let(:error_message) do
        'match must be a Proc'
      end

      it 'should raise an exception' do
        expect { described_class.add_parameter_mapping map: -> {}, match: nil }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with match: an Object' do
      let(:error_message) do
        'match must be a Proc'
      end

      it 'should raise an exception' do
        expect do
          described_class.add_parameter_mapping(
            map:   -> {},
            match: Object.new.freeze
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '.map_parameters' do
    let(:actual) { Spec::ExampleCommand.new }
    let(:parameters) do
      described_class.map_parameters(actual: actual, method_name: method_name)
    end
    let(:expected) do
      [
        %i[req action],
        %i[opt record_class],
        %i[opt resource_id],
        %i[keyreq user],
        %i[key auth_token],
        %i[key role],
        %i[block callback]
      ]
    end

    example_class 'Spec::ExampleCommand' do |klass|
      klass.include Stannum::ParameterValidation

      klass.define_method(:call) {}
    end

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:map_parameters)
        .with(0).arguments
        .and_keywords(:actual, :method_name)
    end

    describe 'with an unmapped method name' do
      let(:method_name) { :call }

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(:call) {}
      end

      it 'should return the superclass method parameters' do
        expect(parameters).to be == expected
      end
    end

    describe 'with a class and :new' do
      let(:actual)      { Spec::ExampleCommand }
      let(:method_name) { :new }

      before(:example) do
        Spec::ExampleCommand.define_method(:initialize, &implementation)
      end

      it 'should return the :initialize instance method parameters' do
        expect(parameters).to be == expected
      end
    end

    context 'when the matcher defines a parameter mapping' do
      let(:method_name) { :call }

      before(:example) do
        Spec::ExampleCommand.define_method(:process, &implementation)
      end

      around(:example) do |example|
        previous_mappings = described_class.send(:parameter_mappings).dup

        described_class.add_parameter_mapping(
          match: ->(method_name:, **_) { method_name == :call },
          map:   ->(actual:, **_)      { actual.method(:process).parameters }
        )

        example.call
      ensure
        described_class.instance_variable_set(
          :@parameter_mappings,
          previous_mappings
        )
      end

      it 'should return the :process method parameters' do
        expect(parameters).to be == expected
      end
    end
  end

  describe '#description' do
    let(:expected) do
      "validate the #{parameter_name.inspect} parameter"
    end

    include_examples 'should define reader', :description, -> { be == expected }
  end

  describe '#does_not_match?' do
    shared_examples 'should set the failure message' do
      it 'should set the failure message' do
        matcher.matches?(actual)

        expect(matcher.failure_message_when_negated).to be == failure_message
      end
    end

    let(:actual)         { Spec::ExampleCommand.new }
    let(:parameter_type) { 'parameter' }
    let(:failure_message) do
      "expected ##{method_name} not to validate the #{parameter_name.inspect}" \
      " #{parameter_type}"
    end

    example_class 'Spec::ExampleCommand' do |klass|
      klass.include Stannum::ParameterValidation

      klass.define_method(:call) {}
    end

    it { expect(matcher).to respond_to(:does_not_match?).with(1).argument }

    describe 'with an object that does not support parameter validation' do
      let(:actual) { Object.new }

      it { expect(matcher.does_not_match?(actual)).to be true }
    end

    describe 'with an object that does not respond to the method' do
      let(:method_name) { :do_nothing }
      let(:failure_message) do
        super() + ", but the object does not respond to ##{method_name}"
      end

      it { expect(matcher.does_not_match?(actual)).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an object that does not validate the method' do
      it { expect(matcher.does_not_match?(actual)).to be true }
    end

    describe 'with an object with a method that does not have the parameter' do
      let(:failure_message) do
        super() +
          ", but ##{method_name} does not have a #{parameter_name.inspect}" \
          ' parameter'
      end

      before(:example) do
        Spec::ExampleCommand.define_method(:call) {}

        Spec::ExampleCommand.validate_parameters(method_name) {}
      end

      it { expect(matcher.does_not_match?(actual)).to be false }

      include_examples 'should set the failure message'
    end

    context 'when the matcher has an expected constraint' do
      let(:constraint) { Stannum::Constraint.new }
      let(:matcher)    { super().using_constraint(constraint) }
      let(:error_message) do
        '#does_not_match? with #using_constraint is not supported'
      end

      it 'should raise an exception' do
        expect { matcher.does_not_match?(actual) }
          .to raise_error RuntimeError, error_message
      end
    end

    context 'when the matcher has an expected type' do
      let(:matcher) { super().using_constraint(String) }
      let(:error_message) do
        '#does_not_match? with #using_constraint is not supported'
      end

      it 'should raise an exception' do
        expect { matcher.does_not_match?(actual) }
          .to raise_error RuntimeError, error_message
      end
    end

    context 'when the matcher has a parameter value' do
      let(:matcher) { super().with_value(Object.new.freeze) }
      let(:error_message) do
        '#does_not_match? with #with_value is not supported'
      end

      it 'should raise an exception' do
        expect { matcher.does_not_match?(actual) }
          .to raise_error RuntimeError, error_message
      end
    end

    describe 'with a class with a method argument' do
      let(:actual)         { Spec::ExampleCommand }
      let(:parameter_name) { :record_class }
      let(:parameter_type) { 'argument' }
      let(:validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class, optional: true
        end
      end

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_singleton_method(:call, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end

    describe 'with a class with a method keyword' do
      let(:actual)         { Spec::ExampleCommand }
      let(:parameter_name) { :role }
      let(:parameter_type) { 'keyword' }
      let(:validations) do
        lambda do
          keyword :role, String
        end
      end

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_singleton_method(:call, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end

    describe 'with a class with a method block' do
      let(:actual)         { Spec::ExampleCommand }
      let(:parameter_name) { :callback }
      let(:parameter_type) { 'block' }

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_singleton_method(:call, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:validations) { -> {} }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        let(:validations) { -> { block true } }

        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end

    describe 'with an object with a method argument' do
      let(:parameter_name) { :record_class }
      let(:parameter_type) { 'argument' }
      let(:validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class, optional: true
        end
      end

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end

    describe 'with an object with a method keyword' do
      let(:parameter_name) { :role }
      let(:parameter_type) { 'keyword' }
      let(:validations) do
        lambda do
          keyword :role, String
        end
      end

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :auth_token }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end

    describe 'with an object with a method block' do
      let(:parameter_name) { :callback }
      let(:parameter_type) { 'block' }

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:validations) { -> {} }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        let(:validations) { -> { block true } }

        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end

    describe 'with a constructor method' do
      let(:actual)         { Spec::ExampleCommand }
      let(:method_name)    { :new }
      let(:parameter_name) { :record_class }
      let(:parameter_type) { 'argument' }
      let(:validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class, optional: true
        end
      end

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_method(:initialize, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }

        it { expect(matcher.does_not_match?(actual)).to be true }
      end

      context 'when the method validates the parameter' do
        it { expect(matcher.does_not_match?(actual)).to be false }

        include_examples 'should set the failure message'
      end
    end
  end

  describe '#expected_constraint' do
    include_examples 'should define reader', :expected_constraint, nil
  end

  describe '#failure_message' do
    include_examples 'should define reader', :failure_message
  end

  describe '#failure_message_when_negated' do
    include_examples 'should define reader', :failure_message_when_negated
  end

  describe '#matches?' do
    shared_examples 'should set the failure message' do
      it 'should set the failure message' do
        matcher.matches?(actual)

        expect(matcher.failure_message).to be == failure_message
      end
    end

    shared_examples 'should validate the parameter' do
      it 'should query the method parameters' do
        allow(described_class).to receive(:map_parameters).and_call_original

        matcher.matches?(actual)

        expect(described_class)
          .to have_received(:map_parameters)
          .with(actual: actual, method_name: method_name)
          .at_least(1).times
          .at_most(2).times
      end

      context 'when the method validation accepts nil values' do
        let(:failure_message) do
          super() +
            ", but #{parameter_value.inspect} is a valid value for the" \
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      context 'when the method validation does not accept nil values' do
        let(:validations) { required_validations }

        it { expect(matcher.matches?(actual)).to be true }

        context 'when the expected constraint is a constraint' do
          let(:matcher) { super().using_constraint(constraint) }

          context 'when the errors do not match the expected errors' do
            let(:constraint)          { Stannum::Constraints::Nothing.new }
            let(:expected_constraint) { constraint }
            let(:expected_errors)     { expected_constraint.errors_for(actual) }
            let(:failure_message) do
              matcher =
                RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
                .new(expected_errors.to_a)

              matcher.matches?(actual_constraint.errors_for(actual).to_a)

              super() +
                ", but the errors do not match:\n\n" +
                matcher.failure_message
            end

            it { expect(matcher.matches?(actual)).to be false }

            include_examples 'should set the failure message'
          end

          context 'when the errors match the expected errors' do
            let(:constraint) { actual_constraint }

            it { expect(matcher.matches?(actual)).to be true }
          end
        end

        context 'when the expected constraint is a type' do
          let(:matcher) { super().using_constraint(type) }
          let(:validations) do
            defined?(type_validations) ? type_validations : required_validations
          end
          let(:actual_constraint) do
            defined?(type_constraint) ? type_constraint : super()
          end

          context 'when the errors do not match the expected errors' do
            let(:type)                { Struct }
            let(:expected_constraint) { Stannum::Constraints::Type.new(type) }
            let(:expected_errors)     { expected_constraint.errors_for(actual) }
            let(:failure_message) do
              matcher =
                RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
                .new(expected_errors.to_a)

              matcher.matches?(actual_constraint.errors_for(actual).to_a)

              super() +
                ", but the errors do not match:\n\n" +
                matcher.failure_message
            end

            it { expect(matcher.matches?(actual)).to be false }

            include_examples 'should set the failure message'
          end

          context 'when the errors match the expected errors' do
            let(:type) { actual_type }

            it { expect(matcher.matches?(actual)).to be true }
          end
        end
      end

      context 'when the method validation accepts the custom value' do
        let(:matcher)         { super().with_value(parameter_value) }
        let(:parameter_value) { valid_value }
        let(:failure_message) do
          super() +
            ", but #{parameter_value.inspect} is a valid value for the" \
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      context 'when the method validation does not accept the custom value' do
        let(:matcher)         { super().with_value(parameter_value) }
        let(:parameter_value) { invalid_value }
        let(:validations)     { required_validations }
        let(:invalid_value) do
          defined?(super()) ? super() : Object.new.freeze
        end

        it { expect(matcher.matches?(actual)).to be true }

        context 'when the expected constraint is a constraint' do
          let(:matcher) { super().using_constraint(constraint) }

          context 'when the errors do not match the expected errors' do
            let(:constraint)          { Spec::CustomConstraint.new }
            let(:expected_constraint) { constraint }
            let(:expected_errors) do
              expected_constraint.errors_for(parameter_value)
            end
            let(:failure_message) do
              matcher =
                RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
                .new(expected_errors.to_a)

              matcher.matches?(actual_constraint.errors_for(actual).to_a)

              super() +
                ", but the errors do not match:\n\n" +
                matcher.failure_message
            end

            example_class 'Spec::CustomConstraint', \
              Stannum::Constraints::Nothing \
              do |klass|
                klass.define_method :update_errors_for do |actual:, errors:|
                  errors.add(type, message: message, value: actual.class.name)
                end
              end

            it { expect(matcher.matches?(actual)).to be false }

            include_examples 'should set the failure message'
          end

          context 'when the errors match the expected errors' do
            let(:constraint) { actual_constraint }

            it { expect(matcher.matches?(actual)).to be true }
          end
        end

        context 'when the expected constraint is a type' do
          let(:matcher) { super().using_constraint(type) }
          let(:validations) do
            defined?(type_validations) ? type_validations : required_validations
          end
          let(:actual_constraint) do
            defined?(type_constraint) ? type_constraint : super()
          end
          let(:invalid_value) do
            defined?(invalid_typed_value) ? invalid_typed_value : super()
          end

          context 'when the errors do not match the expected errors' do
            let(:type)                { Struct }
            let(:expected_constraint) { Stannum::Constraints::Type.new(type) }
            let(:expected_errors)     { expected_constraint.errors_for(actual) }
            let(:failure_message) do
              matcher =
                RSpec::SleepingKingStudios::Matchers::Core::DeepMatcher
                .new(expected_errors.to_a)

              matcher.matches?(actual_constraint.errors_for(actual).to_a)

              super() +
                ", but the errors do not match:\n\n" +
                matcher.failure_message
            end

            it { expect(matcher.matches?(actual)).to be false }

            include_examples 'should set the failure message'
          end

          context 'when the errors match the expected errors' do
            let(:type) { actual_type }

            it { expect(matcher.matches?(actual)).to be true }
          end
        end
      end
    end

    let(:actual)         { Spec::ExampleCommand.new }
    let(:parameter_type) { 'parameter' }
    let(:failure_message) do
      "expected ##{method_name} to validate the #{parameter_name.inspect}" \
      " #{parameter_type}"
    end

    example_class 'Spec::ExampleCommand' do |klass|
      klass.include Stannum::ParameterValidation

      klass.define_method(:call) {}
    end

    it { expect(matcher).to respond_to(:matches?).with(1).argument }

    describe 'with an object that does not support parameter validation' do
      let(:actual) { Object.new }
      let(:failure_message) do
        super() + ', but the object does not implement parameter validation'
      end

      it { expect(matcher.matches?(actual)).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an object that does not respond to the method' do
      let(:method_name) { :do_nothing }
      let(:failure_message) do
        super() + ", but the object does not respond to ##{method_name}"
      end

      it { expect(matcher.matches?(actual)).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an object that does not validate the method' do
      let(:failure_message) do
        super() +
          ", but the object does not validate the parameters of ##{method_name}"
      end

      it { expect(matcher.matches?(actual)).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with an object with a method that does not have the parameter' do
      let(:failure_message) do
        super() +
          ", but ##{method_name} does not have a #{parameter_name.inspect}" \
          ' parameter'
      end

      before(:example) do
        Spec::ExampleCommand.define_method(:call) {}

        Spec::ExampleCommand.validate_parameters(method_name) {}
      end

      it { expect(matcher.matches?(actual)).to be false }

      include_examples 'should set the failure message'
    end

    describe 'with a class with a method argument' do
      let(:actual)            { Spec::ExampleCommand }
      let(:parameter_name)    { :record_class }
      let(:parameter_type)    { 'argument' }
      let(:required_name)     { :action }
      let(:valid_value)       { String }
      let(:actual_type)       { Class }
      let(:actual_constraint) { Stannum::Constraints::Type.new(Class) }
      let(:validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class, optional: true
        end
      end
      let(:required_validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class
        end
      end

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_singleton_method(:call, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }
        let(:failure_message) do
          super() +
            ", but ##{method_name} does not expect a"\
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      include_examples 'should validate the parameter'
    end

    describe 'with a class with a method keyword' do
      let(:actual)            { Spec::ExampleCommand }
      let(:parameter_name)    { :role }
      let(:parameter_type)    { 'keyword' }
      let(:valid_value)       { 'admin' }
      let(:actual_type)       { String }
      let(:actual_constraint) { Stannum::Constraints::Type.new(String) }
      let(:validations) do
        lambda do
          keyword :role, String, optional: true
          keyword :user, Spec::ExampleUser
        end
      end
      let(:required_validations) do
        lambda do
          keyword :role, String
          keyword :user, Spec::ExampleUser
        end
      end

      example_class 'Spec::ExampleUser'

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_singleton_method(:call, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :auth_token }
        let(:failure_message) do
          super() +
            ", but ##{method_name} does not expect a"\
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      include_examples 'should validate the parameter'
    end

    describe 'with a class with a method block' do
      let(:actual)              { Spec::ExampleCommand }
      let(:parameter_name)      { :callback }
      let(:parameter_type)      { 'block' }
      let(:invalid_value)       { -> {} }
      let(:valid_value)         { ->(_) {} }
      let(:invalid_typed_value) { nil }
      let(:actual_type)         { Proc }
      let(:actual_constraint) do
        Stannum::Constraint.new { |block| block&.arity == 1 }
      end
      let(:type_constraint) do
        Stannum::Constraints::Type.new(Proc)
      end
      let(:validations) do
        lambda do
          argument :action, Symbol

          block Stannum::Constraints::Type.new(Proc, optional: true)
        end
      end
      let(:required_validations) do
        lambda do
          argument :action, Symbol

          block(Stannum::Constraint.new { |block| block&.arity == 1 })
        end
      end
      let(:type_validations) do
        lambda do
          argument :action, Symbol

          block Stannum::Constraints::Type.new(Proc)
        end
      end

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_singleton_method(:call, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      include_examples 'should validate the parameter'
    end

    describe 'with an object with a method argument' do
      let(:parameter_name)    { :record_class }
      let(:parameter_type)    { 'argument' }
      let(:required_name)     { :action }
      let(:valid_value)       { String }
      let(:actual_type)       { Class }
      let(:actual_constraint) { Stannum::Constraints::Type.new(Class) }
      let(:validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class, optional: true
        end
      end
      let(:required_validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class
        end
      end

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }
        let(:failure_message) do
          super() +
            ", but ##{method_name} does not expect a"\
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      include_examples 'should validate the parameter'
    end

    describe 'with an object with a method keyword' do
      let(:parameter_name)    { :role }
      let(:parameter_type)    { 'keyword' }
      let(:valid_value)       { 'admin' }
      let(:actual_type)       { String }
      let(:actual_constraint) { Stannum::Constraints::Type.new(String) }
      let(:validations) do
        lambda do
          keyword :role, String, optional: true
          keyword :user, Spec::ExampleUser
        end
      end
      let(:required_validations) do
        lambda do
          keyword :role, String
          keyword :user, Spec::ExampleUser
        end
      end

      example_class 'Spec::ExampleUser'

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :auth_token }
        let(:failure_message) do
          super() +
            ", but ##{method_name} does not expect a"\
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      include_examples 'should validate the parameter'
    end

    describe 'with an object with a method block' do
      let(:parameter_name)      { :callback }
      let(:parameter_type)      { 'block' }
      let(:invalid_value)       { -> {} }
      let(:valid_value)         { ->(_) {} }
      let(:invalid_typed_value) { nil }
      let(:actual_type)         { Proc }
      let(:actual_constraint) do
        Stannum::Constraint.new { |block| block&.arity == 1 }
      end
      let(:type_constraint) do
        Stannum::Constraints::Type.new(Proc)
      end
      let(:validations) do
        lambda do
          argument :action, Symbol

          block Stannum::Constraints::Type.new(Proc, optional: true)
        end
      end
      let(:required_validations) do
        lambda do
          argument :action, Symbol

          block(Stannum::Constraint.new { |block| block&.arity == 1 })
        end
      end
      let(:type_validations) do
        lambda do
          argument :action, Symbol

          block Stannum::Constraints::Type.new(Proc)
        end
      end

      before(:example) do
        Spec::ExampleCommand.define_method(:call, &implementation)

        Spec::ExampleCommand.validate_parameters(method_name, &validations)
      end

      include_examples 'should validate the parameter'
    end

    describe 'with a constructor method' do
      let(:actual)            { Spec::ExampleCommand }
      let(:method_name)       { :new }
      let(:parameter_name)    { :record_class }
      let(:parameter_type)    { 'argument' }
      let(:required_name)     { :action }
      let(:valid_value)       { String }
      let(:actual_type)       { Class }
      let(:actual_constraint) { Stannum::Constraints::Type.new(Class) }
      let(:validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class, optional: true
        end
      end
      let(:required_validations) do
        lambda do
          argument :action,       Symbol
          argument :record_class, Class
        end
      end

      before(:example) do
        Spec::ExampleCommand.extend(Stannum::ParameterValidation)

        Spec::ExampleCommand.define_method(:initialize, &implementation)

        Spec::ExampleCommand
          .singleton_class
          .validate_parameters(method_name, &validations)
      end

      context 'when the method does not validate the parameter' do
        let(:parameter_name) { :resource_id }
        let(:failure_message) do
          super() +
            ", but ##{method_name} does not expect a"\
            " #{parameter_name.inspect} #{parameter_type}"
        end

        it { expect(matcher.matches?(actual)).to be false }

        include_examples 'should set the failure message'
      end

      include_examples 'should validate the parameter'
    end

    describe 'with a custom validation' do
      let(:constraint)     { Stannum::Constraints::Presence.new }
      let(:parameter_name) { :value }

      before(:example) do
        value_constraint = constraint

        Spec::ExampleCommand.define_method(:call) do |value|
          contract = Stannum::Contracts::ParametersContract.new do
            argument :value, value_constraint
          end

          match_parameters_to_contract(
            arguments:   [value],
            contract:    contract,
            method_name: :call
          )

          # :nocov:
          raise 'Something went wrong.'
          # :nocov:
        end

        Spec::ExampleCommand.validate_parameters :call do
          argument :value, Object
        end
      end

      it 'should query the method parameters' do
        allow(described_class).to receive(:map_parameters).and_call_original

        matcher.matches?(actual)

        expect(described_class)
          .to have_received(:map_parameters)
          .with(actual: actual, method_name: method_name)
          .at_least(1).times
          .at_most(2).times
      end

      it { expect(matcher.matches?(actual)).to be true }

      it 'should not call the method implementation' do
        expect { matcher.matches?(actual) }
          .not_to raise_error
      end
    end
  end

  describe '#method_name' do
    include_examples 'should define reader', :method_name, -> { method_name }
  end

  describe '#parameter_name' do
    include_examples 'should define reader',
      :parameter_name,
      -> { parameter_name }
  end

  describe '#parameter_value' do
    include_examples 'should define reader', :parameter_value, nil
  end

  describe '#using_constraint' do
    it 'should define the method' do
      expect(matcher)
        .to respond_to(:using_constraint)
        .with(1).argument
        .and_any_keywords
    end

    describe 'with nil' do
      let(:error_message) do
        'constraint must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { matcher.using_constraint(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) do
        'constraint must be a Class or Module or a constraint'
      end

      it 'should raise an exception' do
        expect { matcher.using_constraint(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a constraint instance' do
      let(:constraint) { Stannum::Constraints::Presence.new }
      let(:options)    { {} }
      let(:expected_constraint) do
        constraint.with_options(**options)
      end

      it { expect(matcher.using_constraint(constraint)).to be matcher }

      it 'should set the expected constraint' do
        expect { matcher.using_constraint(constraint) }
          .to change(matcher, :expected_constraint)
          .to be == expected_constraint
      end

      describe 'with options' do
        let(:options) { { key: :value } }

        it 'should set the expected constraint' do
          expect { matcher.using_constraint(constraint, **options) }
            .to change(matcher, :expected_constraint)
            .to be == expected_constraint
        end
      end
    end

    describe 'with a type' do
      let(:type)    { String }
      let(:options) { {} }
      let(:expected_constraint) do
        Stannum::Constraints::Type.new(type, **options)
      end

      it { expect(matcher.using_constraint(type)).to be matcher }

      it 'should set the expected constraint' do
        expect { matcher.using_constraint(type) }
          .to change(matcher, :expected_constraint)
          .to be == expected_constraint
      end

      describe 'with options' do
        let(:options) { { key: :value } }

        it 'should set the expected constraint' do
          expect { matcher.using_constraint(type, **options) }
            .to change(matcher, :expected_constraint)
            .to be == expected_constraint
        end
      end
    end
  end

  describe '#with_value' do
    let(:parameter_value) { 'invalid value' }

    it { expect(matcher).to respond_to(:with_value).with(1).argument }

    it { expect(matcher.with_value(parameter_value)).to be matcher }

    it 'should set the parameter value' do
      expect { matcher.with_value(parameter_value) }
        .to change(matcher, :parameter_value)
        .to be == parameter_value
    end
  end
end
