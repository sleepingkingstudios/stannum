# frozen_string_literal: true

require 'stannum/messages/default_loader'

RSpec.describe Stannum::Messages::DefaultLoader do
  subject(:loader) { described_class.new(**constructor_options) }

  let(:file_paths)          { %w[/path/to/configuration] }
  let(:locale)              { 'en' }
  let(:constructor_options) { { file_paths: } }

  describe '#initialize' do
    it 'should define the constructor' do
      expect(described_class)
        .to be_constructible
        .with(0).arguments
        .and_keywords(:file_paths, :locale)
    end
  end

  describe '#call' do
    before(:example) do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:read)
    end

    it { expect(loader).to respond_to(:call).with(0).arguments }

    it { expect(loader).to respond_to(:load).with(0).arguments }

    it { expect(loader.method(:load)).to be == loader.method(:call) }

    context 'when initialized with file_paths: an empty array' do
      let(:file_paths) { [] }

      it { expect(loader.call).to be == {} }
    end

    context 'when initialized with file_paths: an array with one path' do
      let(:file_paths) { %w[/path/to/configuration] }
      let(:ruby_file)  { File.join(file_paths.first, "#{locale}.rb") }
      let(:yaml_file)  { File.join(file_paths.first, "#{locale}.yml") }

      context 'when the file does not exist' do
        it 'should check if the Ruby file exists' do
          loader.call

          expect(File).to have_received(:exist?).with(ruby_file)
        end

        it 'should check if the YAML file exists' do
          loader.call

          expect(File).to have_received(:exist?).with(yaml_file)
        end

        it 'should not read any files' do
          loader.call

          expect(File).not_to have_received(:read)
        end

        it { expect(loader.call).to be == {} }
      end

      context 'when the Ruby file exists' do
        let(:ruby_config) do
          <<~RUBY
            # frozen_string_literal: true

            {
              weapons: {
                swords: {
                  short:  'wakizashi',
                  medium: 'katana',
                  long:   'tachi'
                }
              }
            }
          RUBY
        end
        let(:expected) do
          {
            weapons: {
              swords: {
                short:  'wakizashi',
                medium: 'katana',
                long:   'tachi'
              }
            }
          }
        end

        before(:example) do
          allow(File).to receive(:exist?).with(ruby_file).and_return(true)
          allow(File).to receive(:read).with(ruby_file).and_return(ruby_config)
        end

        it 'should check if the Ruby file exists' do
          loader.call

          expect(File).to have_received(:exist?).with(ruby_file)
        end

        it 'should read the Ruby file' do
          loader.call

          expect(File).to have_received(:read).with(ruby_file)
        end

        it { expect(loader.call).to be == expected }

        context 'when the ruby file includes a Proc' do
          let(:ruby_config) do
            <<~RUBY
              # frozen_string_literal: true

              {
                syllabary: lambda do |foreign_word = false|
                  foreign_word ? 'katakana' : 'hiragana'
                end
              }
            RUBY
          end

          it { expect(loader.call).to be_a Hash }

          it { expect(loader.call[:syllabary]).to be_a Proc }

          it { expect(loader.call[:syllabary].call).to be == 'hiragana' }

          it { expect(loader.call[:syllabary].call(true)).to be == 'katakana' }
        end

        context 'when initialized with locale: value' do
          let(:locale)              { 'en-gb' }
          let(:constructor_options) { super().merge(locale:) }

          it 'should check if the Ruby file exists' do
            loader.call

            expect(File).to have_received(:exist?).with(ruby_file)
          end

          it 'should read the Ruby file' do
            loader.call

            expect(File).to have_received(:read).with(ruby_file)
          end

          it { expect(loader.call).to be == expected }
        end
      end

      context 'when the YAML file exists' do
        let(:yaml_config) do
          <<~YAML
            ---
            weapons:
              swords:
                short:  'wakizashi'
                medium: 'katana'
                long:   'tachi'
          YAML
        end
        let(:expected) do
          {
            weapons: {
              swords: {
                short:  'wakizashi',
                medium: 'katana',
                long:   'tachi'
              }
            }
          }
        end

        before(:example) do
          allow(File).to receive(:exist?).with(yaml_file).and_return(true)
          allow(File).to receive(:read).with(yaml_file).and_return(yaml_config)
        end

        it 'should check if the Ruby file exists' do
          loader.call

          expect(File).to have_received(:exist?).with(ruby_file)
        end

        it 'should check if the YAML file exists' do
          loader.call

          expect(File).to have_received(:exist?).with(yaml_file)
        end

        it 'should read the YAML file' do
          loader.call

          expect(File).to have_received(:read).with(yaml_file)
        end

        it { expect(loader.call).to be == expected }

        context 'when initialized with locale: value' do
          let(:locale)              { 'en-gb' }
          let(:constructor_options) { super().merge(locale:) }

          it 'should check if the Ruby file exists' do
            loader.call

            expect(File).to have_received(:exist?).with(ruby_file)
          end

          it 'should check if the YAML file exists' do
            loader.call

            expect(File).to have_received(:exist?).with(yaml_file)
          end

          it 'should read the YAML file' do
            loader.call

            expect(File).to have_received(:read).with(yaml_file)
          end

          it { expect(loader.call).to be == expected }
        end
      end
    end

    context 'when initialized with file_paths: an array with multiple paths' do
      let(:file_paths) do
        %w[
          /path/to/configuration
          /library/path/to/configuration
          /application/path/to/configuration
        ]
      end
      let(:ruby_files) do
        file_paths.map do |file_path|
          File.join(file_path, "#{locale}.rb")
        end
      end
      let(:yaml_files) do
        file_paths.map do |file_path|
          File.join(file_path, "#{locale}.yml")
        end
      end

      context 'when no files exist' do
        it 'should check if the Ruby files exist', :aggregate_failures do
          loader.call

          ruby_files.each do |ruby_file|
            expect(File).to have_received(:exist?).with(ruby_file)
          end
        end

        it 'should check if the YAML files exist', :aggregate_failures do
          loader.call

          yaml_files.each do |yaml_file|
            expect(File).to have_received(:exist?).with(yaml_file)
          end
        end

        it 'should not read any files' do
          loader.call

          expect(File).not_to have_received(:read)
        end

        it { expect(loader.call).to be == {} }
      end

      context 'when multiple files exist' do
        let(:core_ruby_file) { ruby_files[0] }
        let(:core_ruby_config) do
          <<~RUBY
            # frozen_string_literal: true

            {
              weapons: {
                swords: {
                  short:  'wakizashi',
                  medium: 'katana',
                  long:   'tachi'
                }
              }
            }
          RUBY
        end
        let(:library_ruby_file) { ruby_files[1] }
        let(:library_ruby_config) do
          <<~RUBY
            # frozen_string_literal: true

            {
              cavalry: 'hussar',
              sausage: 'kolbász'
            }
          RUBY
        end
        let(:application_yaml_file) { yaml_files[2] }
        let(:application_yaml_config) do
          <<~YAML
            weapons:
              swords:
                short:  'einhänder'
                long:   'zweihänder'
                heroic: 'Balmung'
            sausage: 'wurst'
          YAML
        end
        let(:expected) do
          {
            weapons: {
              swords: {
                short:  'einhänder',
                medium: 'katana',
                long:   'zweihänder',
                heroic: 'Balmung'
              }
            },
            cavalry: 'hussar',
            sausage: 'wurst'
          }
        end

        before(:example) do
          allow(File)
            .to receive(:exist?)
            .with(core_ruby_file).and_return(true)
          allow(File).to receive(:read)
            .with(core_ruby_file)
            .and_return(core_ruby_config)

          allow(File)
            .to receive(:exist?)
            .with(library_ruby_file).and_return(true)
          allow(File).to receive(:read)
            .with(library_ruby_file)
            .and_return(library_ruby_config)

          allow(File)
            .to receive(:exist?)
            .with(application_yaml_file).and_return(true)
          allow(File).to receive(:read)
            .with(application_yaml_file)
            .and_return(application_yaml_config)
        end

        it { expect(loader.call).to deep_match expected }
      end
    end
  end

  describe '#file_paths' do
    include_examples 'should define reader',
      :file_paths,
      -> { be == file_paths }
  end

  describe '#locale' do
    include_examples 'should define reader', :locale, 'en'

    context 'when initialized with locale: value' do
      let(:locale)              { 'en-gb' }
      let(:constructor_options) { super().merge(locale:) }

      it { expect(loader.locale).to be == locale }
    end
  end
end
