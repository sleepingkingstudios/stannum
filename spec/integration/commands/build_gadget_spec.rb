# frozen_string_literal: true

require 'stannum'

require 'support/commands/build_gadget'
require 'support/structs/factory'
require 'support/structs/gadget'
require 'support/structs/gizmo'

RSpec.describe Spec::BuildGadget do
  subject(:command) { described_class.new(factory: factory) }

  let(:factory) { Spec::Factory.new }

  describe '.new' do
    let(:error_message) { 'invalid parameters for #new' }

    describe 'with no parameters' do
      it 'should raise an exception' do
        expect { described_class.new }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with factory: nil' do
      it 'should raise an exception' do
        expect { described_class.new(factory: nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with factory: an Object' do
      it 'should raise an exception' do
        expect { described_class.new(factory: Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with factory: a factory instance' do
      it 'should initialize the command' do
        expect(described_class.new(factory: factory)).to be_a described_class
      end

      it 'should call the constructor' do
        expect(described_class.new(factory: factory).factory).to be factory
      end
    end
  end

  describe '#call' do
    let(:contract) do
      Stannum::Contracts::ParametersContract.new do
        keyword :attributes,   Hash
        keyword :gadget_class, Class, default: true
      end
    end
    let(:keywords) { { attributes: {} } }
    let(:expected_errors) do
      contract.errors_for(
        arguments: [],
        keywords:  keywords,
        block:     nil
      )
    end

    describe 'with no parameters' do
      let(:keywords) { {} }

      it 'should return an error object' do
        expect(command.call(**keywords)).to be == [false, expected_errors]
      end
    end

    describe 'with attributes: nil' do
      let(:keywords) { super().merge(attributes: nil) }

      it 'should return an error object' do
        expect(command.call(**keywords)).to be == [false, expected_errors]
      end
    end

    describe 'with attributes: an Object' do
      let(:keywords) { super().merge(attributes: Object.new.freeze) }

      it 'should return an error object' do
        expect(command.call(**keywords)).to be == [false, expected_errors]
      end
    end

    describe 'with attributes: an empty Hash' do
      let(:keywords) { super().merge(attributes: {}) }

      it 'should build a gadget' do
        expect(command.call(**keywords))
          .to be == [true, Spec::Gadget.new({})]
      end
    end

    describe 'with gadget_class: nil' do
      let(:keywords) { super().merge(gadget_class: nil) }

      it 'should return an error object' do
        expect(command.call(**keywords)).to be == [false, expected_errors]
      end
    end

    describe 'with gadget_class: Gadget' do
      let(:keywords) { super().merge(gadget_class: Spec::Gadget) }

      it 'should build a gadget' do
        expect(command.call(**keywords))
          .to be == [true, Spec::Gadget.new({})]
      end
    end

    describe 'with gadget_class: Gizmo' do
      let(:keywords) { super().merge(gadget_class: Spec::Gizmo) }

      it 'should build a gadget' do
        expect(command.call(**keywords))
          .to be == [true, Spec::Gizmo.new({})]
      end
    end
  end
end
