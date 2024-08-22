# frozen_string_literal: true

require 'stannum/associations/many'
require 'stannum/constraints/type'
require 'stannum/entity'

require 'support/examples/association_examples'

RSpec.describe Stannum::Associations::Many do
  include Spec::Support::Examples::AssociationExamples

  subject(:association) do
    described_class.new(name:, type:, options:)
  end

  shared_context 'with an entity' do
    shared_context 'when the association has a value' do
      let(:previous_value) do
        [
          Spec::Reference.new(id: 0, name: 'Previous Reference 0'),
          Spec::Reference.new(id: 1, name: 'Previous Reference 1'),
          Spec::Reference.new(id: 2, name: 'Previous Reference 2')
        ]
      end
      let(:associations) { super().merge('references' => previous_value) }

      # Ensure associations are populated before examples.
      before(:example) { entity }
    end

    let(:attributes)   { { name: 'Entity' } }
    let(:associations) { {} }
    let(:entity)       { Spec::EntityClass.new(**attributes, **associations) }

    example_class 'Spec::EntityClass' do |klass|
      klass.include Stannum::Entity

      klass.association(:many, name, **association_options)

      klass.define_attribute :name, String
    end
  end

  let(:constructor_options) do
    {}
  end
  let(:name)    { 'references' }
  let(:type)    { Spec::Reference }
  let(:options) { constructor_options }
  let(:association_options) do
    hsh = { class_name: 'Spec::Reference', inverse: false }

    hsh[:inverse] = options[:inverse_name] if options[:inverse_name]

    hsh
  end

  example_class 'Spec::Reference' do |klass|
    klass.include Stannum::Entity

    klass.define_primary_key :id, Integer

    klass.attribute :name, String
  end

  describe '::Proxy' do
    include_context 'with an entity'

    subject(:proxy) { described_class.new(association:, entity:) }

    let(:described_class) { super()::Proxy }
    let(:association) do
      Stannum::Associations::Many.new(name:, type:, options:) # rubocop:disable RSpec/DescribedClass
    end

    describe '.new' do
      it 'should define the constructor' do
        expect(described_class)
          .to be_constructible
          .with(0).arguments
          .and_keywords(:association, :entity)
      end
    end

    describe '#==' do
      shared_context 'when the proxy has a non-matching association' do
        let(:other_association) do
          Stannum::Associations::Many.new(name: 'criticisms', type:, options:) # rubocop:disable RSpec/DescribedClass
        end
        let(:other_entity) { Spec::EntityClass.new(criticisms: other_value) }
        let(:other) do
          described_class.new(
            association: other_association,
            entity:      other_entity
          )
        end

        before(:example) do
          Spec::EntityClass.define_association(
            :many,
            'criticisms',
            class_name: 'Spec::Reference',
            inverse:    false
          )
        end
      end

      let(:other_value)  { [] }
      let(:other_entity) { Spec::EntityClass.new(references: other_value) }
      let(:other) do
        described_class.new(
          association:,
          entity:      other_entity
        )
      end

      describe 'with nil' do
        it { expect(proxy == nil).to be false } # rubocop:disable Style/NilComparison
      end

      describe 'with an Object' do
        it { expect(proxy == Object.new.freeze).to be false }
      end

      describe 'with an empty Array' do
        it { expect(proxy == []).to be true }
      end

      describe 'with a non-empty Array' do
        let(:other_value) do
          [
            Spec::Reference.new(id: 3, name: 'Other Reference 0'),
            Spec::Reference.new(id: 4, name: 'Other Reference 1'),
            Spec::Reference.new(id: 5, name: 'Other Reference 2')
          ]
        end

        it { expect(proxy == other_value).to be false }
      end

      describe 'with an empty Proxy with non-matching association' do
        include_context 'when the proxy has a non-matching association'

        it { expect(proxy == other).to be true }
      end

      describe 'with an empty Proxy with matching association' do
        it { expect(proxy == other).to be true }
      end

      describe 'with a non-empty Proxy' do
        let(:other_value) do
          [
            Spec::Reference.new(id: 3, name: 'Other Reference 0'),
            Spec::Reference.new(id: 4, name: 'Other Reference 1'),
            Spec::Reference.new(id: 5, name: 'Other Reference 2')
          ]
        end

        it { expect(proxy == other).to be false }
      end

      wrap_context 'when the association has a value' do
        describe 'with an empty Array' do
          it { expect(proxy == []).to be false }
        end

        describe 'with a non-matching Array' do
          it { expect(proxy == other_value).to be false }
        end

        describe 'with a matching Array' do
          it { expect(proxy == previous_value).to be true }
        end

        describe 'with an empty Proxy' do
          it { expect(proxy == other).to be false }
        end

        describe 'with a non-matching Proxy' do
          let(:other_value) do
            [
              Spec::Reference.new(id: 3, name: 'Other Reference 0'),
              Spec::Reference.new(id: 4, name: 'Other Reference 1'),
              Spec::Reference.new(id: 5, name: 'Other Reference 2')
            ]
          end

          it { expect(proxy == other).to be false }
        end

        describe 'with a matching Proxy with non-matching association' do
          include_context 'when the proxy has a non-matching association'

          let(:other_value) { previous_value }

          it { expect(proxy == other).to be true }
        end

        describe 'with a matching Proxy with matching association' do
          let(:other_value) { previous_value }

          it { expect(proxy == other).to be true }
        end
      end
    end

    describe '#add' do
      let(:error_message) do
        'invalid association item - must be an instance of Spec::Reference'
      end

      before(:example) do
        allow(association).to receive(:add_value)
      end

      it { expect(proxy).to respond_to(:add).with(1).argument }

      it { expect(proxy).to have_aliased_method(:add).as(:<<) }

      it { expect(proxy).to have_aliased_method(:add).as(:push) }

      describe 'with nil' do
        it 'should raise an exception' do
          expect { proxy.add(nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Object' do
        it 'should raise an exception' do
          expect { proxy.add(Object.new.freeze) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Entity' do
        example_class 'Spec::OtherEntity' do |klass|
          klass.include Stannum::Entity
        end

        let(:value) { Spec::OtherEntity.new }

        it 'should raise an exception' do
          expect { proxy.add(value) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an instance of the associated class' do
        let(:value) { Spec::Reference.new(id: 0, name: 'New Reference') }

        it 'should delegate to the association' do
          proxy.add(value)

          expect(association).to have_received(:add_value).with(entity, value)
        end

        it { expect(proxy.add(value)).to be proxy }
      end
    end

    describe '#each' do
      it { expect(proxy).to respond_to(:each).with(0).arguments.and_a_block }

      it { expect(proxy.each).to be_a Enumerator }

      it { expect(proxy.each.to_a).to be == [] }

      it { expect { |block| proxy.each(&block) }.not_to yield_control }

      wrap_context 'when the association has a value' do
        it { expect(proxy.each.to_a).to be == previous_value }

        it 'should yield each item' do
          expect { |block| proxy.each(&block) }
            .to yield_successive_args(*previous_value)
        end
      end
    end

    describe '#entity' do
      include_examples 'should define private reader', :entity, -> { entity }

      context 'when there are many entities' do
        let(:entities) do
          [
            Spec::EntityClass.new(name: 'Entity 0'),
            Spec::EntityClass.new(name: 'Entity 1'),
            Spec::EntityClass.new(name: 'Entity 2')
          ]
        end

        it 'should return the corresponding entity' do
          expect(entities).to all(
            satisfy { |entity| entity.send(name).send(:entity) == entity }
          )
        end
      end
    end

    describe '#inspect' do
      let(:object_id) do
        Object.instance_method(:inspect).bind(proxy).call[39...55]
      end
      let(:expected_items) { '' }
      let(:expected) do
        "#<#{described_class.name}:0x#{object_id} data=[#{expected_items}]>"
      end

      it { expect(proxy.inspect).to be == expected }

      wrap_context 'when the association has a value' do
        let(:expected_items) do
          proxy.map(&:inspect).join(', ')
        end

        it { expect(proxy.inspect).to be == expected }
      end
    end

    describe '#remove' do
      let(:error_message) do
        'invalid association item - must be an instance of Spec::Reference'
      end

      before(:example) do
        allow(association).to receive(:remove_value)
      end

      it { expect(proxy).to respond_to(:remove).with(1).argument }

      it { expect(proxy).to have_aliased_method(:remove).as(:delete) }

      describe 'with nil' do
        it 'should raise an exception' do
          expect { proxy.remove(nil) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Object' do
        it 'should raise an exception' do
          expect { proxy.remove(Object.new.freeze) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an Entity' do
        example_class 'Spec::OtherEntity' do |klass|
          klass.include Stannum::Entity
        end

        let(:value) { Spec::OtherEntity.new }

        it 'should raise an exception' do
          expect { proxy.remove(value) }
            .to raise_error ArgumentError, error_message
        end
      end

      describe 'with an instance of the associated class' do
        let(:value) { Spec::Reference.new(id: 0, name: 'New Reference') }

        it 'should delegate to the association' do
          proxy.remove(value)

          expect(association)
            .to have_received(:remove_value)
            .with(entity, value)
        end

        it { expect(proxy.remove(value)).to be proxy }
      end
    end
  end

  include_examples 'should implement the Association methods'

  describe '#:association' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }
    let(:proxy)   { entity.send(association.name) }

    it { expect(entity).to define_reader(association.name) }

    it { expect(proxy).to be_a described_class::Proxy }

    it { expect(proxy.to_a).to be == [] }

    wrap_context 'when the association has a value' do
      it { expect(proxy.to_a).to be == previous_value }
    end
  end

  describe '#:association=' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }
    let(:proxy)   { association.get_value(entity) }

    it { expect(entity).to define_writer("#{association.name}=") }

    describe 'with nil' do
      it 'should not change the association value' do
        expect { entity.send("#{association.name}=", nil) }
          .not_to change(proxy, :to_a)
      end
    end

    describe 'with an empty Array' do
      it 'should not change the association value' do
        expect { entity.send("#{association.name}=", []) }
          .not_to change(proxy, :to_a)
      end
    end

    describe 'with an Array with one item' do
      let(:new_value) { [Spec::Reference.new(id: 3, name: 'New Reference')] }

      it 'should set the association value', :aggregate_failures do
        expect { entity.send("#{association.name}=", new_value) }
          .to change(proxy, :count)
          .to(new_value.size)

        expect(proxy.to_a).to be == new_value
      end
    end

    describe 'with an Array with many items' do
      let(:new_value) do
        [
          Spec::Reference.new(id: 3, name: 'New Reference 0'),
          Spec::Reference.new(id: 4, name: 'New Reference 1'),
          Spec::Reference.new(id: 5, name: 'New Reference 2')
        ]
      end

      it 'should set the association value', :aggregate_failures do
        expect { entity.send("#{association.name}=", new_value) }
          .to change(proxy, :count)
          .to(new_value.size)

        expect(proxy.to_a).to be == new_value
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should clear the association value' do
          expect { entity.send("#{association.name}=", nil) }
            .to change(proxy, :to_a)
            .to be == []
        end
      end

      describe 'with an empty Array' do
        it 'should clear the association value' do
          expect { entity.send("#{association.name}=", []) }
            .to change(proxy, :to_a)
            .to be == []
        end
      end

      describe 'with an Array with one item' do
        let(:new_value) { [Spec::Reference.new(id: 3, name: 'New Reference')] }

        it 'should set the association value', :aggregate_failures do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(proxy, :count)
            .to(new_value.size)

          expect(proxy.to_a).to be == new_value
        end
      end

      describe 'with an Array with many items' do
        let(:new_value) do
          [
            Spec::Reference.new(id: 3, name: 'New Reference 0'),
            Spec::Reference.new(id: 4, name: 'New Reference 1'),
            Spec::Reference.new(id: 5, name: 'New Reference 2')
          ]
        end

        it 'should set the association value', :aggregate_failures do
          expect { entity.send("#{association.name}=", new_value) }
            .not_to change(proxy, :count)

          expect(proxy.to_a).to be == new_value
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { nil }
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
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          entity.send("#{association.name}=", nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with an empty Array' do
        it 'should not change the association value' do
          expect { entity.send("#{association.name}=", []) }
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          entity.send("#{association.name}=", [])

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with an Array with one item' do
        let(:new_value) { [Spec::Reference.new(id: 3, name: 'New Reference')] }

        it 'should set the association value', :aggregate_failures do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(proxy, :count)
            .to(new_value.size)

          expect(proxy.to_a).to be == new_value
        end

        it 'should set the inverse association' do
          reset_mocks!

          entity.send("#{association.name}=", new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value.first, entity, update_inverse: false)
        end
      end

      describe 'with an Array with many items' do
        let(:new_value) do
          [
            Spec::Reference.new(id: 3, name: 'New Reference 0'),
            Spec::Reference.new(id: 4, name: 'New Reference 1'),
            Spec::Reference.new(id: 5, name: 'New Reference 2')
          ]
        end

        it 'should set the association value', :aggregate_failures do
          expect { entity.send("#{association.name}=", new_value) }
            .to change(proxy, :count)
            .to(new_value.size)

          expect(proxy.to_a).to be == new_value
        end

        it 'should set the inverse associations', :aggregate_failures do
          reset_mocks!

          entity.send("#{association.name}=", new_value)

          new_value.each do |new_item|
            expect(mock_association)
              .to have_received(:add_value)
              .with(new_item, entity, update_inverse: false)
          end
        end
      end

      wrap_context 'when the association has a value' do
        let(:previous_inverse) { entity }
        let(:current_inverse) do
          Spec::EntityClass.new(name: 'Current Inverse')
        end

        describe 'with nil' do
          it 'should clear the association value' do
            expect { entity.send("#{association.name}=", nil) }
              .to change(proxy, :to_a)
              .to be == []
          end

          it 'should clear the previous inverse', :aggregate_failures do
            reset_mocks!

            entity.send("#{association.name}=", nil)

            previous_value.each do |previous_item|
              expect(mock_association)
                .to have_received(:remove_value)
                .with(previous_item, entity, update_inverse: false)
            end
          end
        end

        describe 'with an empty Array' do
          it 'should clear the association value' do
            expect { entity.send("#{association.name}=", []) }
              .to change(proxy, :to_a)
              .to be == []
          end

          it 'should clear the previous inverse', :aggregate_failures do
            reset_mocks!

            entity.send("#{association.name}=", nil)

            previous_value.each do |previous_item|
              expect(mock_association)
                .to have_received(:remove_value)
                .with(previous_item, entity, update_inverse: false)
            end
          end
        end

        describe 'with an Array with one item' do
          let(:new_value) do
            [Spec::Reference.new(id: 3, name: 'New Reference')]
          end

          def reset_mocks!
            super

            new_value.each do |item|
              allow(mock_association)
                .to receive(:get_value)
                .with(item)
                .and_return(current_inverse)
            end
          end

          it 'should set the association value', :aggregate_failures do
            expect { entity.send("#{association.name}=", new_value) }
              .to change(proxy, :count)
              .to(new_value.size)

            expect(proxy.to_a).to be == new_value
          end

          it 'should clear the previous inverse', :aggregate_failures do
            reset_mocks!

            entity.send("#{association.name}=", nil)

            previous_value.each do |previous_item|
              expect(mock_association)
                .to have_received(:remove_value)
                .with(previous_item, entity, update_inverse: false)
            end
          end

          it 'should clear the current inverse' do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(new_value.first, current_inverse, update_inverse: true)
          end

          it 'should set the inverse association' do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value.first, entity, update_inverse: false)
          end
        end

        describe 'with an Array with many items' do
          let(:new_value) do
            [
              Spec::Reference.new(id: 3, name: 'New Reference 0'),
              Spec::Reference.new(id: 4, name: 'New Reference 1'),
              Spec::Reference.new(id: 5, name: 'New Reference 2')
            ]
          end

          def reset_mocks!
            super

            new_value.each do |item|
              allow(mock_association)
                .to receive(:get_value)
                .with(item)
                .and_return(current_inverse)
            end
          end

          it 'should set the association value', :aggregate_failures do
            expect { entity.send("#{association.name}=", new_value) }
              .not_to change(proxy, :count)

            expect(proxy.to_a).to be == new_value
          end

          it 'should clear the previous inverse', :aggregate_failures do
            reset_mocks!

            entity.send("#{association.name}=", nil)

            previous_value.each do |previous_item|
              expect(mock_association)
                .to have_received(:remove_value)
                .with(previous_item, entity, update_inverse: false)
            end
          end

          it 'should clear the current inverse', :aggregate_failures do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            new_value.each do |new_item|
              expect(mock_association)
                .to have_received(:remove_value)
                .with(new_item, current_inverse, update_inverse: true)
            end
          end

          it 'should set the inverse association', :aggregate_failures do
            reset_mocks!

            entity.send("#{association.name}=", new_value)

            new_value.each do |new_item|
              expect(mock_association)
                .to have_received(:add_value)
                .with(new_item, entity, update_inverse: false)
            end
          end
        end
      end
    end
  end

  describe '#add_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }
    let(:proxy)   { association.get_value(entity) }

    describe 'with nil' do
      it 'should not change the association value' do
        expect { association.add_value(entity, nil) }
          .not_to change(proxy, :to_a)
      end
    end

    describe 'with a value' do
      let(:new_value) { Spec::Reference.new(id: 3, name: 'New Reference') }

      it 'should add the item to the association value', :aggregate_failures do
        expect { association.add_value(entity, new_value) }
          .to change(proxy, :count)
          .by(1)

        expect(proxy.to_a.last).to be new_value
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.add_value(entity, nil) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with an existing value' do
        let(:existing_value) { previous_value[1] }

        it 'should not change the association value' do
          expect { association.add_value(entity, existing_value) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with a new value' do
        let(:new_value) { Spec::Reference.new(id: 3, name: 'New Reference') }

        it 'should add the item to the association value',
          :aggregate_failures \
        do
          expect { association.add_value(entity, new_value) }
            .to change(proxy, :count)
            .by(1)

          expect(proxy.to_a.last).to be new_value
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { nil }
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
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.add_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a value' do
        let(:new_value) { Spec::Reference.new(id: 3, name: 'New Reference') }

        it 'should add the item to the association value',
          :aggregate_failures \
        do
          expect { association.add_value(entity, new_value) }
            .to change(proxy, :count)
            .by(1)

          expect(proxy.to_a.last).to be new_value
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
          it 'should not change the association value' do
            reset_mocks!

            expect { association.add_value(entity, nil) }
              .not_to change(proxy, :to_a)
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.add_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with an existing value' do
          let(:existing_value) { previous_value[1] }

          it 'should not change the association value' do
            expect { association.add_value(entity, existing_value) }
              .not_to change(proxy, :to_a)
          end

          it 'should set the inverse association' do
            reset_mocks!

            association.add_value(entity, existing_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(existing_value, entity, update_inverse: false)
          end

          context 'when the existing value has a non-matching inverse' do # rubocop:disable RSpec/NestedGroups
            let(:previous_inverse) { Spec::EntityClass.new }

            it 'should not change the association value' do
              expect { association.add_value(entity, existing_value) }
                .not_to change(proxy, :to_a)
            end

            it 'should set the inverse association' do
              reset_mocks!

              association.add_value(entity, existing_value)

              expect(mock_association)
                .to have_received(:add_value)
                .with(existing_value, entity, update_inverse: false)
            end

            describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
              def add_value
                association.add_value(
                  entity,
                  existing_value,
                  update_inverse: false
                )
              end

              it 'should not update the inverse association',
                :aggregate_failures \
              do
                reset_mocks!

                add_value

                expect(mock_association).not_to have_received(:add_value)
                expect(mock_association).not_to have_received(:remove_value)
              end
            end
          end

          context 'when the existing value has a matching inverse' do # rubocop:disable RSpec/NestedGroups
            let(:previous_inverse) { entity }

            it 'should not change the association value' do
              expect { association.add_value(entity, existing_value) }
                .not_to change(proxy, :to_a)
            end

            it 'should not update the inverse association',
              :aggregate_failures \
            do
              reset_mocks!

              association.add_value(entity, existing_value)

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end

        describe 'with a new value' do
          let(:new_value) { Spec::Reference.new(id: 3, name: 'New Reference') }

          it 'should add the item to the association value',
            :aggregate_failures \
          do
            expect { association.add_value(entity, new_value) }
              .to change(proxy, :count)
              .by(1)

            expect(proxy.to_a.last).to be new_value
          end

          it 'should set the inverse association' do
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

            it 'should not update the inverse association',
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
    let(:proxy)   { association.get_value(entity) }

    it 'should not change the association value' do
      expect { association.clear_value(entity) }
        .not_to change(proxy, :to_a)
    end

    wrap_context 'when the association has a value' do
      it 'should clear the association value' do
        expect { association.clear_value(entity) }
          .to change(proxy, :to_a)
          .to be == []
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { nil }
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

      it 'should not change the association value' do
        expect { association.clear_value(entity) }
          .not_to change(proxy, :to_a)
      end

      it 'should not update the inverse associations', :aggregate_failures do
        reset_mocks!

        association.clear_value(entity)

        expect(mock_association).not_to have_received(:add_value)
        expect(mock_association).not_to have_received(:remove_value)
      end

      wrap_context 'when the association has a value' do
        let(:previous_inverse) { entity }

        it 'should clear the association value' do
          expect { association.clear_value(entity) }
            .to change(proxy, :to_a)
            .to be == []
        end

        it 'should update the inverse associations', :aggregate_failures do
          reset_mocks!

          association.clear_value(entity)

          previous_value.each do |previous_item|
            expect(mock_association)
              .to have_received(:remove_value)
              .with(previous_item, entity, update_inverse: false)
          end
        end

        describe 'with update_inverse: false' do
          it 'should not update the inverse associations',
            :aggregate_failures \
          do
            reset_mocks!

            association.clear_value(entity, update_inverse: false)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end
      end
    end
  end

  describe '#get_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }
    let(:proxy)   { association.get_value(entity) }

    it { expect(proxy).to be_a described_class::Proxy }

    it { expect(proxy.to_a).to be == [] }

    wrap_context 'when the association has a value' do
      it { expect(proxy.to_a).to be == previous_value }
    end
  end

  describe '#many?' do
    it { expect(association.many?).to be true }
  end

  describe '#one?' do
    it { expect(association.one?).to be false }
  end

  describe '#remove_value' do
    include_context 'with an entity'

    let(:options) { super().merge(inverse: false) }
    let(:proxy)   { association.get_value(entity) }

    describe 'with nil' do
      it 'should not change the association value' do
        expect { association.remove_value(entity, nil) }
          .not_to change(proxy, :to_a)
      end
    end

    describe 'with a non-matching value' do
      let(:value) { Spec::Reference.new(name: 'Other Reference') }

      it 'should not change the association value' do
        expect { association.remove_value(entity, value) }
          .not_to change(proxy, :to_a)
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.remove_value(entity, nil) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with a non-matching value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with a matching value' do
        let(:value) { previous_value[1] }

        it 'should remove the item from the association value',
          :aggregate_failures \
        do
          expect { association.remove_value(entity, value) }
            .to change(proxy, :count)
            .by(-1)

          expect(proxy.to_a).not_to include value
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { nil }
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
          expect { association.remove_value(entity, nil) }
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          reset_mocks!

          association.remove_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with a non-matching value' do
        let(:value) { Spec::Reference.new(name: 'Other Reference') }

        it 'should not change the association value' do
          expect { association.remove_value(entity, value) }
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          reset_mocks!

          association.remove_value(entity, value)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should not change the association value' do
            expect { association.remove_value(entity, nil) }
              .not_to change(proxy, :to_a)
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.remove_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with a non-matching value' do
          let(:value) { Spec::Reference.new(name: 'Other Reference') }

          it 'should not change the association value' do
            expect { association.remove_value(entity, value) }
              .not_to change(proxy, :to_a)
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.remove_value(entity, value)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with a matching value' do
          let(:previous_inverse) { entity }
          let(:value)            { previous_value[1] }

          it 'should remove the item from the association value',
            :aggregate_failures \
          do
            expect { association.remove_value(entity, value) }
              .to change(proxy, :count)
              .by(-1)

            expect(proxy.to_a).not_to include value
          end

          it 'should update the inverse association' do
            reset_mocks!

            association.remove_value(entity, value)

            expect(mock_association)
              .to have_received(:remove_value)
              .with(value, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            def remove_value
              association.remove_value(
                entity,
                value,
                update_inverse: false
              )
            end

            it 'should not update the inverse association',
              :aggregate_failures \
            do
              reset_mocks!

              remove_value

              expect(mock_association).not_to have_received(:add_value)
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
    let(:proxy)   { association.get_value(entity) }

    describe 'with nil' do
      it 'should not change the association value' do
        expect { association.set_value(entity, nil) }
          .not_to change(proxy, :to_a)
      end
    end

    describe 'with an empty Array' do
      it 'should not change the association value' do
        expect { association.set_value(entity, []) }
          .not_to change(proxy, :to_a)
      end
    end

    describe 'with an Array with one non-matching item' do
      let(:new_value) { [Spec::Reference.new(id: 3, name: 'New Reference')] }

      it 'should set the association value', :aggregate_failures do
        expect { association.set_value(entity, new_value) }
          .to change(proxy, :count)
          .by(new_value.size)

        expect(proxy.to_a[-new_value.size..]).to be == new_value
      end
    end

    describe 'with an Array with many items' do
      let(:new_value) do
        [
          Spec::Reference.new(id: 3, name: 'New Reference 0'),
          Spec::Reference.new(id: 4, name: 'New Reference 1'),
          Spec::Reference.new(id: 5, name: 'New Reference 2')
        ]
      end

      it 'should set the association value', :aggregate_failures do
        expect { association.set_value(entity, new_value) }
          .to change(proxy, :count)
          .by(new_value.size)

        expect(proxy.to_a[-new_value.size..]).to be == new_value
      end
    end

    wrap_context 'when the association has a value' do
      describe 'with nil' do
        it 'should not change the association value' do
          expect { association.set_value(entity, nil) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with an empty Array' do
        it 'should not change the association value' do
          expect { association.set_value(entity, []) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with an Array with one non-matching item' do
        let(:new_value) { [Spec::Reference.new(id: 3, name: 'New Reference')] }

        it 'should set the association value', :aggregate_failures do
          expect { association.set_value(entity, new_value) }
            .to change(proxy, :count)
            .by(new_value.size)

          expect(proxy.to_a[-new_value.size..]).to be == new_value
        end
      end

      describe 'with an Array with one matching item' do
        let(:new_value) { previous_value[1..1] }

        it 'should not change the association value' do
          expect { association.set_value(entity, []) }
            .not_to change(proxy, :to_a)
        end
      end

      describe 'with an Array with many items' do
        let(:new_value) do
          [
            Spec::Reference.new(id: 3, name: 'New Reference 0'),
            Spec::Reference.new(id: 4, name: 'New Reference 1'),
            Spec::Reference.new(id: 5, name: 'New Reference 2')
          ]
        end

        it 'should set the association value', :aggregate_failures do
          expect { association.set_value(entity, new_value) }
            .to change(proxy, :count)
            .by(new_value.size)

          expect(proxy.to_a[-new_value.size..]).to be == new_value
        end
      end
    end

    context 'when the association has an inverse' do
      let(:previous_inverse) { nil }
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
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.set_value(entity, nil)

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with an empty Array' do
        it 'should not change the association value' do
          expect { association.set_value(entity, []) }
            .not_to change(proxy, :to_a)
        end

        it 'should not update the inverse association', :aggregate_failures do
          association.set_value(entity, [])

          expect(mock_association).not_to have_received(:add_value)
          expect(mock_association).not_to have_received(:remove_value)
        end
      end

      describe 'with an Array with one non-matching item' do
        let(:new_value) { [Spec::Reference.new(id: 3, name: 'New Reference')] }

        it 'should set the association value', :aggregate_failures do
          expect { association.set_value(entity, new_value) }
            .to change(proxy, :count)
            .by(new_value.size)

          expect(proxy.to_a[-new_value.size..]).to be == new_value
        end

        it 'should set the inverse association' do
          association.set_value(entity, new_value)

          expect(mock_association)
            .to have_received(:add_value)
            .with(new_value.first, entity, update_inverse: false)
        end

        describe 'with update_inverse: false' do
          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, new_value, update_inverse: false)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end
      end

      describe 'with an Array with many items' do
        let(:new_value) do
          [
            Spec::Reference.new(id: 3, name: 'New Reference 0'),
            Spec::Reference.new(id: 4, name: 'New Reference 1'),
            Spec::Reference.new(id: 5, name: 'New Reference 2')
          ]
        end

        it 'should set the association value', :aggregate_failures do
          expect { association.set_value(entity, new_value) }
            .to change(proxy, :count)
            .by(new_value.size)

          expect(proxy.to_a[-new_value.size..]).to be == new_value
        end

        it 'should set the inverse associations', :aggregate_failures do
          reset_mocks!

          association.set_value(entity, new_value)

          new_value.each do |new_item|
            expect(mock_association)
              .to have_received(:add_value)
              .with(new_item, entity, update_inverse: false)
          end
        end

        describe 'with update_inverse: false' do
          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, new_value, update_inverse: false)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end
      end

      wrap_context 'when the association has a value' do
        describe 'with nil' do
          it 'should not change the association value' do
            expect { association.set_value(entity, nil) }
              .not_to change(proxy, :to_a)
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, nil)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with an empty Array' do
          it 'should not change the association value' do
            expect { association.set_value(entity, []) }
              .not_to change(proxy, :to_a)
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, [])

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with an Array with one non-matching item' do
          let(:new_value) do
            [Spec::Reference.new(id: 3, name: 'New Reference')]
          end

          it 'should set the association value', :aggregate_failures do
            expect { association.set_value(entity, new_value) }
              .to change(proxy, :count)
              .by(new_value.size)

            expect(proxy.to_a[-new_value.size..]).to be == new_value
          end

          it 'should set the inverse association' do
            reset_mocks!

            association.set_value(entity, new_value)

            expect(mock_association)
              .to have_received(:add_value)
              .with(new_value.first, entity, update_inverse: false)
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            it 'should not update the inverse association',
              :aggregate_failures \
            do
              reset_mocks!

              association.set_value(entity, new_value, update_inverse: false)

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end

        describe 'with an Array with one matching item' do
          let(:new_value)        { previous_value[1..1] }
          let(:previous_inverse) { entity }

          it 'should not change the association value' do
            expect { association.set_value(entity, new_value) }
              .not_to change(proxy, :to_a)
          end

          it 'should not update the inverse association', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, new_value)

            expect(mock_association).not_to have_received(:add_value)
            expect(mock_association).not_to have_received(:remove_value)
          end
        end

        describe 'with an Array with many items' do
          let(:new_value) do
            [
              Spec::Reference.new(id: 3, name: 'New Reference 0'),
              Spec::Reference.new(id: 4, name: 'New Reference 1'),
              Spec::Reference.new(id: 5, name: 'New Reference 2')
            ]
          end

          it 'should set the association value', :aggregate_failures do
            expect { association.set_value(entity, new_value) }
              .to change(proxy, :count)
              .by(new_value.size)

            expect(proxy.to_a[-new_value.size..]).to be == new_value
          end

          it 'should set the inverse associations', :aggregate_failures do
            reset_mocks!

            association.set_value(entity, new_value)

            new_value.each do |new_item|
              expect(mock_association)
                .to have_received(:add_value)
                .with(new_item, entity, update_inverse: false)
            end
          end

          describe 'with update_inverse: false' do # rubocop:disable RSpec/NestedGroups
            it 'should not update the inverse association',
              :aggregate_failures \
            do
              reset_mocks!

              association.set_value(entity, new_value, update_inverse: false)

              expect(mock_association).not_to have_received(:add_value)
              expect(mock_association).not_to have_received(:remove_value)
            end
          end
        end
      end
    end
  end
end
