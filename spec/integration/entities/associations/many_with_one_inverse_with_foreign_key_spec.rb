# frozen_string_literal: true

require 'stannum/entity'

# @note Integration spec for Stannum::Entities::Associations.
#   - Tests a :many association with inverse :one association with foreign key.
RSpec.describe Stannum::Associations::Many do
  subject(:entity) { described_class.new(**attributes, **associations) }

  shared_context 'when the entity has an association' do
    let(:monsters) do
      [
        Spec::Monster.new(challenge: 1, name: 'Goblin'),
        Spec::Monster.new(challenge: 1, name: 'Goblin Guard'),
        Spec::Monster.new(challenge: 2, name: 'Pet Wolf')
      ]
    end
    let(:associations) { super().merge(monsters:) }

    # Ensure associations are populated before examples.
    before(:example) { entity }
  end

  shared_examples 'should not change the association' do
    it 'should not change the association' do
      expect { update_association }.not_to(change { entity.monsters.to_a })
    end

    it 'should not change the inverse associations' do
      expect { update_association }.not_to(
        change { entity.monsters.map(&:dungeon) }
      )
    end

    it 'should not change the inverse foreign keys' do
      expect { update_association }.not_to(
        change { entity.monsters.map(&:dungeon_id) }
      )
    end
  end

  shared_examples 'should clear the association' do
    it 'should clear the association' do
      expect { update_association }
        .to(change { entity.monsters.to_a }.to be == [])
    end

    it 'should clear the previous inverse associations' do
      next unless defined?(monsters)

      expect { update_association }.to(
        change { monsters.map(&:dungeon) }
          .to be == Array.new(monsters.size)
      )
    end

    it 'should clear the previous inverse foreign keys' do
      next unless defined?(monsters)

      expect { update_association }.to(
        change { monsters.map(&:dungeon_id) }
          .to be == Array.new(monsters.size)
      )
    end
  end

  shared_examples 'should update the association' do
    it 'should update the association' do
      expect { update_association }
        .to(change { entity.monsters.to_a }.to be == new_monsters)
    end

    it 'should clear the previous inverse associations' do
      next unless defined?(monsters)

      expect { update_association }.to(
        change { monsters.map(&:dungeon) }
          .to be == Array.new(monsters.size)
      )
    end

    it 'should clear the previous inverse foreign keys' do
      next unless defined?(monsters)

      expect { update_association }.to(
        change { monsters.map(&:dungeon_id) }
          .to be == Array.new(monsters.size)
      )
    end

    it 'should clear the previous inverse of the new inverse association' do
      expect { update_association }.to(
        change { new_monsters_dungeon.monsters.to_a }
          .to be == []
      )
    end

    it 'should set the new inverse associations' do
      expect { update_association }.to(
        change { new_monsters.map(&:dungeon) }
          .to be == Array.new(new_monsters.size) { entity }
      )
    end

    it 'should set the new inverse foreign keys' do
      expect { update_association }.to(
        change { new_monsters.map(&:dungeon_id) }
          .to be == Array.new(new_monsters.size) { entity.id }
      )
    end
  end

  shared_examples 'should add the value to the association' do
    it 'should add the value to the association', :aggregate_failures do
      expect { update_association }.to(change { entity.monsters.count }.by(1))

      expect(entity.monsters.to_a.last).to be == new_monster
    end

    it 'should clear the previous inverse of the new inverse association',
      :aggregate_failures \
    do
      expect { update_association }.to(
        change { new_monsters_dungeon.monsters.count }
        .by(-1)
      )

      expect(new_monsters_dungeon.monsters).not_to include(new_monster)
    end

    it 'should set the new inverse association' do
      expect { update_association }
        .to change(new_monster, :dungeon).to be entity
    end

    it 'should set the new inverse foreign key' do
      expect { update_association }
        .to change(new_monster, :dungeon_id).to be entity.id
    end
  end

  shared_examples 'should remove the value from the association' do
    it 'should remove the value from the association', :aggregate_failures do
      expect { update_association }.to(change { entity.monsters.count }.by(-1))

      expect(entity.monsters.to_a).not_to include monster
    end

    it 'should clear the previous inverse association' do
      expect { update_association }.to change(monster, :dungeon).to be nil
    end

    it 'should clear the previous inverse foreign key' do
      expect { update_association }.to change(monster, :dungeon_id).to be nil
    end
  end

  let(:described_class) { Spec::Dungeon }
  let(:attributes) do
    { id: 0, location: 'Swamp Of Peril', name: 'Goblin Camp' }
  end
  let(:associations) { {} }
  let(:new_monsters_dungeon) do
    Spec::Dungeon.new(
      id:       1,
      location: 'The Forbidden Peaks',
      name:     'The Dire Tower'
    )
  end
  let(:new_monsters) do
    [
      Spec::Monster.new(
        challenge: 3,
        name:      'Big Goblin',
        dungeon:   new_monsters_dungeon
      ),
      Spec::Monster.new(
        challenge: 2,
        name:      'Goblin Archer',
        dungeon:   new_monsters_dungeon
      ),
      Spec::Monster.new(
        challenge: 2,
        name:      'Goblin Warrior',
        dungeon:   new_monsters_dungeon
      )
    ]
  end

  # Ensure associations are populated before examples.
  before(:example) { new_monsters }

  example_class 'Spec::Dungeon' do |klass|
    klass.include Stannum::Entity

    klass.define_primary_key :id, Integer

    klass.attribute :name, String

    klass.attribute :location, String

    klass.association :many,
      :monsters,
      class_name: 'Spec::Monster'
  end

  example_class 'Spec::Monster' do |klass|
    klass.include Stannum::Entity

    klass.attribute :challenge, Integer

    klass.attribute :name, String

    klass.association :one,
      :dungeon,
      class_name:  'Spec::Dungeon',
      foreign_key: true
  end

  describe '#assign_associations' do
    def update_association
      entity.assign_associations(value)
    end

    describe 'with monsters: nil' do
      let(:value) { { monsters: nil } }

      it 'should not change the associations' do
        expect { entity.assign_associations(value) }
          .not_to change(entity, :associations)
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: an empty Array' do
      let(:value) { { monsters: [] } }

      it 'should not change the associations' do
        expect { entity.assign_associations(value) }
          .not_to change(entity, :associations)
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: value' do
      let(:value)    { { monsters: new_monsters } }
      let(:expected) { { 'monsters' => new_monsters } }

      it 'should update the associations' do
        expect { entity.assign_associations(value) }
          .to change(entity, :associations)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with monsters: nil' do
        let(:value) { { monsters: nil } }

        it 'should update the associations' do
          expect { entity.assign_associations(value) }
            .to change(entity, :associations)
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: an empty Array' do
        let(:value) { { monsters: [] } }

        it 'should update the associations' do
          expect { entity.assign_associations(value) }
            .to change(entity, :associations)
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: value' do
        let(:value)    { { monsters: new_monsters } }
        let(:expected) { { 'monsters' => new_monsters } }

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

    describe 'with monsters: nil' do
      let(:value) { { monsters: nil } }

      it 'should not change the properties' do
        expect { entity.assign_properties(value) }
          .not_to change(entity, :properties)
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: an empty Array' do
      let(:value) { { monsters: [] } }

      it 'should not change the properties' do
        expect { entity.assign_properties(value) }
          .not_to change(entity, :properties)
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: value' do
      let(:value) { { monsters: new_monsters } }
      let(:expected) do
        {
          'id'       => 0,
          'location' => 'Swamp Of Peril',
          'name'     => 'Goblin Camp',
          'monsters' => new_monsters
        }
      end

      it 'should update the properties' do
        expect { entity.assign_properties(value) }
          .to change(entity, :properties)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with monsters: nil' do
        let(:value) { { monsters: nil } }
        let(:expected) do
          {
            'id'       => 0,
            'location' => 'Swamp Of Peril',
            'name'     => 'Goblin Camp',
            'monsters' => []
          }
        end

        it 'should update the properties' do
          expect { entity.assign_properties(value) }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: an empty Array' do
        let(:value) { { monsters: [] } }
        let(:expected) do
          {
            'id'       => 0,
            'location' => 'Swamp Of Peril',
            'name'     => 'Goblin Camp',
            'monsters' => []
          }
        end

        it 'should update the properties' do
          expect { entity.assign_properties(value) }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: value' do
        let(:value) { { monsters: new_monsters } }
        let(:expected) do
          {
            'id'       => 0,
            'location' => 'Swamp Of Peril',
            'name'     => 'Goblin Camp',
            'monsters' => new_monsters
          }
        end

        it 'should update the properties' do
          expect { entity.assign_properties(value) }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should update the association'
      end
    end
  end

  describe '#associations' do
    let(:expected) { { 'monsters' => [] } }

    it { expect(entity.associations).to be == expected }

    wrap_context 'when the entity has an association' do
      let(:expected) { super().merge('monsters' => monsters) }

      it { expect(entity.associations).to be == expected }
    end
  end

  describe '#associations=' do
    def update_association
      entity.associations = value
    end

    describe 'with monsters: nil' do
      let(:value) { { monsters: nil } }

      it 'should not change the associations' do
        expect { entity.associations = value }
          .not_to change(entity, :associations)
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: an empty Array' do
      let(:value) { { monsters: [] } }

      it 'should not change the associations' do
        expect { entity.associations = value }
          .not_to change(entity, :associations)
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: value' do
      let(:value)    { { monsters: new_monsters } }
      let(:expected) { { 'monsters' => new_monsters } }

      it 'should update the associations' do
        expect { entity.associations = value }
          .to change(entity, :associations)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with monsters: nil' do
        let(:value) { { monsters: nil } }

        it 'should update the associations' do
          expect { entity.associations = value }
            .to change(entity, :associations)
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: an empty Array' do
        let(:value) { { monsters: [] } }

        it 'should update the associations' do
          expect { entity.associations = value }
            .to change(entity, :associations)
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: value' do
        let(:value)    { { monsters: new_monsters } }
        let(:expected) { { 'monsters' => new_monsters } }

        it 'should update the associations' do
          expect { entity.associations = value }
            .to change(entity, :associations)
            .to be == expected
        end

        include_examples 'should update the association'
      end
    end
  end

  describe '#monsters' do
    it { expect(entity.monsters).to be == [] }

    wrap_context 'when the entity has an association' do
      it { expect(entity.monsters).to be == monsters }
    end
  end

  describe '#monsters.add' do
    let(:new_monster) do
      Spec::Monster.new(
        challenge: 1,
        name:      'Slime',
        dungeon:   new_monsters_dungeon
      )
    end

    def update_association
      entity.monsters.add(new_monster)
    end

    # Ensure associations are populated before examples.
    before(:example) { new_monster }

    describe 'with a value' do
      include_examples 'should add the value to the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with a value' do
        include_examples 'should add the value to the association'
      end
    end
  end

  describe '#monsters.remove' do
    def update_association
      entity.monsters.remove(monster)
    end

    describe 'with a value not in the association' do
      let(:monster) { Spec::Monster.new(challenge: 1, name: 'Slime') }

      include_examples 'should not change the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with a value not in the association' do
        let(:monster) { Spec::Monster.new(challenge: 1, name: 'Slime') }

        include_examples 'should not change the association'
      end

      describe 'with a value in the association' do
        let(:monster) { monsters[1] }

        include_examples 'should remove the value from the association'
      end
    end
  end

  describe '#monsters=' do
    def update_association
      entity.monsters = new_monsters
    end

    describe 'with nil' do
      let(:new_monsters) { nil }

      include_examples 'should not change the association'
    end

    describe 'with an empty Array' do
      let(:new_monsters) { [] }

      include_examples 'should not change the association'
    end

    describe 'with a value' do
      let(:value)    { { monsters: new_monsters } }
      let(:expected) { { 'monsters' => new_monsters } }

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with nil' do
        let(:new_monsters) { nil }

        include_examples 'should clear the association'
      end

      describe 'with an empty Array' do
        let(:new_monsters) { [] }

        include_examples 'should clear the association'
      end

      describe 'with a value' do
        let(:value)    { { monsters: new_monsters } }
        let(:expected) { { 'monsters' => new_monsters } }

        include_examples 'should update the association'
      end
    end
  end

  describe '#properties' do
    let(:expected) do
      {
        'id'       => 0,
        'location' => 'Swamp Of Peril',
        'name'     => 'Goblin Camp',
        'monsters' => []
      }
    end

    it { expect(entity.properties).to be == expected }

    wrap_context 'when the entity has an association' do
      let(:expected) { super().merge('monsters' => monsters) }

      it { expect(entity.properties).to be == expected }
    end
  end

  describe '#properties=' do
    let(:value) { { id: entity.id, monsters: new_monsters } }
    let(:expected) do
      {
        'id'       => 0,
        'location' => nil,
        'name'     => nil,
        'monsters' => new_monsters || []
      }
    end

    def update_association
      entity.properties = value
    end

    describe 'with monsters: nil' do
      let(:new_monsters) { nil }

      it 'should update the properties' do
        expect { entity.properties = value }
          .to change(entity, :properties)
          .to be == expected
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: an empty Array' do
      let(:new_monsters) { [] }

      it 'should update the properties' do
        expect { entity.properties = value }
          .to change(entity, :properties)
          .to be == expected
      end

      include_examples 'should not change the association'
    end

    describe 'with monsters: value' do
      it 'should update the properties' do
        expect { entity.properties = value }
          .to change(entity, :properties)
          .to be == expected
      end

      include_examples 'should update the association'
    end

    wrap_context 'when the entity has an association' do
      describe 'with monsters: nil' do
        let(:new_monsters) { nil }

        it 'should update the properties' do
          expect { entity.properties = value }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: an empty Array' do
        let(:new_monsters) { [] }

        it 'should update the properties' do
          expect { entity.properties = value }
            .to change(entity, :properties)
            .to be == expected
        end

        include_examples 'should clear the association'
      end

      describe 'with monsters: value' do
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
