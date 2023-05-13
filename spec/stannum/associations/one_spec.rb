# frozen_string_literal: true

require 'stannum/associations/one'

require 'support/examples/association_examples'

RSpec.describe Stannum::Associations::One do
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

      klass.define_method(:set_properties) do |values, **|
        @associations = values
      end
    end

    include_examples 'should implement the Association::Builder methods'

    describe '#call' do
      let(:association) do
        described_class.new(name: name, type: type, options: options)
      end
      let(:values) { {} }
      let(:entity) { entity_class.new(**values) }

      describe '#:association' do
        before(:example) { builder.call(association) }

        it { expect(entity).to define_reader(association.name) }

        it { expect(entity.send(association.name)).to be nil }

        context 'when the association has a value' do
          let(:values) do
            { 'reference' => Spec::Reference.new }
          end

          it 'should get the association value' do
            expect(entity.send(association.name))
              .to be == values[association.name]
          end
        end
      end

      describe '#:association=' do
        let(:value) { Spec::Reference.new }

        before(:example) { builder.call(association) }

        it { expect(entity).to define_writer("#{association.name}=") }

        it 'should set the association value' do
          expect { entity.send("#{association.name}=", value) }
            .to change(entity, association.name)
            .to be == value
        end

        # rubocop:disable RSpec/NestedGroups
        context 'when the association has a value' do
          let(:values) do
            { 'reference' => Spec::Reference.new }
          end

          describe 'with nil' do
            it 'should clear the association value' do
              expect { entity.send("#{association.name}=", nil) }
                .to change(entity, association.name)
                .to be nil
            end
          end

          describe 'with a value' do
            it 'should set the association value' do
              expect { entity.send("#{association.name}=", value) }
                .to change(entity, association.name)
                .to be == value
            end
          end
        end
        # rubocop:enable RSpec/NestedGroups
      end
    end
  end

  include_examples 'should implement the Association methods'

  describe '#many?' do
    it { expect(association.many?).to be false }
  end

  describe '#one?' do
    it { expect(association.one?).to be true }
  end
end
