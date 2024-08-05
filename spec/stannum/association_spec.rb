# frozen_string_literal: true

require 'stannum/association'

require 'support/examples/association_examples'

RSpec.describe Stannum::Association do
  include Spec::Support::Examples::AssociationExamples

  subject(:association) do
    described_class.new(name:, type:, options:)
  end

  let(:constructor_options) do
    {}
  end
  let(:name)    { 'reference' }
  let(:type)    { Spec::Reference }
  let(:options) { constructor_options }

  example_class 'Spec::Reference' do |klass|
    klass.include Stannum::Entity
  end

  describe '::AbstractAssociationError' do
    include_examples 'should define constant',
      :AbstractAssociationError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::InverseAssociationError' do
    include_examples 'should define constant',
      :InverseAssociationError,
      -> { be_a(Class).and(be < StandardError) }
  end

  describe '::Builder' do
    subject(:builder) do
      described_class::Builder.new(entity_class::Associations)
    end

    let(:entity_class) { Spec::Entity }

    example_class 'Spec::Entity' do |klass|
      klass.include Stannum::Entities::Properties
      klass.include Stannum::Entities::Associations

      klass.define_method(:set_properties) { |values, **| @attributes = values }
    end

    include_examples 'should implement the Association::Builder methods'
  end

  include_examples 'should implement the Association methods'

  describe '#add_value' do
    let(:entity) { Object.new.freeze }
    let(:value)  { Object.new.freeze }
    let(:error_message) do
      "#{described_class} is an abstract class - use an association subclass"
    end

    it 'should raise an exception' do
      expect { association.add_value(entity, value) }.to raise_error(
        described_class::AbstractAssociationError,
        error_message
      )
    end
  end

  describe '#foreign_key?' do
    it { expect(association.foreign_key?).to be false }
  end

  describe '#foreign_key_name' do
    it { expect(association.foreign_key_name).to be nil }
  end

  describe '#foreign_key_type' do
    it { expect(association.foreign_key_type).to be nil }
  end

  describe '#get_value' do
    let(:entity) { Object.new.freeze }
    let(:error_message) do
      "#{described_class} is an abstract class - use an association subclass"
    end

    it 'should raise an exception' do
      expect { association.get_value(entity) }.to raise_error(
        described_class::AbstractAssociationError,
        error_message
      )
    end
  end

  describe '#many?' do
    it { expect(association.many?).to be false }
  end

  describe '#one?' do
    it { expect(association.one?).to be false }
  end

  describe '#remove_value' do
    let(:entity) { Object.new.freeze }
    let(:value)  { Object.new.freeze }
    let(:error_message) do
      "#{described_class} is an abstract class - use an association subclass"
    end

    it 'should raise an exception' do
      expect { association.remove_value(entity, value) }.to raise_error(
        described_class::AbstractAssociationError,
        error_message
      )
    end
  end
end
