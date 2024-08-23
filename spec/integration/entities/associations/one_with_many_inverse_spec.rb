# frozen_string_literal: true

require 'stannum/entity'

# @note Integration spec for Stannum::Entities::Associations.
#   - Tests a :one association with inverse :many association.
RSpec.describe Stannum::Associations::One do
  subject(:entity) { described_class.new(**attributes, **associations) }

  shared_context 'when the entity has an association' do
    let(:dungeon)      { Spec::Dungeon.new(id: 0, name: 'Goblin Camp') }
    let(:associations) { super().merge(dungeon:) }

    # Ensure associations are populated before examples.
    before(:example) { entity }
  end

  shared_examples 'should not change the association' do
    it 'should not change the association' do
      expect { update_association }.not_to change(entity, :dungeon)
    end

    it 'should not change the inverse association' do
      expect { update_association }
        .not_to(change { entity.dungeon&.monsters&.to_a })
    end
  end

  shared_examples 'should clear the association' do
    it 'should clear the association' do
      expect { update_association }
        .to change(entity, :dungeon)
        .to be nil
    end

    it 'should clear the previous inverse association' do
      next unless defined?(dungeon)

      expect { update_association }
        .to(
          change { dungeon.monsters.to_a }.to(
            satisfy { |proxy| !proxy.include?(entity) }
          )
        )
    end
  end

  shared_examples 'should update the association' do
    it 'should update the association' do
      expect { update_association }
        .to change(entity, :dungeon)
        .to be == new_dungeon
    end

    it 'should clear the previous inverse association' do
      next unless defined?(dungeon)

      expect { update_association }
        .to(
          change { dungeon.monsters.to_a }.to(
            satisfy { |proxy| !proxy.include?(entity) }
          )
        )
    end

    it 'should set the new inverse association' do
      expect { update_association }
        .to(
          change { new_dungeon.monsters.to_a }
          .to include(entity)
        )
    end
  end

  let(:described_class) { Spec::Monster }
  let(:attributes)      { { challenge: 1, name: 'Goblin' } }
  let(:associations)    { {} }
  let(:new_dungeon_monsters) do
    [
      Spec::Monster.new(challenge: 3, name: 'Big Goblin'),
      Spec::Monster.new(challenge: 2, name: 'Goblin Archer'),
      Spec::Monster.new(challenge: 2, name: 'Goblin Warrior')
    ]
  end
  let(:new_dungeon) do
    Spec::Dungeon.new(
      id:       1,
      name:     'Dread Necropolis',
      monsters: new_dungeon_monsters
    )
  end

  # Ensure associations are populated before examples.
  before(:example) { new_dungeon }

  example_class 'Spec::Dungeon' do |klass|
    klass.include Stannum::Entity

    klass.define_primary_key :id, Integer

    klass.attribute :name, String

    klass.association :many, :monsters, class_name: 'Spec::Monster'
  end

  example_class 'Spec::Monster' do |klass|
    klass.include Stannum::Entity

    klass.attribute :challenge, Integer

    klass.attribute :name, String

    klass.association :one,
      :dungeon,
      class_name: 'Spec::Dungeon'
  end

  describe '#assign_associations' do
    def update_association
      entity.assign_associations(value)
    end

    describe 'with dungeon: nil' do
      let(:value) { { dungeon: nil } }

      it 'should not change the associations' do
        expect { entity.assign_associations(value) }
          .not_to change(entity, :associations)
      end

      include_examples 'should not change the association'
    end

    describe 'with dungeon: value' do
      let(:value)    { { dungeon: new_dungeon } }
      let(:expected) { { 'dungeon' => new_dungeon } }

      it 'should update the associations' do
        expect { entity.assign_associations(value) }
          .to change(entity, :associations)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with dungeon: nil' do
        let(:value)    { { dungeon: nil } }
        let(:expected) { { 'dungeon' => nil } }

        it 'should update the associations' do
          expect { entity.assign_associations(value) }
            .to change(entity, :associations)
        end

        include_examples 'should clear the association'
      end

      describe 'with dungeon: value' do
        let(:value)    { { dungeon: new_dungeon } }
        let(:expected) { { 'dungeon' => new_dungeon } }

        it 'should update the associations' do
          expect { entity.assign_associations(value) }
            .to change(entity, :associations)
            .to be == expected
        end

        include_examples 'should update the association'
      end
    end
  end

  describe '#assign_properties' do
    def update_association
      entity.assign_properties(value)
    end

    describe 'with dungeon: nil' do
      let(:value) { { dungeon: nil } }

      it 'should not change the properties' do
        expect { entity.assign_properties(value) }
          .not_to change(entity, :properties)
      end

      include_examples 'should not change the association'
    end

    describe 'with dungeon: value' do
      let(:value) { { dungeon: new_dungeon } }
      let(:expected) do
        {
          'challenge' => 1,
          'name'      => 'Goblin',
          'dungeon'   => new_dungeon
        }
      end

      include_examples 'should update the association'

      it 'should update the properties' do
        expect { entity.assign_properties(value) }
          .to change(entity, :properties)
          .to be == expected
      end
    end

    wrap_context 'when the entity has an association' do
      describe 'with dungeon: nil' do
        let(:value) { { dungeon: nil } }
        let(:expected) do
          {
            'challenge' => 1,
            'name'      => 'Goblin',
            'dungeon'   => nil
          }
        end

        it 'should update the properties' do
          expect { entity.assign_properties(value) }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with dungeon: value' do
        let(:value) { { dungeon: new_dungeon } }
        let(:expected) do
          {
            'challenge' => 1,
            'name'      => 'Goblin',
            'dungeon'   => new_dungeon
          }
        end

        include_examples 'should update the association'

        it 'should update the properties' do
          expect { entity.assign_properties(value) }
            .to change(entity, :properties)
            .to be == expected
        end
      end
    end
  end

  describe '#associations' do
    let(:expected) { { 'dungeon' => nil } }

    it { expect(entity.associations).to be == expected }

    wrap_context 'when the entity has an association' do
      let(:expected) { super().merge('dungeon' => dungeon) }

      it { expect(entity.associations).to be == expected }
    end
  end

  describe '#associations=' do
    def update_association
      entity.associations = value
    end

    describe 'with dungeon: nil' do
      let(:value) { { dungeon: nil } }

      it 'should not change the associations' do
        expect { entity.associations = value }
          .not_to change(entity, :associations)
      end

      include_examples 'should not change the association'
    end

    describe 'with dungeon: value' do
      let(:value)    { { dungeon: new_dungeon } }
      let(:expected) { { 'dungeon' => new_dungeon } }

      it 'should update the associations' do
        expect { entity.associations = value }
          .to change(entity, :associations)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with dungeon: nil' do
        let(:value)    { { dungeon: nil } }
        let(:expected) { { 'dungeon' => nil } }

        it 'should update the associations' do
          expect { entity.associations = value }
            .to change(entity, :associations)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with dungeon: value' do
        let(:value)    { { dungeon: new_dungeon } }
        let(:expected) { { 'dungeon' => new_dungeon } }

        it 'should update the associations' do
          expect { entity.associations = value }
            .to change(entity, :associations)
            .to be == expected
        end

        include_examples 'should update the association'
      end
    end
  end

  describe '#dungeon' do
    it { expect(entity.dungeon).to be nil }

    wrap_context 'when the entity has an association' do
      it { expect(entity.dungeon).to be dungeon }
    end
  end

  describe '#dungeon=' do
    def update_association
      entity.dungeon = new_dungeon
    end

    describe 'with nil' do
      let(:new_dungeon) { nil }

      include_examples 'should not change the association'
    end

    describe 'with a value' do
      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with nil' do
        let(:new_dungeon) { nil }

        include_examples 'should clear the association'
      end

      describe 'with a value' do
        include_examples 'should update the association'
      end
    end
  end

  describe '#properties' do
    let(:expected) do
      {
        'challenge' => 1,
        'name'      => 'Goblin',
        'dungeon'   => nil
      }
    end

    it { expect(entity.properties).to be == expected }

    wrap_context 'when the entity has an association' do
      let(:expected) { super().merge('dungeon' => dungeon) }

      it { expect(entity.properties).to be == expected }
    end
  end

  describe '#properties=' do
    let(:value) { { dungeon: new_dungeon } }
    let(:expected) do
      {
        'challenge' => nil,
        'name'      => nil,
        'dungeon'   => new_dungeon
      }
    end

    def update_association
      entity.properties = value
    end

    describe 'with dungeon: nil' do
      let(:new_dungeon) { nil }

      it 'should update the properties' do
        expect { entity.properties = value }
          .to change(entity, :properties)
          .to be == expected
      end

      include_examples 'should not change the association'
    end

    describe 'with dungeon: value' do
      let(:expected) { super().merge('dungeon' => new_dungeon) }

      it 'should update the properties' do
        expect { entity.properties = value }
          .to change(entity, :properties)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with dungeon: nil' do
        let(:new_dungeon) { nil }

        it 'should update the properties' do
          expect { entity.properties = value }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with dungeon: value' do
        let(:expected) { super().merge('dungeon' => new_dungeon) }

        it 'should update the properties' do
          expect { entity.properties = value }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should update the association'
      end
    end
  end
end
