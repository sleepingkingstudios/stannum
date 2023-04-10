# frozen_string_literal: true

require 'support/entities/employee'

# @note Integration spec for Stannum::Entity.
#   Asserts the order that default attribute values are calculated:
#
#   1. Attributes with a given value.
#   2. Attributes with a default value.
#   3. Attributes with a default proc, in order of definition.
RSpec.describe Spec::Employee do
  shared_context 'when initialized with partial attribute values' do
    let(:attributes) do
      {
        employee_id: '[classified]',
        last_name:   'Shepard'
      }
    end
  end

  shared_context 'when initialized with complete attribute values' do
    let(:attributes) do
      {
        employee_id: '[classified]',
        first_name:  'Jonathan',
        last_name:   'Shepard',
        full_name:   'Jonathan "John" Shepard'
      }
    end
  end

  subject(:employee) { described_class.new(**attributes) }

  let(:attributes) { {} }

  describe '#attributes' do
    let(:expected) do
      {
        'employee_id' => an_instance_of(String),
        'first_name'  => 'Jane',
        'last_name'   => 'Doe',
        'full_name'   => 'Jane Doe',
        'access_card' => an_instance_of(described_class::AccessCard)
      }
    end

    it { expect(employee.attributes).to deep_match expected }

    it { expect(employee.attributes['employee_id']).to be_a_uuid }

    it 'should generate the access card', :aggregate_failures do
      expect(employee.attributes['access_card'].employee_id).to be_a_uuid
      expect(employee.attributes['access_card'].full_name).to be == 'Jane Doe'
    end

    wrap_context 'when initialized with partial attribute values' do
      let(:expected) do
        {
          'employee_id' => '[classified]',
          'first_name'  => 'Jane',
          'last_name'   => 'Shepard',
          'full_name'   => 'Jane Shepard',
          'access_card' => an_instance_of(described_class::AccessCard)
        }
      end

      it { expect(employee.attributes).to deep_match expected }

      it { expect(employee.attributes['employee_id']).to be == '[classified]' }

      it 'should generate the access card', :aggregate_failures do
        expect(employee.attributes['access_card'].employee_id)
          .to be == '[classified]'
        expect(employee.attributes['access_card'].full_name)
          .to be == 'Jane Shepard'
      end
    end

    wrap_context 'when initialized with complete attribute values' do
      let(:expected) do
        {
          'employee_id' => '[classified]',
          'first_name'  => 'Jonathan',
          'last_name'   => 'Shepard',
          'full_name'   => 'Jonathan "John" Shepard',
          'access_card' => an_instance_of(described_class::AccessCard)
        }
      end

      it { expect(employee.attributes).to deep_match expected }

      it { expect(employee.attributes['employee_id']).to be == '[classified]' }

      it 'should generate the access card', :aggregate_failures do
        expect(employee.attributes['access_card'].employee_id)
          .to be == '[classified]'
        expect(employee.attributes['access_card'].full_name)
          .to be == 'Jonathan "John" Shepard'
      end
    end
  end
end
