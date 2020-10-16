# frozen_string_literal: true

require 'support/contracts/manufacturer_contract'
require 'support/structs/factory'
require 'support/structs/gadget'
require 'support/structs/manufacturer'

# @note Integration spec for Stannum::Contracts::PropertyContract.
RSpec.describe Spec::ManufacturerContract do
  subject(:contract) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '#does_not_match?' do
    let(:status) { contract.does_not_match?(actual) }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(status).to be true }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new
        )
      end

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new(
            gadget: Spec::Gadget.new(
              name: 'Ambrosia Software Licenses'
            )
          )
        )
      end

      it { expect(status).to be false }
    end
  end

  describe '#errors_for' do
    let(:errors) { contract.errors_for(actual) }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an object that matches the sanity constraints' do
      let(:actual) { Spec::Manufacturer.new }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    %i[registered_name],
            type:    Stannum::Constraints::Presence::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[factory gadget name],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new
        )
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    %i[factory gadget name],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new(
            gadget: Spec::Gadget.new(
              name: 'Ambrosia Software Licenses'
            )
          )
        )
      end

      it { expect(errors).to be == [] }
    end
  end

  describe '#match' do
    let(:status) { Array(contract.match(actual))[0] }
    let(:errors) { Array(contract.match(actual))[1] }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an object that matches the sanity constraints' do
      let(:actual) { Spec::Manufacturer.new }
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    %i[registered_name],
            type:    Stannum::Constraints::Presence::TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[factory gadget name],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new
        )
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    %i[factory gadget name],
            type:    Stannum::Constraints::Presence::TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new(
            gadget: Spec::Gadget.new(
              name: 'Ambrosia Software Licenses'
            )
          )
        )
      end

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end
  end

  describe '#matches?' do
    let(:status) { contract.matches?(actual) }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(status).to be false }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new
        )
      end

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new(
            gadget: Spec::Gadget.new(
              name: 'Ambrosia Software Licenses'
            )
          )
        )
      end

      it { expect(status).to be true }
    end
  end

  describe '#negated_errors_for' do
    let(:errors) { contract.negated_errors_for(actual) }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(errors).to be == [] }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new
        )
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[registered_name],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new(
            gadget: Spec::Gadget.new(
              name: 'Ambrosia Software Licenses'
            )
          )
        )
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[registered_name],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[factory gadget name],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }
    end
  end

  describe '#negated_match' do
    let(:status) { Array(contract.negated_match(actual))[0] }
    let(:errors) { Array(contract.negated_match(actual))[1] }

    describe 'with an object that does not match any constraints' do
      let(:actual) { nil }

      it { expect(errors).to be == [] }

      it { expect(status).to be true }
    end

    describe 'with an object that matches some of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new
        )
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[registered_name],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end

    describe 'with an object that matches all of the constraints' do
      let(:actual) do
        Spec::Manufacturer.new(
          name:    'Gadget Co.',
          factory: Spec::Factory.new(
            gadget: Spec::Gadget.new(
              name: 'Ambrosia Software Licenses'
            )
          )
        )
      end
      let(:expected_errors) do
        [
          {
            data:    {},
            message: nil,
            path:    [],
            type:    described_class::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[registered_name],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          },
          {
            data:    {},
            message: nil,
            path:    %i[factory gadget name],
            type:    Stannum::Constraints::Presence::NEGATED_TYPE
          }
        ]
      end

      it { expect(errors).to be == expected_errors }

      it { expect(status).to be false }
    end
  end
end
