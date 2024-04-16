# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module AssociationExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    shared_examples 'should implement the Association methods' do
      describe '.new' do
        it 'should define the constructor' do
          expect(described_class)
            .to be_constructible
            .with(0).arguments
            .and_keywords(:name, :options, :type)
        end

        describe 'with name: nil' do
          it 'should raise an error' do
            expect do
              described_class.new(name: nil, type: type, options: options)
            end
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
            expect do
              described_class.new(name: '', type: type, options: options)
            end
              .to raise_error ArgumentError, "name can't be blank"
          end
        end

        describe 'with name: empty Symbol' do
          it 'should raise an error' do
            expect do
              described_class.new(name: :'', type: type, options: options)
            end
              .to raise_error ArgumentError, "name can't be blank"
          end
        end

        describe 'with options: nil' do
          it 'should set the options to a default hash' do
            expect(
              described_class.new(name: name, type: type, options: nil).options
            ).to be == {}
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
            expect do
              described_class.new(name: name, type: nil, options: options)
            end
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
                'type must be a Class, a Module, or the name of a class or ' \
                'module'
          end
        end

        describe 'with type: an empty String' do
          it 'should raise an error' do
            expect do
              described_class.new(name: name, type: '', options: options)
            end
              .to raise_error ArgumentError, "type can't be blank"
          end
        end
      end

      describe '#clear_association' do
        it 'should define the method' do
          expect(association)
            .to respond_to(:clear_association)
            .with(1).argument
        end
      end

      describe '#many?' do
        include_examples 'should define predicate', :many?
      end

      describe '#name' do
        include_examples 'should define reader', :name, -> { name }

        context 'when the name is a symbol' do
          let(:name) { :reference }

          it { expect(association.name).to be == name.to_s }
        end
      end

      describe '#one?' do
        include_examples 'should define predicate', :one?
      end

      describe '#options' do
        let(:expected) do
          SleepingKingStudios::Tools::HashTools.convert_keys_to_symbols(options)
        end

        include_examples 'should define reader', :options, -> { expected }

        context 'with options: a Hash with String keys' do
          let(:options) { { 'key' => 'value' } }

          it { expect(association.options).to be == expected }
        end

        context 'with options: a Hash with Symbol keys' do
          let(:options) { { key: 'value' } }

          it { expect(association.options).to be == expected }
        end
      end

      describe '#read_association' do
        it 'should define the method' do
          expect(association)
            .to respond_to(:read_association)
            .with(1).argument
        end
      end

      describe '#reader_name' do
        include_examples 'should define reader',
          :reader_name,
          -> { name.intern }

        context 'when the name is a symbol' do
          let(:name) { :reference }

          it { expect(association.reader_name).to be == name }
        end
      end

      describe '#resolved_type' do
        include_examples 'should define reader', :resolved_type, -> { type }

        context 'when the type is an invalid constant name' do
          let(:type) { 'Foo' }

          it 'should raise an error' do
            expect { association.resolved_type }
              .to raise_error NameError, /uninitialized constant Foo/
          end
        end

        context 'when the type is an invalid module name' do
          let(:type) { 'RUBY_VERSION' }

          it 'should raise an error' do
            expect { association.resolved_type }
              .to raise_error NameError,
                /constant RUBY_VERSION is not a Class or Module/
          end
        end

        context 'when the type is a valid module name' do
          let(:type) { super().to_s }

          it { expect(association.resolved_type).to be Object.const_get(type) }
        end
      end

      describe '#type' do
        include_examples 'should define reader', :type, -> { type.to_s }

        context 'when the type is a String' do
          let(:type) { super().to_s }

          it { expect(association.type).to be == type }
        end
      end

      describe '#write_association' do
        it 'should define the method' do
          expect(association)
            .to respond_to(:write_association)
            .with(2).arguments
        end
      end

      describe '#writer_name' do
        include_examples 'should define reader',
          :writer_name,
          -> { :"#{name}=" }

        context 'when the name is a symbol' do
          let(:name) { :reference }

          it { expect(association.writer_name).to be == :"#{name}=" }
        end
      end
    end

    shared_examples 'should implement the Association::Builder methods' do
      describe '.new' do
        it 'should be constructible' do
          expect(described_class::Builder).to be_constructible.with(1).argument
        end
      end

      describe '#call' do
        it { expect(builder).to respond_to(:call).with(1).argument }
      end
    end
  end
end
