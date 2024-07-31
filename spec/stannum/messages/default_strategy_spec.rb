# frozen_string_literal: true

require 'stannum/messages/default_strategy'

RSpec.describe Stannum::Messages::DefaultStrategy do
  subject(:strategy) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::DEFAULT_LOAD_PATHS' do
    it 'should define the constant' do
      expect(described_class)
        .to define_constant(:DEFAULT_LOAD_PATHS)
        .with_value(be == [Stannum::Messages.locales_path])
    end
  end

  describe '.new' do
    it 'should define the constructor' do
      expect(described_class)
        .to respond_to(:new)
        .with(0).arguments
        .and_keywords(:configuration, :load_paths, :locale)
    end
  end

  describe '.load_paths' do
    include_examples 'should define class reader',
      :load_paths,
      -> { be == described_class::DEFAULT_LOAD_PATHS }

    it 'should be mutable' do
      expect { described_class.load_paths << '/path/to/configuration' }
        .to change(described_class, :load_paths)
        .to include '/path/to/configuration'
    ensure
      described_class.load_paths.replace(described_class::DEFAULT_LOAD_PATHS)
    end
  end

  describe '#call' do
    # rubocop:disable Style/FormatStringToken
    let(:configuration) do
      {
        en: {
          stannum: {
            greeting: lambda do |_key, options|
              if options[:name] == 'starfighter'
                'Greetings, %{name}! You have been recruited by the Star ' \
                  'League to defend the frontier against Xur and the Ko-Dan ' \
                  'armada!'
              else
                'Greetings, %{name}!'
              end
            end,
            hello:    'hello %{name}',
            invalid:  'is invalid',
            valid:    'is valid'
          }
        }
      }
    end
    # rubocop:enable Style/FormatStringToken

    before(:example) do
      allow(strategy) # rubocop:disable RSpec/SubjectStub
        .to receive(:configuration)
        .and_return(configuration)
    end

    it 'should define the method' do
      expect(strategy)
        .to respond_to(:call)
        .with(1).argument
        .and_any_keywords
    end

    describe 'with nil' do
      let(:error_message) { 'error type must be a String or Symbol' }

      it 'should raise an error' do
        expect { strategy.call(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) { 'error type must be a String or Symbol' }

      it 'should raise an error' do
        expect { strategy.call(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with an error type with no corresponding value' do
      let(:error_type) { 'spec.undefined_error' }
      let(:expected)   { "no message defined for #{error_type.inspect}" }

      it { expect(strategy.call(error_type)).to be == expected }
    end

    describe 'with an error type that corresponds to a namespace' do
      let(:error_type) { 'stannum' }
      let(:expected)   { "configuration is a namespace at #{error_type}" }

      it { expect(strategy.call(error_type)).to be == expected }
    end

    describe 'with an error type that corresponds to a basic string' do
      let(:error_type) { 'stannum.invalid' }
      let(:expected)   { 'is invalid' }

      it { expect(strategy.call(error_type)).to be == expected }
    end

    describe 'with an error type that corresponds to an interpolated string' do
      let(:error_type) { 'stannum.hello' }
      let(:expected)   { 'hello %{name}' } # rubocop:disable Style/FormatStringToken

      it { expect(strategy.call(error_type)).to be == expected }

      describe 'with name: value' do
        let(:options)  { { name: 'world' } }
        let(:expected) { 'hello world' }

        it { expect(strategy.call(error_type, **options)).to be == expected }
      end
    end

    describe 'with an error type that corresponds to a lambda' do
      let(:error_type) { 'stannum.greeting' }
      let(:expected)   { 'Greetings, %{name}!' } # rubocop:disable Style/FormatStringToken

      it { expect(strategy.call(error_type)).to be == expected }

      describe 'with name: programs' do
        let(:expected) { 'Greetings, programs!' }
        let(:options)  { { name: 'programs' } }

        it { expect(strategy.call(error_type, **options)).to be == expected }
      end

      describe 'with name: starfighter' do
        let(:expected) do
          'Greetings, starfighter! You have been recruited by the Star ' \
            'League to defend the frontier against Xur and the Ko-Dan armada!'
        end
        let(:options) { { name: 'starfighter' } }

        it { expect(strategy.call(error_type, **options)).to be == expected }
      end
    end

    context 'when initialized with locale: value' do
      let(:locale)              { 'en-gb' }
      let(:constructor_options) { super().merge(locale:) }
      let(:configuration) do
        super().merge(
          {
            'en-gb': {
              stannum: {
                invalid: 'is bollocks'
              }
            }
          }
        )
      end

      describe 'with an error type with no corresponding value' do
        let(:error_type) { 'stannum.valid' }
        let(:expected)   { "no message defined for #{error_type.inspect}" }

        it { expect(strategy.call(error_type)).to be == expected }
      end

      describe 'with an error type that corresponds to a basic string' do
        let(:error_type) { 'stannum.invalid' }
        let(:expected)   { 'is bollocks' }

        it { expect(strategy.call(error_type)).to be == expected }
      end
    end
  end

  describe '#configuration' do
    shared_examples 'should delegate to a loader' do
      let(:configuration) do
        {
          en: {
            stannum: {
              constraints: {
                invalid: 'is invalid',
                valid:   'is valid'
              }
            }
          }
        }
      end
      let(:loader) do
        instance_double(Stannum::Messages::DefaultLoader, call: configuration)
      end

      before(:example) do
        allow(Stannum::Messages::DefaultLoader)
          .to receive(:new)
          .and_return(loader)
      end

      it 'should initialize a loader' do
        strategy.send :configuration

        expect(Stannum::Messages::DefaultLoader)
          .to have_received(:new)
          .with(file_paths: strategy.load_paths, locale: strategy.locale)
      end

      it 'should call the loader' do
        strategy.send :configuration

        expect(loader).to have_received(:call).with(no_args)
      end

      it { expect(strategy.send(:configuration)).to be == configuration }
    end

    include_examples 'should define private reader', :configuration

    context 'when initialized with no arguments' do
      include_examples 'should delegate to a loader'
    end

    context 'when initialized with configuration: value' do
      let(:custom_configuration) do
        {
          stannum: {
            custom: 'custom message'
          }
        }
      end
      let(:constructor_options) do
        super().merge(configuration: custom_configuration)
      end
      let(:loader) do
        instance_double(Stannum::Messages::DefaultLoader, call: nil)
      end

      before(:example) do
        allow(Stannum::Messages::DefaultLoader)
          .to receive(:new)
          .and_return(loader)
      end

      it { expect(strategy.send :configuration).to be == custom_configuration }

      it 'should not call the loader' do
        strategy.send :configuration

        expect(loader).not_to have_received(:call)
      end
    end

    context 'when initialized with load_paths: an empty array' do
      let(:constructor_options) do
        super().merge(load_paths: [])
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: a Ruby file name' do
      let(:filename) { '/path/to/config/locale.rb' }
      let(:constructor_options) do
        super().merge(load_paths: filename)
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: a YAML file name' do
      let(:filename) { '/path/to/config/locale.yml' }
      let(:constructor_options) do
        super().merge(load_paths: filename)
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: an array of file names' do
      let(:filenames) do
        [
          '/path/to/alpha.rb',
          '/path/to/beta.yml',
          '/path/to/gamma.yml'
        ]
      end
      let(:constructor_options) do
        super().merge(load_paths: filenames)
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with locale: value' do
      let(:locale)              { 'en-gb' }
      let(:constructor_options) { super().merge(locale:) }

      include_examples 'should delegate to a loader'
    end
  end

  describe '#locale' do
    include_examples 'should define reader', :locale, 'en'

    context 'when initialized with locale: value' do
      let(:locale)              { 'en-gb' }
      let(:constructor_options) { super().merge(locale:) }

      it { expect(strategy.locale).to be == locale }
    end
  end

  describe '#load_paths' do
    let(:expected) { [Stannum::Messages.locales_path] }

    include_examples 'should define reader', :load_paths, -> { be == expected }

    context 'when initialized with load_paths: an empty Array' do
      let(:load_paths) { [] }
      let(:constructor_options) do
        super().merge(load_paths:)
      end

      it { expect(strategy.load_paths).to be == load_paths }
    end

    context 'when initialized with load_paths: a filename' do
      let(:load_paths) { '/path/to/config/locales.rb' }
      let(:constructor_options) do
        super().merge(load_paths:)
      end

      it { expect(strategy.load_paths).to be == [load_paths] }
    end

    context 'when initialized with load_paths: an array of filenames' do
      let(:load_paths) do
        [
          '/path/to/config/de.rb',
          '/path/to/config/en.rb',
          '/path/to/config/fr.rb'
        ]
      end
      let(:constructor_options) do
        super().merge(load_paths:)
      end

      it { expect(strategy.load_paths).to be == load_paths }
    end
  end

  describe '#reload_configuration!' do
    shared_examples 'should delegate to a loader' do
      let(:configuration) do
        {
          en: {
            stannum: {
              constraints: {
                invalid: 'is invalid',
                valid:   'is valid'
              }
            }
          }
        }
      end
      let(:loader) do
        instance_double(Stannum::Messages::DefaultLoader, call: configuration)
      end

      before(:example) do
        allow(Stannum::Messages::DefaultLoader)
          .to receive(:new)
          .and_return(loader)
      end

      it 'should initialize a loader' do
        strategy.reload_configuration!

        expect(Stannum::Messages::DefaultLoader)
          .to have_received(:new)
          .with(file_paths: strategy.load_paths, locale: strategy.locale)
      end

      it 'should call the loader' do
        strategy.reload_configuration!

        expect(loader).to have_received(:call).with(no_args)
      end

      it 'should update the configuration' do
        strategy.reload_configuration!

        expect(strategy.send(:configuration)).to be == configuration
      end
    end

    let(:constructor_options) do
      super().merge(configuration: { en: {} })
    end

    it 'should define the method' do
      expect(strategy).to respond_to(:reload_configuration!).with(0).arguments
    end

    it { expect(strategy.reload_configuration!).to be strategy }

    context 'when initialized with no arguments' do
      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: an empty array' do
      let(:constructor_options) do
        super().merge(load_paths: [])
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: a Ruby file name' do
      let(:filename) { '/path/to/config/locale.rb' }
      let(:constructor_options) do
        super().merge(load_paths: filename)
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: a YAML file name' do
      let(:filename) { '/path/to/config/locale.yml' }
      let(:constructor_options) do
        super().merge(load_paths: filename)
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with load_paths: an array of file names' do
      let(:filenames) do
        [
          '/path/to/alpha.rb',
          '/path/to/beta.yml',
          '/path/to/gamma.yml'
        ]
      end
      let(:constructor_options) do
        super().merge(load_paths: filenames)
      end

      include_examples 'should delegate to a loader'
    end

    context 'when initialized with locale: value' do
      let(:locale)              { 'en-gb' }
      let(:constructor_options) { super().merge(locale:) }

      include_examples 'should delegate to a loader'
    end
  end
end
