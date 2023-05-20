# frozen_string_literal: true

require 'support/entities/secret'

# @note Integration spec for Stannum::Entities::Associations.
#   - Tests a :one association with no foreign key or inverse.
RSpec.describe Spec::Secret do
  subject(:secret) { described_class.new(**attributes, **associations) }

  shared_context 'when the secret has a room' do
    let(:room)         { Spec::Room.new(name: 'Old Room') }
    let(:associations) { super().merge(room: room) }
  end

  let(:attributes)   { { difficulty: 10 } }
  let(:associations) { {} }

  describe '#assign_associations' do
    let(:value)    { { room: Spec::Room.new(name: 'New Room') } }
    let(:expected) { { 'room' => value[:room] } }

    it 'should update the associations' do
      expect { secret.assign_associations(value) }
        .to change(secret, :associations)
        .to be == expected
    end

    wrap_context 'when the secret has a room' do
      it 'should update the associations' do
        expect { secret.assign_associations(value) }
          .to change(secret, :associations)
          .to be == expected
      end
    end
  end

  describe '#assign_properties' do
    let(:value) { { room: Spec::Room.new(name: 'New Room') } }
    let(:expected) do
      {
        'difficulty' => 10,
        'room'       => value[:room]
      }
    end

    it 'should update the properties' do
      expect { secret.assign_properties(value) }
        .to change(secret, :properties)
        .to be == expected
    end

    wrap_context 'when the secret has a room' do
      it 'should update the properties' do
        expect { secret.assign_properties(value) }
          .to change(secret, :properties)
          .to be == expected
      end
    end
  end

  describe '#associations' do
    let(:expected) { { 'room' => nil } }

    it { expect(secret.associations).to be == expected }

    wrap_context 'when the secret has a room' do
      let(:expected) { super().merge('room' => room) }

      it { expect(secret.associations).to be == expected }
    end
  end

  describe '#associations=' do
    let(:value)    { { room: Spec::Room.new(name: 'New Room') } }
    let(:expected) { { 'room' => value[:room] } }

    it 'should update the associations' do
      expect { secret.associations = value }
        .to change(secret, :associations)
        .to be == expected
    end

    wrap_context 'when the secret has a room' do
      it 'should update the associations' do
        expect { secret.associations = value }
          .to change(secret, :associations)
          .to be == expected
      end
    end
  end

  describe '#properties' do
    let(:expected) do
      {
        'difficulty' => 10,
        'room'       => nil
      }
    end

    it { expect(secret.properties).to be == expected }

    wrap_context 'when the secret has a room' do
      let(:expected) { super().merge('room' => room) }

      it { expect(secret.properties).to be == expected }
    end
  end

  describe '#properties=' do
    let(:value) { { room: Spec::Room.new(name: 'New Room') } }
    let(:expected) do
      {
        'difficulty' => nil,
        'room'       => value[:room]
      }
    end

    it 'should update the properties' do
      expect { secret.properties = value }
        .to change(secret, :properties)
        .to be == expected
    end

    wrap_context 'when the secret has a room' do
      it 'should update the properties' do
        expect { secret.properties = value }
          .to change(secret, :properties)
          .to be == expected
      end
    end
  end

  describe '#room' do
    it { expect(secret.room).to be nil }

    wrap_context 'when the secret has a room' do
      it { expect(secret.room).to be room }
    end
  end

  describe '#room=' do
    describe 'with a value' do
      let(:value) { Spec::Room.new(name: 'New Room') }

      it 'should set the association' do
        expect { secret.room = value }
          .to change(secret, :room)
          .to be value
      end
    end

    wrap_context 'when the secret has a room' do
      describe 'with nil' do
        it 'should clear the association' do
          expect { secret.room = nil }
            .to change(secret, :room)
            .to be nil
        end
      end

      describe 'with a value' do
        let(:value) { Spec::Room.new(name: 'New Room') }

        it 'should set the association' do
          expect { secret.room = value }
            .to change(secret, :room)
            .to be value
        end
      end
    end
  end
end
