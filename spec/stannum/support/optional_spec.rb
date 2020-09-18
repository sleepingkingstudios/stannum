# frozen_string_literal: true

require 'stannum/support/optional'

require 'support/examples/optional_examples'

RSpec.describe Stannum::Support::Optional do
  include Spec::Support::Examples::OptionalExamples

  shared_context 'when the subject is optional by default' do
    before(:example) do
      Spec::Options.send(:define_method, :initialize) do |options|
        super(resolve_required_option(required_by_default: false, **options))
      end
    end
  end

  shared_context 'when the subject is required by default' do
    before(:example) do
      Spec::Options.send(:define_method, :initialize) do |options|
        super(resolve_required_option(**options))
      end
    end
  end

  subject { Spec::Options.new(constructor_options) }

  let(:constructor_options) { {} }

  example_class 'Spec::Options', Struct.new(:options) do |klass|
    klass.include Stannum::Support::Optional # rubocop:disable RSpec/DescribedClass

    klass.send(:define_method, :initialize) do |options|
      super(resolve_required_option(**options))
    end
  end

  describe '.resolve' do
    let(:keywords) { {} }
    let(:resolved) { described_class.resolve(**keywords) }

    it 'should define the class method' do
      expect(described_class)
        .to respond_to(:resolve)
        .with_keywords(:optional, :required, :required_by_default)
        .and_any_keywords
    end

    it { expect(resolved).to be == { required: true } }

    describe 'with additional options' do
      let(:options)  { { key: 'value' } }
      let(:keywords) { super().merge(**options) }

      it { expect(resolved).to be == { required: true, **options } }
    end

    describe 'with optional: an object' do
      let(:error_message) { 'optional must be true or false' }

      it 'should raise an error' do
        expect { described_class.resolve(optional: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with optional: false' do
      let(:keywords) { super().merge(optional: false) }

      it { expect(resolved).to be == { required: true } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: true, **options } }
      end
    end

    describe 'with optional: true' do
      let(:keywords) { super().merge(optional: true) }

      it { expect(resolved).to be == { required: false } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: false, **options } }
      end
    end

    describe 'with required: an object' do
      let(:error_message) { 'required must be true or false' }

      it 'should raise an error' do
        expect { described_class.resolve(required: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with required: false' do
      let(:keywords) { super().merge(required: false) }

      it { expect(resolved).to be == { required: false } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: false, **options } }
      end
    end

    describe 'with required: true' do
      let(:keywords) { super().merge(required: true) }

      it { expect(resolved).to be == { required: true } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: true, **options } }
      end
    end

    describe 'with optional: false and required: false' do
      let(:error_message) { 'required and optional must match' }

      it 'should raise an error' do
        expect { described_class.resolve(optional: false, required: false) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with optional: false and required: true' do
      let(:keywords) { super().merge(optional: false, required: true) }

      it { expect(resolved).to be == { required: true } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: true, **options } }
      end
    end

    describe 'with optional: true and required: false' do
      let(:keywords) { super().merge(optional: true, required: false) }

      it { expect(resolved).to be == { required: false } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: false, **options } }
      end
    end

    describe 'with optional: true and required: true' do
      let(:error_message) { 'required and optional must match' }

      it 'should raise an error' do
        expect { described_class.resolve(optional: true, required: true) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with required_by_default: an object' do
      let(:error_message) { 'required_by_default must be true or false' }

      it 'should raise an error' do
        expect do
          described_class.resolve(required_by_default: Object.new.freeze)
        end
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with required_by_default: false' do
      let(:keywords) { super().merge(required_by_default: false) }

      it { expect(resolved).to be == { required: false } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: false, **options } }
      end

      describe 'with optional: false' do
        let(:keywords) { super().merge(optional: false) }

        it { expect(resolved).to be == { required: true } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: true, **options } }
        end
      end

      describe 'with optional: true' do
        let(:keywords) { super().merge(optional: true) }

        it { expect(resolved).to be == { required: false } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: false, **options } }
        end
      end

      describe 'with required: false' do
        let(:keywords) { super().merge(required: false) }

        it { expect(resolved).to be == { required: false } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: false, **options } }
        end
      end

      describe 'with required: true' do
        let(:keywords) { super().merge(required: true) }

        it { expect(resolved).to be == { required: true } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: true, **options } }
        end
      end
    end

    describe 'with required_by_default: true' do
      let(:keywords) { super().merge(required_by_default: true) }

      it { expect(resolved).to be == { required: true } }

      describe 'with additional options' do
        let(:options)  { { key: 'value' } }
        let(:keywords) { super().merge(**options) }

        it { expect(resolved).to be == { required: true, **options } }
      end

      describe 'with optional: false' do
        let(:keywords) { super().merge(optional: false) }

        it { expect(resolved).to be == { required: true } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: true, **options } }
        end
      end

      describe 'with optional: true' do
        let(:keywords) { super().merge(optional: true) }

        it { expect(resolved).to be == { required: false } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: false, **options } }
        end
      end

      describe 'with required: false' do
        let(:keywords) { super().merge(required: false) }

        it { expect(resolved).to be == { required: false } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: false, **options } }
        end
      end

      describe 'with required: true' do
        let(:keywords) { super().merge(required: true) }

        it { expect(resolved).to be == { required: true } }

        describe 'with additional options' do
          let(:options)  { { key: 'value' } }
          let(:keywords) { super().merge(**options) }

          it { expect(resolved).to be == { required: true, **options } }
        end
      end
    end
  end

  include_examples 'should implement the Optional interface'

  include_examples 'should implement the Optional methods'

  # rubocop:disable RSpec/NamedSubject
  describe '#optional?' do
    it { expect(subject.optional?).to be false }

    context 'when initialized with optional: false' do
      let(:constructor_options) { super().merge(optional: false) }

      it { expect(subject.optional?).to be false }
    end

    context 'when initialized with optional: true' do
      let(:constructor_options) { super().merge(optional: true) }

      it { expect(subject.optional?).to be true }
    end

    context 'when initialized with required: false' do
      let(:constructor_options) { super().merge(required: false) }

      it { expect(subject.optional?).to be true }
    end

    context 'when initialized with required: true' do
      let(:constructor_options) { super().merge(required: true) }

      it { expect(subject.optional?).to be false }
    end

    wrap_context 'when the subject is optional by default' do
      it { expect(subject.optional?).to be true }

      context 'when initialized with optional: false' do
        let(:constructor_options) { super().merge(optional: false) }

        it { expect(subject.optional?).to be false }
      end

      context 'when initialized with optional: true' do
        let(:constructor_options) { super().merge(optional: true) }

        it { expect(subject.optional?).to be true }
      end

      context 'when initialized with required: false' do
        let(:constructor_options) { super().merge(required: false) }

        it { expect(subject.optional?).to be true }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(subject.optional?).to be false }
      end
    end

    wrap_context 'when the subject is required by default' do
      it { expect(subject.optional?).to be false }

      context 'when initialized with optional: false' do
        let(:constructor_options) { super().merge(optional: false) }

        it { expect(subject.optional?).to be false }
      end

      context 'when initialized with optional: true' do
        let(:constructor_options) { super().merge(optional: true) }

        it { expect(subject.optional?).to be true }
      end

      context 'when initialized with required: false' do
        let(:constructor_options) { super().merge(required: false) }

        it { expect(subject.optional?).to be true }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(subject.optional?).to be false }
      end
    end
  end

  describe '#options' do
    let(:expected) do
      constructor_options
        .dup
        .tap { |hsh| hsh.delete(:optional) }
        .merge(required: true)
    end

    it { expect(subject.options).to be == expected }

    context 'when initialized with optional: false' do
      let(:constructor_options) { super().merge(optional: false) }

      it { expect(subject.options).to be == expected }
    end

    context 'when initialized with optional: true' do
      let(:constructor_options) { super().merge(optional: true) }
      let(:expected)            { super().merge(required: false) }

      it { expect(subject.options).to be == expected }
    end

    context 'when initialized with required: false' do
      let(:constructor_options) { super().merge(required: false) }
      let(:expected)            { super().merge(required: false) }

      it { expect(subject.options).to be == expected }
    end

    context 'when initialized with required: true' do
      let(:constructor_options) { super().merge(required: true) }

      it { expect(subject.options).to be == expected }
    end

    wrap_context 'when the subject is optional by default' do
      let(:expected) do
        constructor_options
          .dup
          .tap { |hsh| hsh.delete(:optional) }
          .merge(required: false)
      end

      it { expect(subject.options).to be == expected }

      context 'when initialized with optional: false' do
        let(:constructor_options) { super().merge(optional: false) }
        let(:expected)            { super().merge(required: true) }

        it { expect(subject.options).to be == expected }
      end

      context 'when initialized with optional: true' do
        let(:constructor_options) { super().merge(optional: true) }

        it { expect(subject.options).to be == expected }
      end

      context 'when initialized with required: false' do
        let(:constructor_options) { super().merge(required: false) }

        it { expect(subject.options).to be == expected }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }
        let(:expected)            { super().merge(required: true) }

        it { expect(subject.options).to be == expected }
      end
    end

    wrap_context 'when the subject is required by default' do
      let(:expected) do
        constructor_options
          .dup
          .tap { |hsh| hsh.delete(:optional) }
          .merge(required: true)
      end

      it { expect(subject.options).to be == expected }

      context 'when initialized with optional: false' do
        let(:constructor_options) { super().merge(optional: false) }

        it { expect(subject.options).to be == expected }
      end

      context 'when initialized with optional: true' do
        let(:constructor_options) { super().merge(optional: true) }
        let(:expected)            { super().merge(required: false) }

        it { expect(subject.options).to be == expected }
      end

      context 'when initialized with required: false' do
        let(:constructor_options) { super().merge(required: false) }
        let(:expected)            { super().merge(required: false) }

        it { expect(subject.options).to be == expected }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(subject.options).to be == expected }
      end
    end
  end

  describe '#required?' do
    it { expect(subject.required?).to be true }

    context 'when initialized with optional: false' do
      let(:constructor_options) { super().merge(optional: false) }

      it { expect(subject.required?).to be true }
    end

    context 'when initialized with optional: true' do
      let(:constructor_options) { super().merge(optional: true) }

      it { expect(subject.required?).to be false }
    end

    context 'when initialized with required: false' do
      let(:constructor_options) { super().merge(required: false) }

      it { expect(subject.required?).to be false }
    end

    context 'when initialized with required: true' do
      let(:constructor_options) { super().merge(required: true) }

      it { expect(subject.required?).to be true }
    end

    wrap_context 'when the subject is optional by default' do
      it { expect(subject.required?).to be false }

      context 'when initialized with optional: false' do
        let(:constructor_options) { super().merge(optional: false) }

        it { expect(subject.required?).to be true }
      end

      context 'when initialized with optional: true' do
        let(:constructor_options) { super().merge(optional: true) }

        it { expect(subject.required?).to be false }
      end

      context 'when initialized with required: false' do
        let(:constructor_options) { super().merge(required: false) }

        it { expect(subject.required?).to be false }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(subject.required?).to be true }
      end
    end

    wrap_context 'when the subject is required by default' do
      it { expect(subject.required?).to be true }

      context 'when initialized with optional: false' do
        let(:constructor_options) { super().merge(optional: false) }

        it { expect(subject.required?).to be true }
      end

      context 'when initialized with optional: true' do
        let(:constructor_options) { super().merge(optional: true) }

        it { expect(subject.required?).to be false }
      end

      context 'when initialized with required: false' do
        let(:constructor_options) { super().merge(required: false) }

        it { expect(subject.required?).to be false }
      end

      context 'when initialized with required: true' do
        let(:constructor_options) { super().merge(required: true) }

        it { expect(subject.required?).to be true }
      end
    end
  end

  describe '#resolve_required_option' do
    let(:resolved_options) { { key: 'value', required: false } }
    let(:options)          { { key: 'value', optional: true } }

    it 'should define the private method' do
      expect(subject)
        .to respond_to(:resolve_required_option, true)
        .with(0).arguments
        .and_any_keywords
    end

    it 'should delegate to .resolve' do
      subject # Initialize subject.

      allow(Stannum::Support::Optional) # rubocop:disable RSpec/DescribedClass
        .to receive(:resolve)
        .and_return({})

      subject.send(:resolve_required_option, **options)

      expect(Stannum::Support::Optional) # rubocop:disable RSpec/DescribedClass
        .to have_received(:resolve)
        .with(options)
    end

    it 'should resolve the optional and required options' do
      expect(subject.send(:resolve_required_option, **options))
        .to be == resolved_options
    end
  end
  # rubocop:enable RSpec/NamedSubject
end
