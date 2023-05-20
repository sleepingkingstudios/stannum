# frozen_string_literal: true

require 'stannum/association'

require 'support/examples/association_examples'

RSpec.describe Stannum::Association do
  include Spec::Support::Examples::AssociationExamples

  subject(:association) do
    described_class.new(name: name, type: type, options: options)
  end

  let(:constructor_options) do
    {}
  end
  let(:name)    { 'reference' }
  let(:type)    { Spec::Reference }
  let(:options) { constructor_options }

  example_class 'Spec::Reference'

  describe '::Builder' do
    subject(:builder) do
      described_class::Builder.new(entity_class)
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

  describe '#many?' do
    it { expect(association.many?).to be false }
  end

  describe '#one?' do
    it { expect(association.one?).to be false }
  end
end
