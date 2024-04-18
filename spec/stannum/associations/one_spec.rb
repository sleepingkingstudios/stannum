# frozen_string_literal: true

require 'stannum/associations/one'
require 'stannum/constraints/type'
require 'stannum/entity'

require 'support/examples/association_examples'

RSpec.describe Stannum::Associations::One do
  include Spec::Support::Examples::AssociationExamples

  subject(:association) do
    described_class.new(name: name, type: type, options: options)
  end

  shared_context 'with an entity' do
    shared_context 'when the association has a value' do
      let(:previous_value) do
        Spec::Reference.new(id: 0, name: 'Previous Reference')
      end
      let(:associations) { { 'reference' => previous_value } }
    end

    let(:attributes)   { {} }
    let(:associations) { {} }
    let(:entity)       { Spec::EntityClass.new(**attributes, **associations) }

    example_class 'Spec::EntityClass' do |klass|
      klass.include Stannum::Entity

      klass.association(:one, name, **options.merge(class_name: type.name))
    end
  end

  let(:constructor_options) do
    {}
  end
  let(:name)    { 'reference' }
  let(:type)    { Spec::Reference }
  let(:options) { constructor_options }

  example_class 'Spec::Reference' do |klass|
    klass.include Stannum::Entity

    klass.define_primary_key :id, Integer

    klass.attribute :name, String
  end

  describe '::Builder' do
    subject(:builder) do
      described_class::Builder.new(entity_class::Associations)
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

  describe '#add_value' do
    include_context 'with an entity'

    describe 'with nil' do
      it 'should not change the association value' do
        expect { association.add_value(entity, nil) }
          .not_to change(entity, name)
      end
    end

    describe 'with a value' do
      let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

      it 'should change the association value' do
        expect { association.add_value(entity, new_value) }
          .to change(entity, name)
          .to be new_value
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should clear the association value' do
          expect { association.add_value(entity, nil) }
            .to change(entity, name)
            .to be nil
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.add_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end
      end
    end
  end

  describe '#foreign_key?' do
    include_examples 'should define predicate', :foreign_key?, false

    context 'with options: { foreign_key_name: a string }' do
      let(:options) { { 'foreign_key_name' => 'reference_uuid' } }

      it { expect(association.foreign_key?).to be true }
    end

    context 'with options: { foreign_key_name: a symbol }' do
      let(:options) { { 'foreign_key_name' => :reference_uuid } }

      it { expect(association.foreign_key?).to be true }
    end
  end

  describe '#foreign_key_name' do
    include_examples 'should define reader', :foreign_key_name, nil

    context 'with options: { foreign_key_name: a string }' do
      let(:options)  { { 'foreign_key_name' => 'reference_id' } }
      let(:expected) { options['foreign_key_name'] }

      it { expect(association.foreign_key_name).to be == expected }
    end

    context 'with options: { foreign_key_name: a symbol }' do
      let(:options) { { 'foreign_key_name' => :reference_id } }
      let(:expected) { options['foreign_key_name'].to_s }

      it { expect(association.foreign_key_name).to be == expected }
    end
  end

  describe '#foreign_key_type' do
    include_examples 'should define reader', :foreign_key_type, nil

    context 'with options: { foreign_key_name: a class }' do
      let(:options) do
        {
          'foreign_key_name' => 'reference_id',
          'foreign_key_type' => String
        }
      end

      it { expect(association.foreign_key_type).to be String }
    end

    context 'with options: { foreign_key_name: a constraint }' do
      let(:constraint) { Stannum::Constraints::Uuid.new }
      let(:options) do
        {
          'foreign_key_name' => 'reference_id',
          'foreign_key_type' => constraint
        }
      end

      it { expect(association.foreign_key_type).to be constraint }
    end
  end

  describe '#many?' do
    it { expect(association.many?).to be false }
  end

  describe '#one?' do
    it { expect(association.one?).to be true }
  end

  describe '#remove_value' do
    include_context 'with an entity'

    describe 'with another foreign key' do
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer
        )
      end

      it 'should not change the association value' do
        expect { association.remove_value(entity, 65_535) }
          .not_to change(entity, name)
      end
    end

    describe 'with another value' do
      let(:value) { Spec::Reference.new(name: 'Other Reference') }

      it 'should not change the association value' do
        expect { association.remove_value(entity, value) }
          .not_to change(entity, name)
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with another foreign key' do
        let(:options) do
          super().merge(
            foreign_key_name: 'reference_id',
            foreign_key_type: Integer
          )
        end

        it 'should not change the association value' do
          expect { association.remove_value(entity, 65_535) }
            .not_to change(entity, name)
        end
      end

      describe 'with another value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, name)
        end
      end

      describe 'with the association foreign key' do
        let(:options) do
          super().merge(
            foreign_key_name: 'reference_id',
            foreign_key_type: Integer
          )
        end

        it 'should clear the association foreign key' do
          expect { association.remove_value(entity, previous_value.id) }
            .to change(entity, name)
            .to be nil
        end
      end

      describe 'with the association value' do
        it 'should clear the association value' do
          expect { association.remove_value(entity, previous_value) }
            .to change(entity, name)
            .to be nil
        end
      end
    end
  end

  describe '#value' do
    include_context 'with an entity'

    it { expect(association.value(entity)).to be nil }

    wrap_context 'when the association has a value' do
      it { expect(association.value(entity)).to be previous_value }
    end
  end
end
