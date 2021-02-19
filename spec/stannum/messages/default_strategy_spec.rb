# frozen_string_literal: true

require 'stannum/messages/default_strategy'

RSpec.describe Stannum::Messages::DefaultStrategy do
  shared_context 'when the configuration is defined' do
    let(:filename) { File.join(Stannum::Messages.locales_path, 'en.rb') }
    let(:configuration) do
      <<~RUBY
        # frozen_string_literal: true

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
      RUBY
    end
    let(:expected) do
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

    before(:example) do
      allow(IO).to receive(:read).with(filename).and_return(configuration)
    end
  end

  subject(:strategy) { described_class.new(**constructor_options) }

  let(:constructor_options) { {} }

  describe '::new' do
    it 'should define the constructor' do
      expect(described_class)
        .to respond_to(:new)
        .with(0).arguments
        .and_keywords(:configuration, :filename)
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
                'Greetings, %{name}! You have been recruited by the Star' \
                ' League to defend the frontier against Xur and the Ko-Dan' \
                ' armada!'
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
      let(:expected)   { "no message defined for #{error_type}" }

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
          'Greetings, starfighter! You have been recruited by the Star League' \
          ' to defend the frontier against Xur and the Ko-Dan armada!'
        end
        let(:options) { { name: 'starfighter' } }

        it { expect(strategy.call(error_type, **options)).to be == expected }
      end
    end
  end

  describe '#configuration' do
    include_context 'when the configuration is defined'

    include_examples 'should define private reader',
      :configuration,
      -> { be == expected }

    it 'should read the configuration from the file' do
      strategy.send :configuration

      expect(IO).to have_received(:read).with(filename)
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

      it { expect(strategy.send :configuration).to be == custom_configuration }

      it 'should not read the configuration' do
        strategy.send :configuration

        expect(IO).not_to have_received(:read)
      end
    end

    context 'when initialized with filename: value' do
      let(:filename) { '/path/to/config/locale.rb' }
      let(:constructor_options) do
        super().merge(filename: filename)
      end

      it { expect(strategy.send :configuration).to be == expected }

      it 'should read the configuration from the file' do
        strategy.send :configuration

        expect(IO).to have_received(:read).with(filename)
      end
    end
  end

  describe '#filename' do
    include_context 'when the configuration is defined'

    let(:expected) { File.join(Stannum::Messages.locales_path, 'en.rb') }

    include_examples 'should define private reader',
      :filename,
      -> { be == expected }

    context 'when initialized with filename: value' do
      let(:filename) { '/path/to/config/locale.rb' }
      let(:constructor_options) do
        super().merge(filename: filename)
      end

      it { expect(strategy.send :filename).to be == filename }
    end
  end
end
