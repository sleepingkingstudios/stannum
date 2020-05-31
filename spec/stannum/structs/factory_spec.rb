# frozen_string_literal: true

require 'stannum/structs/factory'

RSpec.describe Stannum::Structs::Factory do
  subject(:factory) { described_class.new }

  describe '.new' do
    it { expect(described_class).to be_constructible.with(0).arguments }
  end

  describe '.instance' do
    it 'should define the class method' do
      expect(described_class).to respond_to(:instance).with(0).arguments
    end

    it 'should return a factory instance' do
      expect(described_class.instance).to be_a described_class
    end

    it 'should cache the instance' do
      previous_instance = described_class.instance

      expect(described_class.instance).to be previous_instance
    end
  end

  describe '#call' do
    it { expect(factory).to respond_to(:call).with(1).argument }

    describe 'with nil' do
      let(:error_message) { 'struct class must be a Class' }

      it 'should raise an error' do
        expect { factory.call nil }.to raise_error ArgumentError, error_message
      end
    end

    describe 'with an object' do
      let(:error_message) { 'struct class must be a Class' }

      it 'should raise an error' do
        expect { factory.call Object.new.freeze }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a module' do
      let(:error_message) { 'struct class must be a Class' }

      it 'should raise an error' do
        expect { factory.call Module.new }
          .to raise_error ArgumentError, error_message
      end
    end

    describe 'with a class' do
      example_class 'Spec::CustomStruct'

      it 'should define ::Attributes' do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct)
          .to define_constant(:Attributes)
          .with_value(an_instance_of Stannum::Structs::Attributes)
      end

      it 'should include ::Attributes' do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct).to be < Spec::CustomStruct::Attributes
      end

      it 'should define ::Contract' do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct)
          .to define_constant(:Contract)
          .with_value(an_instance_of Stannum::Contracts::MapContract)
      end
    end

    describe 'with a class with a struct ancestor' do
      example_class 'Spec::AncestorStruct' do |klass|
        factory.call(klass)
      end

      example_class 'Spec::CustomStruct', 'Spec::AncestorStruct'

      it 'should define ::Attributes', :aggregate_failures do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct)
          .to define_constant(:Attributes)
          .with_value(an_instance_of Stannum::Structs::Attributes)

        expect(Spec::CustomStruct::Attributes)
          .not_to be Spec::AncestorStruct::Attributes
      end

      it 'should include the parent ::Attributes' do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct::Attributes)
          .to be < Spec::AncestorStruct::Attributes
      end

      it 'should include ::Attributes' do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct).to be < Spec::CustomStruct::Attributes
      end

      it 'should define ::Contract', :aggregate_failures do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct)
          .to define_constant(:Contract)
          .with_value(an_instance_of Stannum::Contracts::MapContract)

        expect(Spec::CustomStruct::Contract)
          .not_to be Spec::AncestorStruct::Contract
      end

      it 'should include the parent ::Contract' do
        factory.call(Spec::CustomStruct)

        expect(Spec::CustomStruct::Contract.send :included)
          .to include(Spec::AncestorStruct::Contract)
      end
    end

    describe 'with a class that is already a struct class' do
      example_class 'Spec::CustomStruct' do |klass|
        factory.call(klass)
      end

      it 'should not change ::Attributes' do
        expect { factory.call(Spec::CustomStruct) }
          .not_to(change { Spec::CustomStruct::Attributes })
      end

      it 'should not change ::Contract' do
        expect { factory.call(Spec::CustomStruct) }
          .not_to(change { Spec::CustomStruct::Contract })
      end
    end
  end
end
