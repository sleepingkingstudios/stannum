# frozen_string_literal: true

require 'stannum/associations/one'
require 'stannum/constraints/type'
require 'stannum/entity'

require 'support/examples/association_examples'

RSpec.describe Stannum::Associations::One do
  include Spec::Support::Examples::AssociationExamples

  subject(:association) do
    described_class.new(name:, type:, options:)
  end

  shared_context 'with an entity' do
    shared_context 'when the association has a value' do
      let(:previous_value) do
        Spec::Reference.new(id: 0, name: 'Previous Reference')
      end
      let(:associations) { super().merge('reference' => previous_value) }

      # Ensure associations are populated before examples.
      before(:example) { entity }
    end

    let(:attributes)   { {} }
    let(:associations) { {} }
    let(:entity)       { Spec::EntityClass.new(**attributes, **associations) }

    example_class 'Spec::EntityClass' do |klass|
      klass.include Stannum::Entity

      klass.association(:one, name, **association_options)
    end
  end

  let(:constructor_options) do
    {}
  end
  let(:name)    { 'reference' }
  let(:type)    { Spec::Reference }
  let(:options) { constructor_options }
  let(:association_options) do
    hsh = { class_name: 'Spec::Reference', inverse: false }

    if options[:foreign_key_name]
      (hsh[:foreign_key] ||= {})[:name] = options[:foreign_key_name]
    end

    if options[:foreign_key_type]
      (hsh[:foreign_key] ||= {})[:type] = options[:foreign_key_type]
    end

    hsh[:inverse] = options[:inverse_name] if options[:inverse_name]

    hsh
  end

  example_class 'Spec::Reference' do |klass|
    klass.include Stannum::Entity

    klass.define_primary_key :id, Integer

    klass.attribute :name, String
  end

  include_examples 'should implement the Association methods'

  describe '#:association' do
    include_context 'with an entity'

    it { expect(entity).to define_reader(association.name) }

    it { expect(entity.send(association.name)).to be nil }

    wrap_context 'when the association has a value' do
      it { expect(entity.send(association.name)).to be == previous_value }
    end
  end

  describe '#:association=' do
    include_context 'with an entity'

    it { expect(entity).to define_writer("#{association.name}=") }

    describe 'with nil' do
      it 'should not change the association value' do
        expect { entity.send("#{association.name}=", nil) }
          .not_to change(entity, association.name)
      end
    end

    describe 'with a value' do
      let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

      it 'should set the association value' do
        expect { entity.send("#{association.name}=", new_value) }
          .to change(entity, association.name)
          .to be == new_value
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should clear the association value' do
          expect { entity.send("#{association.name}=", nil) }
            .to change(entity, association.name)
            .to be nil
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should set the association value' do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(entity, association.name)
            .to be == new_value
        end
      end
    end

    context 'when the association has a foreign key' do
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer
        )
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { entity.send("#{association.name}=", nil) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { entity.send("#{association.name}=", nil) }
            .not_to change(entity, 'reference_id')
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should change the foreign key value' do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(entity, 'reference_id')
            .to be == new_value.primary_key
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { entity.send("#{association.name}=", nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the foreign key value' do
            expect { entity.send("#{association.name}=", nil) }
              .to change(entity, 'reference_id')
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

          it 'should change the foreign key value' do
            expect { association.add_value(entity, new_value) }
              .to change(entity, 'reference_id')
              .to be == new_value.primary_key
          end
        end
      end
    end

    context 'when the association has a foreign key and an inverse' do
      let(:previous_inverse) { Spec::EntityClass.new }
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer,
          inverse:          true,
          inverse_name:     'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      def reset_mocks! # rubocop:disable Metrics/AbcSize
        RSpec::Mocks.space.proxy_for(mock_association).reset

        allow(mock_association).to receive(:add_value)
        allow(mock_association).to receive(:remove_value)
        allow(mock_association)
          .to receive(:get_value)
          .and_return(previous_inverse)
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { entity.send("#{association.name}=", nil) }
            .not_to change(entity, association.name)
        end

        it 'should not change the foreign key value' do
          expect { entity.send("#{association.name}=", nil) }
            .not_to change(entity, 'reference_id')
        end

        it 'should not update the inverse association', :aggregate_failures do
          entity.send("#{association.name}=", nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should set the association value' do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(entity, association.name)
            .to be == new_value
        end

        it 'should change the foreign key value' do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(entity, 'reference_id')
            .to be == new_value.primary_key
        end

        it 'should set the inverse association' do
          entity.send("#{association.name}=", new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value, entity, update_inverse: false)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { entity.send("#{association.name}=", nil) }
              .to change(entity, association.name)
              .to be nil
          end

          it 'should clear the foreign key value' do
            expect { entity.send("#{association.name}=", nil) }
              .to change(entity, 'reference_id')
              .to be nil
          end

          it 'should update the inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", nil)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(previous_value, entity, update_inverse: false)
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should set the association value' do
            expect { entity.send("#{association.name}=", new_value) }
              .to change(entity, association.name)
              .to be == new_value
          end

          it 'should change the foreign key value' do
            expect { association.add_value(entity, new_value) }
              .to change(entity, 'reference_id')
              .to be == new_value.primary_key
          end

          it 'should clear the previous inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value, previous_inverse)
          end

          it 'should set the inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value, entity, update_inverse: false)
          end
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { Spec::EntityClass.new }
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          inverse:      true,
          inverse_name: 'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      def reset_mocks! # rubocop:disable Metrics/AbcSize
        RSpec::Mocks.space.proxy_for(mock_association).reset

        allow(mock_association).to receive(:add_value)
        allow(mock_association).to receive(:remove_value)
        allow(mock_association)
          .to receive(:get_value)
          .and_return(previous_inverse)
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { entity.send("#{association.name}=", nil) }
            .not_to change(entity, association.name)
        end

        it 'should not update the inverse association', :aggregate_failures do
          entity.send("#{association.name}=", nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should set the association value' do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(entity, association.name)
            .to be == new_value
        end

        it 'should set the inverse association' do
          entity.send("#{association.name}=", new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value, entity, update_inverse: false)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { entity.send("#{association.name}=", nil) }
              .to change(entity, association.name)
              .to be nil
          end

          it 'should update the inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", nil)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(previous_value, entity, update_inverse: false)
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should set the association value' do
            expect { entity.send("#{association.name}=", new_value) }
              .to change(entity, association.name)
              .to be == new_value
          end

          it 'should clear the previous inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value, previous_inverse)
          end

          it 'should set the inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value, entity, update_inverse: false)
          end
        end
      end
    end
  end

  describe '#add_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }

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

    context 'when the association has a foreign key' do
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer
        )
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.add_value(entity, nil) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.add_value(entity, nil) }
            .not_to change(entity, 'reference_id')
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.add_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should change the foreign key value' do
          expect { association.add_value(entity, new_value) }
            .to change(entity, 'reference_id')
            .to be == new_value.primary_key
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { association.add_value(entity, nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the foreign key value' do
            expect { association.add_value(entity, nil) }
              .to change(entity, 'reference_id')
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

          it 'should change the foreign key value' do
            expect { association.add_value(entity, new_value) }
              .to change(entity, 'reference_id')
              .to be == new_value.primary_key
          end
        end
      end
    end

    context 'when the association has a foreign key and an inverse' do
      let(:previous_inverse) { Spec::EntityClass.new }
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer,
          inverse:          true,
          inverse_name:     'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      def reset_mocks! # rubocop:disable Metrics/AbcSize
        RSpec::Mocks.space.proxy_for(mock_association).reset

        allow(mock_association).to receive(:add_value)
        allow(mock_association).to receive(:remove_value)
        allow(mock_association)
          .to receive(:get_value)
          .and_return(previous_inverse)
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.add_value(entity, nil) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.add_value(entity, nil) }
            .not_to change(entity, 'reference_id')
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.remove_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.add_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should change the foreign key value' do
          expect { association.add_value(entity, new_value) }
            .to change(entity, 'reference_id')
            .to be == new_value.primary_key
        end

        it 'should set the inverse association' do
          association.add_value(entity, new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value, entity, update_inverse: false)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { association.add_value(entity, nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the foreign key value' do
            expect { association.add_value(entity, nil) }
              .to change(entity, 'reference_id')
              .to be nil
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.add_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should change the association value' do
            expect { association.add_value(entity, new_value) }
              .to change(entity, name)
              .to be new_value
          end

          it 'should change the foreign key value' do
            expect { association.add_value(entity, new_value) }
              .to change(entity, 'reference_id')
              .to be == new_value.primary_key
          end

          it 'should clear the previous inverse association' do
            reset_mocks!

            association.add_value(entity, new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value, previous_inverse)
          end

          it 'should set the inverse association' do
            reset_mocks!

            association.add_value(entity, new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def add_value
              association.add_value(
                entity,
                new_value,
                update_inverse: false
              )
            end

            it 'should change the association value' do
              expect { add_value }
                .to change(entity, name)
                .to be new_value
            end

            it 'should change the foreign key value' do
              expect { association.add_value(entity, new_value) }
                .to change(entity, 'reference_id')
                .to be == new_value.primary_key
            end

            it 'should not update the inverse association', \
              :aggregate_failures \
            do
              reset_mocks!

              add_value

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { Spec::EntityClass.new }
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          inverse:      true,
          inverse_name: 'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      def reset_mocks! # rubocop:disable Metrics/AbcSize
        RSpec::Mocks.space.proxy_for(mock_association).reset

        allow(mock_association).to receive(:add_value)
        allow(mock_association).to receive(:remove_value)
        allow(mock_association)
          .to receive(:get_value)
          .and_return(previous_inverse)
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.add_value(entity, nil) }
            .not_to change(entity, name)
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.add_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.add_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should set the inverse association' do
          association.add_value(entity, new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value, entity, update_inverse: false)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { association.add_value(entity, nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.add_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should change the association value' do
            expect { association.add_value(entity, new_value) }
              .to change(entity, name)
              .to be new_value
          end

          it 'should clear the previous inverse association' do
            reset_mocks!

            association.add_value(entity, new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value, previous_inverse)
          end

          it 'should set the inverse association' do
            reset_mocks!

            association.add_value(entity, new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def add_value
              association.add_value(
                entity,
                new_value,
                update_inverse: false
              )
            end

            it 'should change the association value' do
              expect { add_value }
                .to change(entity, name)
                .to be new_value
            end

            it 'should not update the inverse association', \
              :aggregate_failures \
            do
              reset_mocks!

              add_value

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end
  end

  describe '#clear_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }

    it 'should not change the association value' do
      expect { association.clear_value(entity) }
        .not_to change(entity, name)
    end

    wrap_context 'when the association has a value' do
      it 'should clear the association value' do
        expect { association.clear_value(entity) }
          .to change(entity, name)
          .to be nil
      end
    end

    context 'when the association has a foreign key' do
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer
        )
      end

      it 'should not change the association value' do
        expect { association.clear_value(entity) }
          .not_to change(entity, name)
      end

      wrap_context 'when the association has a value' do
        it 'should clear the association value' do
          expect { association.clear_value(entity) }
            .to change(entity, name)
            .to be nil
        end

        it 'should clear the association foreign key value' do
          expect { association.clear_value(entity) }
            .to change(entity, 'reference_id')
            .to be nil
        end
      end
    end

    context 'when the association has a foreign key and an inverse' do
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer,
          inverse:          true,
          inverse_name:     'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      it 'should not change the association value' do
        expect { association.clear_value(entity) }
          .not_to change(entity, name)
      end

      it 'should not change the foreign key value' do
        expect { association.clear_value(entity) }
          .not_to change(entity, 'reference_id')
      end

      it 'should not update the inverse association' do
        association.clear_value(entity)

        expect(mock_association).not_to have_received(:remove_value)
      end

      wrap_context 'when the association has a value' do
        it 'should clear the association value' do
          expect { association.clear_value(entity) }
            .to change(entity, name)
            .to be nil
        end

        it 'should clear the association foreign key value' do
          expect { association.clear_value(entity) }
            .to change(entity, 'reference_id')
            .to be nil
        end

        it 'should update the inverse association' do
          association.clear_value(entity)

          expect(mock_association)
            .to have_received(:remove_value)
            .with(previous_value, entity, update_inverse: false)
        end

        describe 'with update_inverse: false' do
          it 'should clear the association value' do
            expect { association.clear_value(entity, update_inverse: false) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the association foreign key value' do
            expect { association.clear_value(entity, update_inverse: false) }
              .to change(entity, 'reference_id')
              .to be nil
          end

          it 'should not update the inverse association' do
            association.clear_value(entity, update_inverse: false)

            expect(mock_association).not_to have_received(:remove_value)
          end
        end
      end
    end

    context 'when the association has an inverse' do
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          inverse:      true,
          inverse_name: 'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      it 'should not change the association value' do
        expect { association.clear_value(entity) }
          .not_to change(entity, name)
      end

      it 'should not update the inverse association' do
        association.clear_value(entity)

        expect(mock_association).not_to have_received(:remove_value)
      end

      wrap_context 'when the association has a value' do
        it 'should clear the association value' do
          expect { association.clear_value(entity) }
            .to change(entity, name)
            .to be nil
        end

        it 'should update the inverse association' do
          association.clear_value(entity)

          expect(mock_association)
            .to have_received(:remove_value)
            .with(previous_value, entity, update_inverse: false)
        end

        describe 'with update_inverse: false' do
          it 'should clear the association value' do
            expect { association.clear_value(entity, update_inverse: false) }
              .to change(entity, name)
              .to be nil
          end

          it 'should not update the inverse association' do
            association.clear_value(entity, update_inverse: false)

            expect(mock_association).not_to have_received(:remove_value)
          end
        end
      end
    end
  end

  describe '#foreign_key?' do
    it { expect(association.foreign_key?).to be false }

    context 'with options: { foreign_key_name: a string }' do
      let(:options) do
        {
          'foreign_key_name' => 'reference_uuid',
          'foreign_key_type' => String
        }
      end

      it { expect(association.foreign_key?).to be true }
    end

    context 'with options: { foreign_key_name: a symbol }' do
      let(:options) do
        {
          'foreign_key_name' => :reference_uuid,
          'foreign_key_type' => String
        }
      end

      it { expect(association.foreign_key?).to be true }
    end
  end

  describe '#foreign_key_name' do
    it { expect(association.foreign_key_name).to be nil }

    context 'with options: { foreign_key_name: a string }' do
      let(:options) do
        {
          'foreign_key_name' => 'reference_id',
          'foreign_key_type' => String
        }
      end
      let(:expected) { options['foreign_key_name'] }

      it { expect(association.foreign_key_name).to be == expected }
    end

    context 'with options: { foreign_key_name: a symbol }' do
      let(:options) do
        {
          'foreign_key_name' => :reference_id,
          'foreign_key_type' => String
        }
      end
      let(:expected) { options['foreign_key_name'].to_s }

      it { expect(association.foreign_key_name).to be == expected }
    end
  end

  describe '#foreign_key_type' do
    it { expect(association.foreign_key_type).to be nil }

    context 'with options: { foreign_key_type: a class }' do
      let(:options) do
        {
          'foreign_key_name' => 'reference_id',
          'foreign_key_type' => String
        }
      end

      it { expect(association.foreign_key_type).to be String }
    end

    context 'with options: { foreign_key_type: a String }' do
      let(:options) do
        {
          'foreign_key_name' => 'reference_id',
          'foreign_key_type' => 'String'
        }
      end

      it { expect(association.foreign_key_type).to be == 'String' }
    end
  end

  describe '#get_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }

    it { expect(association.get_value(entity)).to be nil }

    wrap_context 'when the association has a value' do
      it { expect(association.get_value(entity)).to be previous_value }
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

    let(:options) { super().merge(inverse: false) }

    describe 'with another value' do
      let(:value) { Spec::Reference.new(name: 'Other Reference') }

      it 'should not change the association value' do
        expect { association.remove_value(entity, value) }
          .not_to change(entity, name)
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with another value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, name)
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

    context 'when the association has a foreign key' do
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer
        )
      end

      describe 'with another foreign key' do
        it 'should not change the association value' do
          expect { association.remove_value(entity, 65_535) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.remove_value(entity, 65_535) }
            .not_to change(entity, 'reference_id')
        end
      end

      describe 'with another value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, 'reference_id')
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with another foreign key' do
          it 'should not change the association value' do
            expect { association.remove_value(entity, 65_535) }
              .not_to change(entity, name)
          end

          it 'should not change the foreign key value' do
            expect { association.remove_value(entity, 65_535) }
              .not_to change(entity, 'reference_id')
          end
        end

        describe 'with another value' do
          let(:value) { Spec::Reference.new(name: 'Other Reference') }

          it 'should not change the association value' do
            expect { association.remove_value(entity, value) }
              .not_to change(entity, name)
          end

          it 'should not change the foreign key value' do
            expect { association.remove_value(entity, value) }
              .not_to change(entity, 'reference_id')
          end
        end

        describe 'with the association foreign key' do
          it 'should clear the association value' do
            expect { association.remove_value(entity, previous_value.id) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the association foreign key value' do
            expect { association.remove_value(entity, previous_value.id) }
              .to change(entity, 'reference_id')
              .to be nil
          end
        end

        describe 'with the association value' do
          it 'should clear the association value' do
            expect { association.remove_value(entity, previous_value) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the association foreign key value' do
            expect { association.remove_value(entity, previous_value) }
              .to change(entity, 'reference_id')
              .to be nil
          end
        end
      end
    end

    context 'when the association has a foreign key and an inverse' do
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer,
          inverse:          true,
          inverse_name:     'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      describe 'with another foreign key' do
        it 'should not change the association value' do
          expect { association.remove_value(entity, 65_535) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.remove_value(entity, 65_535) }
            .not_to change(entity, 'reference_id')
        end

        it 'should not update the inverse association' do
          association.remove_value(entity, 65_535)

          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with another value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, 'reference_id')
        end

        it 'should not update the inverse association' do
          association.remove_value(entity, value)

          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with another foreign key' do
          it 'should not change the association value' do
            expect { association.remove_value(entity, 65_535) }
              .not_to change(entity, name)
          end

          it 'should not change the foreign key value' do
            expect { association.remove_value(entity, 65_535) }
              .not_to change(entity, 'reference_id')
          end

          it 'should not update the inverse association' do
            association.remove_value(entity, 65_535)

            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with another value' do
          let(:value) { Spec::Reference.new(name: 'Other Reference') }

          it 'should not change the association value' do
            expect { association.remove_value(entity, value) }
              .not_to change(entity, name)
          end

          it 'should not change the foreign key value' do
            expect { association.remove_value(entity, value) }
              .not_to change(entity, 'reference_id')
          end

          it 'should not update the inverse association' do
            association.remove_value(entity, value)

            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with the association foreign key' do
          it 'should clear the association value' do
            expect { association.remove_value(entity, previous_value.id) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the association foreign key value' do
            expect { association.remove_value(entity, previous_value.id) }
              .to change(entity, 'reference_id')
              .to be nil
          end

          it 'should update the inverse association' do
            association.remove_value(entity, previous_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(previous_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def remove_value
              association.remove_value(
                entity,
                previous_value,
                update_inverse: false
              )
            end

            it 'should clear the association value' do
              expect { remove_value }
                .to change(entity, name)
                .to be nil
            end

            it 'should clear the association foreign key value' do
              expect { remove_value }
                .to change(entity, 'reference_id')
                .to be nil
            end

            it 'should not update the inverse association' do
              remove_value

              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end

        describe 'with the association value' do
          it 'should clear the association value' do
            expect { association.remove_value(entity, previous_value) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the association foreign key value' do
            expect { association.remove_value(entity, previous_value) }
              .to change(entity, 'reference_id')
              .to be nil
          end

          it 'should update the inverse association' do
            association.remove_value(entity, previous_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(previous_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def remove_value
              association.remove_value(
                entity,
                previous_value,
                update_inverse: false
              )
            end

            it 'should clear the association value' do
              expect { remove_value }
                .to change(entity, name)
                .to be nil
            end

            it 'should clear the association foreign key value' do
              expect { remove_value }
                .to change(entity, 'reference_id')
                .to be nil
            end

            it 'should not update the inverse association' do
              remove_value

              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end

    context 'when the association has an inverse' do
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          inverse:      true,
          inverse_name: 'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      describe 'with another value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(entity, name)
        end

        it 'should not update the inverse association' do
          association.remove_value(entity, value)

          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with another value' do
          let(:value) { Spec::Reference.new(name: 'Other Reference') }

          it 'should not change the association value' do
            expect { association.remove_value(entity, value) }
              .not_to change(entity, name)
          end

          it 'should not update the inverse association' do
            association.remove_value(entity, value)

            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with the association value' do
          it 'should clear the association value' do
            expect { association.remove_value(entity, previous_value) }
              .to change(entity, name)
              .to be nil
          end

          it 'should update the inverse association' do
            association.remove_value(entity, previous_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(previous_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def remove_value
              association.remove_value(
                entity,
                previous_value,
                update_inverse: false
              )
            end

            it 'should clear the association value' do
              expect { remove_value }
                .to change(entity, name)
                .to be nil
            end

            it 'should not update the inverse association' do
              remove_value

              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end
  end

  describe '#set_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }

    describe 'with nil' do
      it 'should not change the association value' do
        expect { association.set_value(entity, nil) }
          .not_to change(entity, name)
      end
    end

    describe 'with a value' do
      let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

      it 'should change the association value' do
        expect { association.set_value(entity, new_value) }
          .to change(entity, name)
          .to be new_value
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should clear the association value' do
          expect { association.set_value(entity, nil) }
            .to change(entity, name)
            .to be nil
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.set_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end
      end
    end

    context 'when the association has a foreign key' do
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer
        )
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.set_value(entity, nil) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.set_value(entity, nil) }
            .not_to change(entity, 'reference_id')
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.set_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should change the foreign key value' do
          expect { association.set_value(entity, new_value) }
            .to change(entity, 'reference_id')
            .to be == new_value.primary_key
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { association.set_value(entity, nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the foreign key value' do
            expect { association.set_value(entity, nil) }
              .to change(entity, 'reference_id')
              .to be nil
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should change the association value' do
            expect { association.set_value(entity, new_value) }
              .to change(entity, name)
              .to be new_value
          end

          it 'should change the foreign key value' do
            expect { association.set_value(entity, new_value) }
              .to change(entity, 'reference_id')
              .to be == new_value.primary_key
          end
        end
      end
    end

    context 'when the association has a foreign key and an inverse' do
      let(:previous_inverse) { Spec::EntityClass.new }
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          foreign_key_name: 'reference_id',
          foreign_key_type: Integer,
          inverse:          true,
          inverse_name:     'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      def reset_mocks! # rubocop:disable Metrics/AbcSize
        RSpec::Mocks.space.proxy_for(mock_association).reset

        allow(mock_association).to receive(:add_value)
        allow(mock_association).to receive(:remove_value)
        allow(mock_association)
          .to receive(:get_value)
          .and_return(previous_inverse)
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.set_value(entity, nil) }
            .not_to change(entity, name)
        end

        it 'should not change the foreign key value' do
          expect { association.set_value(entity, nil) }
            .not_to change(entity, 'reference_id')
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.remove_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.set_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should change the foreign key value' do
          expect { association.set_value(entity, new_value) }
            .to change(entity, 'reference_id')
            .to be == new_value.primary_key
        end

        it 'should set the inverse association' do
          association.set_value(entity, new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value, entity, update_inverse: false)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { association.set_value(entity, nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should clear the foreign key value' do
            expect { association.set_value(entity, nil) }
              .to change(entity, 'reference_id')
              .to be nil
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should change the association value' do
            expect { association.set_value(entity, new_value) }
              .to change(entity, name)
              .to be new_value
          end

          it 'should change the foreign key value' do
            expect { association.set_value(entity, new_value) }
              .to change(entity, 'reference_id')
              .to be == new_value.primary_key
          end

          it 'should clear the previous inverse association' do
            reset_mocks!

            association.set_value(entity, new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value, previous_inverse)
          end

          it 'should set the inverse association' do
            reset_mocks!

            association.set_value(entity, new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def set_value
              association.set_value(
                entity,
                new_value,
                update_inverse: false
              )
            end

            it 'should change the association value' do
              expect { set_value }
                .to change(entity, name)
                .to be new_value
            end

            it 'should change the foreign key value' do
              expect { association.set_value(entity, new_value) }
                .to change(entity, 'reference_id')
                .to be == new_value.primary_key
            end

            it 'should not update the inverse association', \
              :aggregate_failures \
            do
              reset_mocks!

              set_value

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { Spec::EntityClass.new }
      let(:mock_association) do
        instance_double(
          Stannum::Association,
          add_value:    nil,
          get_value:    nil,
          remove_value: nil
        )
      end
      let(:options) do
        super().merge(
          inverse:      true,
          inverse_name: 'entity'
        )
      end

      before(:example) do
        allow(Spec::Reference.associations)
          .to receive(:[])
          .with('entity')
          .and_return(mock_association)
      end

      def reset_mocks! # rubocop:disable Metrics/AbcSize
        RSpec::Mocks.space.proxy_for(mock_association).reset

        allow(mock_association).to receive(:add_value)
        allow(mock_association).to receive(:remove_value)
        allow(mock_association)
          .to receive(:get_value)
          .and_return(previous_inverse)
      end

      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.set_value(entity, nil) }
            .not_to change(entity, name)
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.remove_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

        it 'should change the association value' do
          expect { association.set_value(entity, new_value) }
            .to change(entity, name)
            .to be new_value
        end

        it 'should set the inverse association' do
          association.set_value(entity, new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value, entity, update_inverse: false)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should clear the association value' do
            expect { association.set_value(entity, nil) }
              .to change(entity, name)
              .to be nil
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with a value' do
          let(:new_value) { Spec::Reference.new(id: 1, name: 'New Reference') }

          it 'should change the association value' do
            expect { association.set_value(entity, new_value) }
              .to change(entity, name)
              .to be new_value
          end

          it 'should clear the previous inverse association' do
            reset_mocks!

            association.set_value(entity, new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value, previous_inverse)
          end

          it 'should set the inverse association' do
            reset_mocks!

            association.set_value(entity, new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def set_value
              association.set_value(
                entity,
                new_value,
                update_inverse: false
              )
            end

            it 'should change the association value' do
              expect { set_value }
                .to change(entity, name)
                .to be new_value
            end

            it 'should not update the inverse association', \
              :aggregate_failures \
            do
              reset_mocks!

              set_value

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end
  end
end
