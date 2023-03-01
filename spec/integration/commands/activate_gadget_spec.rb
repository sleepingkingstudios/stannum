# frozen_string_literal: true

require 'stannum'
require 'stannum/rspec/validate_parameter'

require 'support/commands/activate_gadget'
require 'support/entities/gizmo'

# @note Integration spec for Stannum::ParameterValidation.
RSpec.describe Spec::ActivateGadget do
  include Stannum::RSpec::Matchers

  subject(:command) { described_class.new }

  describe '#call' do
    let(:error_message) do
      /invalid parameters for #call/
    end

    it 'should validate the gadget argument' do
      expect(command)
        .to validate_parameter(:call, :gadget)
        .using_constraint(Spec::Gadget)
    end

    describe 'with no parameters' do
      it 'should raise an exception' do
        expect { command.call }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with gadget: nil' do
      it 'should raise an exception' do
        expect { command.call(nil) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with gadget: an Object' do
      it 'should raise an exception' do
        expect { command.call(Object.new.freeze) }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with gadget: a Spec::Gadget' do
      let(:gadget) { Spec::Gadget.new }

      it 'should activate the gadget' do
        expect { command.call(gadget) }
          .to change(gadget, :active?)
          .to be true
      end
    end

    describe 'with gadget: a Spec::Gizmo' do
      let(:gadget) { Spec::Gizmo.new }

      it 'should activate the gizmo' do
        expect { command.call(gadget) }
          .to change(gadget, :active?)
          .to be true
      end
    end
  end
end
