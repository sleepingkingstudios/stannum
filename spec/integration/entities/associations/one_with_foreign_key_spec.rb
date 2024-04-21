# frozen_string_literal: true

require 'stannum/entity'

# @note Integration spec for Stannum::Entities::Associations.
#   - Tests a :one association with foreign key but no inverse.
RSpec.describe Stannum::Associations::One do
  subject(:entity) { described_class.new(**attributes, **associations) }

  shared_context 'when the entity has an association' do
    let(:dungeon)      { Spec::Dungeon.new(id: 0, name: 'The Crypts') }
    let(:associations) { super().merge(dungeon: dungeon) }
  end

  let(:described_class) { Spec::Boss }
  let(:attributes)      { { challenge: 20, name: 'Lich Lord' } }
  let(:associations)    { {} }

  example_class 'Spec::Boss' do |klass|
    klass.include Stannum::Entity

    klass.association :one,
      :dungeon,
      class_name:  'Spec::Dungeon',
      foreign_key: true,
      inverse:     false

    klass.attribute :challenge, Integer

    klass.attribute :name, String
  end

  example_class 'Spec::Dungeon' do |klass|
    klass.include Stannum::Entity

    klass.define_primary_key :id, Integer

    klass.attribute :name, String
  end

  describe '#assign_associations' do
    let(:value) do
      { dungeon: Spec::Dungeon.new(id: 1, name: 'Dread Necropolis') }
    end
    let(:expected) { { 'dungeon' => value[:dungeon] } }

    it 'should update the associations' do
      expect { entity.assign_associations(value) }
        .to change(entity, :associations)
        .to be == expected
    end

    it 'should update the foreign key' do
      expect { entity.assign_associations(value) }
        .to change(entity, :dungeon_id)
        .to be == value[:dungeon].id
    end

    wrap_context 'when the entity has an association' do
      it 'should update the associations' do
        expect { entity.assign_associations(value) }
          .to change(entity, :associations)
          .to be == expected
      end

      it 'should update the foreign key' do
        expect { entity.assign_associations(value) }
          .to change(entity, :dungeon_id)
          .to be == value[:dungeon].id
      end
    end
  end

  describe '#assign_properties' do
    let(:value) do
      { dungeon: Spec::Dungeon.new(id: 1, name: 'Dread Necropolis') }
    end
    let(:expected) do
      {
        'challenge'  => 20,
        'name'       => 'Lich Lord',
        'dungeon'    => value[:dungeon],
        'dungeon_id' => value[:dungeon]&.id
      }
    end

    it 'should update the properties' do
      expect { entity.assign_properties(value) }
        .to change(entity, :properties)
        .to be == expected
    end

    wrap_context 'when the entity has an association' do
      it 'should update the properties' do
        expect { entity.assign_properties(value) }
          .to change(entity, :properties)
          .to be == expected
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
    let(:value) do
      { dungeon: Spec::Dungeon.new(id: 1, name: 'Dread Necropolis') }
    end
    let(:expected) { { 'dungeon' => value[:dungeon] } }

    it 'should update the associations' do
      expect { entity.associations = value }
        .to change(entity, :associations)
        .to be == expected
    end

    it 'should update the foreign key' do
      expect { entity.associations = value }
        .to change(entity, :dungeon_id)
        .to be == value[:dungeon].id
    end

    wrap_context 'when the entity has an association' do
      it 'should update the associations' do
        expect { entity.associations = value }
          .to change(entity, :associations)
          .to be == expected
      end

      it 'should update the foreign key' do
        expect { entity.associations = value }
          .to change(entity, :dungeon_id)
          .to be == value[:dungeon].id
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
    describe 'with a value' do
      let(:value) { Spec::Dungeon.new(id: 1, name: 'Dread Necropolis') }

      it 'should set the association' do
        expect { entity.dungeon = value }
          .to change(entity, :dungeon)
          .to be value
      end

      it 'should set the foreign key' do
        expect { entity.dungeon = value }
          .to change(entity, :dungeon_id)
          .to be value.id
      end
    end

    wrap_context 'when the entity has an association' do
      describe 'with nil' do
        it 'should clear the association' do
          expect { entity.dungeon = nil }
            .to change(entity, :dungeon)
            .to be nil
        end

        it 'should clear the foreign key' do
          expect { entity.dungeon = nil }
            .to change(entity, :dungeon_id)
            .to be nil
        end
      end

      describe 'with a value' do
        let(:value) { Spec::Dungeon.new(name: 'Dread Necropolis') }

        it 'should set the association' do
          expect { entity.dungeon = value }
            .to change(entity, :dungeon)
            .to be value
        end

        it 'should set the foreign key' do
          expect { entity.dungeon = value }
            .to change(entity, :dungeon_id)
            .to be value.id
        end
      end
    end
  end

  describe '#dungeon_id' do
    it { expect(entity.dungeon_id).to be nil }

    wrap_context 'when the entity has an association' do
      it { expect(entity.dungeon_id).to be dungeon.id }
    end
  end

  describe '#dungeon_id=' do
    describe 'with a value' do
      let(:value) { 1 }

      it 'should not change the association' do
        expect { entity.dungeon_id = value }
          .not_to change(entity, :dungeon)
      end

      it 'should set the foreign key' do
        expect { entity.dungeon_id = value }
          .to change(entity, :dungeon_id)
          .to be value
      end
    end

    wrap_context 'when the entity has an association' do
      describe 'with nil' do
        it 'should clear the association' do
          expect { entity.dungeon_id = nil }
            .to change(entity, :dungeon)
            .to be nil
        end

        it 'should clear the foreign key' do
          expect { entity.dungeon_id = nil }
            .to change(entity, :dungeon_id)
            .to be nil
        end
      end

      describe 'with a value' do
        let(:value) { 1 }

        it 'should clear the association' do
          expect { entity.dungeon_id = value }
            .to change(entity, :dungeon)
            .to be nil
        end

        it 'should set the foreign key' do
          expect { entity.dungeon_id = value }
            .to change(entity, :dungeon_id)
            .to be value
        end
      end
    end
  end

  describe '#properties' do
    let(:expected) do
      {
        'challenge'  => 20,
        'name'       => 'Lich Lord',
        'dungeon'    => nil,
        'dungeon_id' => nil
      }
    end

    it { expect(entity.properties).to be == expected }

    wrap_context 'when the entity has an association' do
      let(:expected) do
        super().merge(
          'dungeon'    => dungeon,
          'dungeon_id' => dungeon.id
        )
      end

      it { expect(entity.properties).to be == expected }
    end
  end

  describe '#properties=' do
    let(:value) do
      { dungeon: Spec::Dungeon.new(id: 1, name: 'Dread Necropolis') }
    end
    let(:expected) do
      {
        'challenge'  => nil,
        'name'       => nil,
        'dungeon'    => value[:dungeon],
        'dungeon_id' => value[:dungeon]&.id
      }
    end

    it 'should update the properties' do
      expect { entity.properties = value }
        .to change(entity, :properties)
        .to be == expected
    end

    it 'should update the foreign key' do
      expect { entity.properties = value }
        .to change(entity, :dungeon_id)
        .to be == value[:dungeon].id
    end

    wrap_context 'when the entity has an association' do
      it 'should update the properties' do
        expect { entity.properties = value }
          .to change(entity, :properties)
          .to be == expected
      end

      it 'should update the foreign key' do
        expect { entity.properties = value }
          .to change(entity, :dungeon_id)
          .to be == value[:dungeon].id
      end
    end
  end
end
