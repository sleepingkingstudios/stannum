# frozen_string_literal: true

require 'stannum/parameter_validation'

RSpec.describe Stannum::ParameterValidation do
  example_class 'Spec::ExampleClass' do |klass|
    klass.include(Stannum::ParameterValidation) # rubocop:disable RSpec/DescribedClass

    klass.define_method(:custom_method) do |*arguments, **keywords|
      inner_method(*arguments, **keywords)
    end

    klass.define_method(:inner_method) { |*_, **_| nil }
  end

  describe '::MethodValidations' do
    subject(:validations) { described_class.new }

    let(:described_class) { Stannum::ParameterValidation::MethodValidations }

    describe '#add_contract' do
      let(:method_name) { :do_something }
      let(:contract)    { Stannum::Contract.new }

      it { expect(validations).to respond_to(:add_contract).with(2).arguments }

      it 'should add the contract to the contracts' do
        expect { validations.add_contract(method_name, contract) }
          .to change(validations, :contracts)
          .to(satisfy { |contracts| contracts[method_name] = contract })
      end
    end

    describe '#contracts' do
      include_examples 'should define reader', :contracts, -> { {} }

      context 'when there is a contract defined' do
        let(:method_name) { :do_something }
        let(:contract)    { Stannum::Contract.new }
        let(:expected)    { { method_name => contract } }

        before(:example) do
          validations.add_contract(method_name, contract)
        end

        it { expect(validations.contracts).to be == expected }
      end

      context 'with included validations from a parent class' do
        let(:included) { described_class.new }

        before(:example) do
          validations.include(included)
        end

        context 'when there is a contract defined on the parent class' do
          let(:parent_method_name) { :do_something_else }
          let(:parent_contract)    { Stannum::Contract.new }
          let(:expected)           { { parent_method_name => parent_contract } }

          before(:example) do
            included.add_contract(parent_method_name, parent_contract)
          end

          it { expect(validations.contracts).to be == expected }

          it { expect(included.contracts).to be == expected }
        end

        context 'when there is a contract defined on the subclass' do
          let(:method_name) { :do_something }
          let(:contract)    { Stannum::Contract.new }
          let(:expected)    { { method_name => contract } }

          before(:example) do
            validations.add_contract(method_name, contract)
          end

          it { expect(validations.contracts).to be == expected }

          it { expect(included.contracts).to be == {} }
        end

        context 'when there are contracts defined on the parent class and ' \
                'subclass' \
        do
          let(:method_name)        { :do_something }
          let(:contract)           { Stannum::Contract.new }
          let(:parent_method_name) { :do_something_else }
          let(:parent_contract)    { Stannum::Contract.new }
          let(:expected) do
            {
              method_name        => contract,
              parent_method_name => parent_contract
            }
          end
          let(:parent_expected) { { parent_method_name => parent_contract } }

          before(:example) do
            included.add_contract(parent_method_name, parent_contract)

            validations.add_contract(method_name, contract)
          end

          it { expect(validations.contracts).to be == expected }

          it { expect(included.contracts).to be == parent_expected }
        end

        context 'when the subclass overrides a contract defined on the ' \
                'parent class' \
        do
          let(:method_name)        { :do_something }
          let(:contract)           { Stannum::Contract.new }
          let(:parent_contract)    { Stannum::Contract.new }
          let(:expected)           { { method_name => contract } }
          let(:parent_expected)    { { method_name => parent_contract } }

          before(:example) do
            included.add_contract(method_name, parent_contract)

            validations.add_contract(method_name, contract)
          end

          it { expect(validations.contracts).to be == expected }

          it { expect(included.contracts).to be == parent_expected }
        end
      end
    end
  end

  describe '.extended' do
    let(:other) { Class.new.extend(Stannum::ParameterValidation) } # rubocop:disable RSpec/DescribedClass

    it 'should define the ::MethodValidations constant' do
      expect(other.singleton_class::MethodValidations)
        .to be_a described_class::MethodValidations
    end

    it 'should initialize the contracts' do
      expect(other.singleton_class::MethodValidations.contracts).to be == {}
    end

    it 'should add ::MethodValidations to ancestors' do
      expect(other.singleton_class.ancestors)
        .to include other.singleton_class::MethodValidations
    end
  end

  describe '.included' do
    let(:other) { Spec::ExampleClass }

    it 'should define the ::MethodValidations constant' do
      expect(other::MethodValidations)
        .to be_a described_class::MethodValidations
    end

    it 'should initialize the contracts' do
      expect(other::MethodValidations.contracts).to be == {}
    end

    it 'should add ::MethodValidations to ancestors' do
      expect(other.ancestors).to include other::MethodValidations
    end
  end

  describe '.inherited' do
    let(:other) { Spec::ExampleSubclass }

    example_class 'Spec::ExampleSubclass', 'Spec::ExampleClass'

    it 'should define the ::MethodValidations constant' do
      expect(other::MethodValidations)
        .to be_a described_class::MethodValidations
    end

    it 'should not be the superclass validations constant' do
      expect(other::MethodValidations)
        .not_to be Spec::ExampleClass::MethodValidations
    end

    it 'should initialize the contracts' do
      expect(other::MethodValidations.contracts).to be == {}
    end

    it 'should add ::MethodValidations to ancestors' do
      expect(other.ancestors).to include other::MethodValidations
    end
  end

  describe '.validate_parameters' do
    subject(:instance) { Spec::ExampleClass.new }

    let(:method_name) { :custom_method }
    let(:validations) { -> {} }

    it 'should define the class method' do
      expect(Spec::ExampleClass)
        .to respond_to(:validate_parameters)
        .with(1).argument
        .and_a_block
    end

    it 'should define a method on ::MethodValidations' do
      Spec::ExampleClass.validate_parameters(method_name, &validations)

      expect(Object.new.extend(Spec::ExampleClass::MethodValidations))
        .to respond_to(method_name)
        .with_unlimited_arguments
        .and_any_keywords
        .and_a_block
    end

    it 'should add a parameters contract to ::MethodValidations' do
      Spec::ExampleClass.validate_parameters(method_name, &validations)

      expect(Spec::ExampleClass::MethodValidations.contracts[method_name])
        .to be_a Stannum::Contracts::ParametersContract
    end

    context 'when the method is called' do
      let(:arguments) { %w[ichi ni san] }
      let(:keywords)  { { one: 1, two: 2, three: 3 } }
      let(:block)     { -> {} }
      let(:match)     { true }
      let(:errors)    { Stannum::Errors.new }
      let(:contract) do
        Spec::ExampleClass::MethodValidations.contracts[method_name]
      end

      before(:example) do
        Spec::ExampleClass.validate_parameters(method_name, &validations)
      end

      it 'should call the contract' do
        allow(contract).to receive(:match).and_return(match, errors)

        begin
          instance.send(method_name, *arguments, **keywords, &block)
        rescue ArgumentError
          # Do nothing.
        end

        expect(contract)
          .to have_received(:match)
          .with(arguments: arguments, block: block, keywords: keywords)
      end

      context 'when the parameters do not match the contract' do
        let(:expected_errors) do
          Stannum::Contracts::ParametersContract
            .new(&validations)
            .errors_for(
              {
                arguments: arguments,
                keywords:  keywords,
                block:     block
              }
            )
        end

        # rubocop:disable RSpec/SubjectStub
        it 'should call the error handler' do
          allow(instance).to receive(:handle_invalid_parameters)

          instance.send(method_name, *arguments, **keywords, &block)

          expect(instance)
            .to have_received(:handle_invalid_parameters)
            .with(errors: expected_errors, method_name: method_name)
        end

        it 'should not call the method implementation' do
          allow(instance).to receive(:handle_invalid_parameters)
          allow(instance).to receive(:inner_method)

          instance.send(method_name, *arguments, **keywords, &block)

          expect(instance).not_to have_received(:inner_method)
        end
        # rubocop:enable RSpec/SubjectStub

        context 'when the subclass defines a custom handler' do
          before(:example) do
            Spec::ExampleClass.define_method(:handle_invalid_parameters) \
            do |**_|
              :failure
            end
          end

          it 'should call the custom handler' do
            expect(instance.send(method_name, *arguments, **keywords, &block))
              .to be :failure
          end
        end
      end

      context 'when the parameters match the contract' do
        let(:validations) do
          lambda do
            arguments :args,   String
            keywords  :kwargs, Integer
          end
        end

        # rubocop:disable RSpec/SubjectStub
        it 'should call the method implementation' do
          allow(instance).to receive(:inner_method)

          instance.send(method_name, *arguments, **keywords, &block)

          expect(instance).to have_received(:inner_method)
            .with(*arguments, **keywords)
        end
        # rubocop:enable RSpec/SubjectStub
      end
    end

    context 'with a subclass' do
      subject(:instance) { Spec::ExampleClass.new }

      example_class 'Spec::ExampleSubclass', 'Spec::ExampleClass'

      context 'with a validation on the parent class' do
        it 'should add a parameters contract to ::MethodValidations' do
          Spec::ExampleClass.validate_parameters(method_name, &validations)

          expect(
            Spec::ExampleSubclass::MethodValidations.contracts[method_name]
          )
            .to be_a Stannum::Contracts::ParametersContract
        end

        # rubocop:disable RSpec/NestedGroups
        context 'when the method is called' do
          let(:arguments) { %w[ichi ni san] }
          let(:keywords)  { { one: 1, two: 2, three: 3 } }
          let(:block)     { -> {} }
          let(:match)     { true }
          let(:errors)    { Stannum::Errors.new }
          let(:contract) do
            Spec::ExampleClass::MethodValidations.contracts[method_name]
          end

          before(:example) do
            Spec::ExampleClass.validate_parameters(method_name, &validations)
          end

          it 'should call the contract' do
            allow(contract).to receive(:match).and_return(match, errors)

            begin
              instance.send(method_name, *arguments, **keywords, &block)
            rescue ArgumentError
              # Do nothing.
            end

            expect(contract)
              .to have_received(:match)
              .with(arguments: arguments, block: block, keywords: keywords)
          end

          context 'when the parameters do not match the contract' do
            let(:expected_errors) do
              Stannum::Contracts::ParametersContract
                .new(&validations)
                .errors_for(
                  {
                    arguments: arguments,
                    keywords:  keywords,
                    block:     block
                  }
                )
            end

            # rubocop:disable RSpec/SubjectStub
            it 'should call the error handler' do
              allow(instance).to receive(:handle_invalid_parameters)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance)
                .to have_received(:handle_invalid_parameters)
                .with(errors: expected_errors, method_name: method_name)
            end

            it 'should not call the method implementation' do
              allow(instance).to receive(:handle_invalid_parameters)
              allow(instance).to receive(:inner_method)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance).not_to have_received(:inner_method)
            end
            # rubocop:enable RSpec/SubjectStub

            context 'when the subclass defines a custom handler' do
              before(:example) do
                Spec::ExampleClass.define_method(:handle_invalid_parameters) \
                do |**_|
                  :failure
                end
              end

              it 'should call the custom handler' do
                expect(
                  instance.send(method_name, *arguments, **keywords, &block)
                )
                  .to be :failure
              end
            end
          end

          context 'when the parameters match the contract' do
            let(:validations) do
              lambda do
                arguments :args,   String
                keywords  :kwargs, Integer
              end
            end

            # rubocop:disable RSpec/SubjectStub
            it 'should call the method implementation' do
              allow(instance).to receive(:inner_method)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance).to have_received(:inner_method)
                .with(*arguments, **keywords)
            end
            # rubocop:enable RSpec/SubjectStub
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end

      context 'with a validation on the subclass' do
        it 'should add a parameters contract to ::MethodValidations' do
          Spec::ExampleSubclass.validate_parameters(method_name, &validations)

          expect(
            Spec::ExampleSubclass::MethodValidations.contracts[method_name]
          )
            .to be_a Stannum::Contracts::ParametersContract
        end

        # rubocop:disable RSpec/NestedGroups
        context 'when the method is called' do
          let(:arguments) { %w[ichi ni san] }
          let(:keywords)  { { one: 1, two: 2, three: 3 } }
          let(:block)     { -> {} }
          let(:match)     { true }
          let(:errors)    { Stannum::Errors.new }
          let(:contract) do
            Spec::ExampleClass::MethodValidations.contracts[method_name]
          end

          before(:example) do
            Spec::ExampleClass.validate_parameters(method_name, &validations)
          end

          it 'should call the contract' do
            allow(contract).to receive(:match).and_return(match, errors)

            begin
              instance.send(method_name, *arguments, **keywords, &block)
            rescue ArgumentError
              # Do nothing.
            end

            expect(contract)
              .to have_received(:match)
              .with(arguments: arguments, block: block, keywords: keywords)
          end

          context 'when the parameters do not match the contract' do
            let(:expected_errors) do
              Stannum::Contracts::ParametersContract
                .new(&validations)
                .errors_for(
                  {
                    arguments: arguments,
                    keywords:  keywords,
                    block:     block
                  }
                )
            end

            # rubocop:disable RSpec/SubjectStub
            it 'should call the error handler' do
              allow(instance).to receive(:handle_invalid_parameters)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance)
                .to have_received(:handle_invalid_parameters)
                .with(errors: expected_errors, method_name: method_name)
            end

            it 'should not call the method implementation' do
              allow(instance).to receive(:handle_invalid_parameters)
              allow(instance).to receive(:inner_method)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance).not_to have_received(:inner_method)
            end
            # rubocop:enable RSpec/SubjectStub

            context 'when the subclass defines a custom handler' do
              before(:example) do
                Spec::ExampleClass.define_method(:handle_invalid_parameters) \
                do |**_|
                  :failure
                end
              end

              it 'should call the custom handler' do
                expect(
                  instance.send(method_name, *arguments, **keywords, &block)
                )
                  .to be :failure
              end
            end
          end

          context 'when the parameters match the contract' do
            let(:validations) do
              lambda do
                arguments :args,   String
                keywords  :kwargs, Integer
              end
            end

            # rubocop:disable RSpec/SubjectStub
            it 'should call the method implementation' do
              allow(instance).to receive(:inner_method)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance).to have_received(:inner_method)
                .with(*arguments, **keywords)
            end
            # rubocop:enable RSpec/SubjectStub
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end

      context 'with a validation on both the parent class and the subclass' do
        it 'should add a parameters contract to ::MethodValidations' do
          Spec::ExampleClass.validate_parameters(method_name) { nil }
          Spec::ExampleSubclass.validate_parameters(method_name, &validations)

          expect(
            Spec::ExampleSubclass::MethodValidations.contracts[method_name]
          )
            .to be_a Stannum::Contracts::ParametersContract
        end

        # rubocop:disable RSpec/NestedGroups
        context 'when the method is called' do
          let(:arguments) { %w[ichi ni san] }
          let(:keywords)  { { one: 1, two: 2, three: 3 } }
          let(:block)     { -> {} }
          let(:match)     { true }
          let(:errors)    { Stannum::Errors.new }
          let(:contract) do
            Spec::ExampleClass::MethodValidations.contracts[method_name]
          end

          before(:example) do
            Spec::ExampleClass.validate_parameters(method_name, &validations)
          end

          it 'should call the contract' do
            allow(contract).to receive(:match).and_return(match, errors)

            begin
              instance.send(method_name, *arguments, **keywords, &block)
            rescue ArgumentError
              # Do nothing.
            end

            expect(contract)
              .to have_received(:match)
              .with(arguments: arguments, block: block, keywords: keywords)
          end

          context 'when the parameters do not match the contract' do
            let(:expected_errors) do
              Stannum::Contracts::ParametersContract
                .new(&validations)
                .errors_for(
                  {
                    arguments: arguments,
                    keywords:  keywords,
                    block:     block
                  }
                )
            end

            # rubocop:disable RSpec/SubjectStub
            it 'should call the error handler' do
              allow(instance).to receive(:handle_invalid_parameters)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance)
                .to have_received(:handle_invalid_parameters)
                .with(errors: expected_errors, method_name: method_name)
            end

            it 'should not call the method implementation' do
              allow(instance).to receive(:handle_invalid_parameters)
              allow(instance).to receive(:inner_method)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance).not_to have_received(:inner_method)
            end
            # rubocop:enable RSpec/SubjectStub

            context 'when the subclass defines a custom handler' do
              before(:example) do
                Spec::ExampleClass.define_method(:handle_invalid_parameters) \
                do |**_|
                  :failure
                end
              end

              it 'should call the custom handler' do
                expect(
                  instance.send(method_name, *arguments, **keywords, &block)
                )
                  .to be :failure
              end
            end
          end

          context 'when the parameters match the contract' do
            let(:validations) do
              lambda do
                arguments :args,   String
                keywords  :kwargs, Integer
              end
            end

            # rubocop:disable RSpec/SubjectStub
            it 'should call the method implementation' do
              allow(instance).to receive(:inner_method)

              instance.send(method_name, *arguments, **keywords, &block)

              expect(instance).to have_received(:inner_method)
                .with(*arguments, **keywords)
            end
            # rubocop:enable RSpec/SubjectStub
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end
    end
  end

  describe '#handle_invalid_parameters' do
    subject(:instance) { Spec::ExampleClass.new }

    let(:errors)      { Stannum::Errors.new }
    let(:method_name) { :custom_method }
    let(:error_message) do
      "invalid parameters for ##{method_name}"
    end

    it 'should define the private method' do
      expect(instance)
        .to respond_to(:handle_invalid_parameters, true)
        .with(0).arguments
        .and_keywords(:errors, :method_name)
    end

    it 'should raise an exception' do
      expect do
        instance.send(
          :handle_invalid_parameters,
          errors:      errors,
          method_name: method_name
        )
      end
        .to raise_error ArgumentError, error_message
    end

    context 'when the errors object has errors' do
      let(:errors) do
        super().add('spec.example_error', message: 'Something went wrong.')
      end
      let(:error_message) do
        super() + ": #{errors.summary}"
      end

      it 'should raise an exception' do
        expect do
          instance.send(
            :handle_invalid_parameters,
            errors:      errors,
            method_name: method_name
          )
        end
          .to raise_error ArgumentError, error_message
      end
    end
  end

  describe '#match_parameters_to_contract' do
    subject(:instance) { Spec::ExampleClass.new }

    let(:contract)    { Stannum::Contract.new }
    let(:method_name) { :custom_method }
    let(:parameters)  { {} }
    let(:expected) do
      {
        arguments: [],
        block:     nil,
        keywords:  {}
      }.merge(parameters)
    end

    def match_parameters
      instance.send(
        :match_parameters_to_contract,
        contract:    contract,
        method_name: method_name,
        **parameters
      )
    end

    before(:example) do
      allow(instance).to receive(:handle_invalid_parameters) # rubocop:disable RSpec/SubjectStub
    end

    it 'should define the private method' do
      expect(instance)
        .to respond_to(:match_parameters_to_contract, true)
        .with(0).arguments
        .and_keywords(:arguments, :block, :contract, :keywords, :method_name)
    end

    it 'should call the contract with the parameters' do
      allow(contract).to receive(:match)

      match_parameters

      expect(contract).to have_received(:match).with(**expected)
    end

    describe 'with arguments: an array' do
      let(:arguments)  { %w[ichi ni san] }
      let(:parameters) { super().merge(arguments: arguments) }

      it 'should call the contract with the parameters' do
        allow(contract).to receive(:match)

        match_parameters

        expect(contract).to have_received(:match).with(**expected)
      end
    end

    describe 'with block: a proc' do
      let(:block)      { -> {} }
      let(:parameters) { super().merge(block: block) }

      it 'should call the contract with the parameters' do
        allow(contract).to receive(:match)

        match_parameters

        expect(contract).to have_received(:match).with(**expected)
      end
    end

    describe 'with contract: a contract that does not match the parameters' do
      let(:contract) { Stannum::Constraints::Nothing.new }
      let(:errors)   { contract.errors_for(expected) }

      it 'should call handle_invalid_parameters' do
        match_parameters

        expect(instance) # rubocop:disable RSpec/SubjectStub
          .to have_received(:handle_invalid_parameters)
          .with(errors: errors, method_name: method_name)
      end
    end

    describe 'with contract: a contract that matches the parameters' do
      let(:contract) { Stannum::Constraints::Anything.new }

      it 'should not call handle_invalid_parameters' do
        match_parameters

        expect(instance) # rubocop:disable RSpec/SubjectStub
          .not_to have_received(:handle_invalid_parameters)
      end

      it 'should return ::VALIDATION_SUCCESS' do
        expect(match_parameters).to be described_class::VALIDATION_SUCCESS
      end
    end

    describe 'with keywords: a hash' do
      let(:keywords)   { { key: :value } }
      let(:parameters) { super().merge(keywords: keywords) }

      it 'should call the contract with the parameters' do
        allow(contract).to receive(:match)

        match_parameters

        expect(contract).to have_received(:match).with(**expected)
      end
    end
  end
end
