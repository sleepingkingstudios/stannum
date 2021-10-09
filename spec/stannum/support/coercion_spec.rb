# frozen_string_literal: true

require 'stannum/support/coercion'

RSpec.describe Stannum::Support::Coercion do
  describe '.error_key' do
    it { expect(described_class).to respond_to(:error_key).with(1).argument }

    describe 'with nil' do
      it { expect(described_class.error_key nil).to be == 'nil' }
    end

    describe 'with an object' do
      let(:value) { Object.new.freeze }

      it { expect(described_class.error_key value).to be == value.inspect }
    end

    describe 'with an integer' do
      it { expect(described_class.error_key 1).to be 1 }
    end

    describe 'with a string' do
      let(:value) { 'string' }

      it { expect(described_class.error_key value).to be value }
    end

    describe 'with a symbol' do
      let(:value) { :symbol }

      it { expect(described_class.error_key value).to be value }
    end
  end

  describe '.presence_constraint' do
    let(:error_message) { 'present must be true or false or a constraint' }

    it 'should define the class method' do
      expect(described_class).to respond_to(:presence_constraint)
        .with(1).argument
        .and_keywords(:allow_nil, :as)
        .and_any_keywords
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { described_class.presence_constraint nil }
          .to raise_error ArgumentError, error_message
      end

      describe 'with allow_nil: true' do
        it 'should return nil' do
          expect(described_class.presence_constraint nil, allow_nil: true)
            .to be nil
        end
      end

      describe 'with as: string' do
        let(:error_message) do
          'value present must be true or false or a constraint'
        end

        it 'should raise an error' do
          expect do
            described_class.presence_constraint nil, as: 'value present'
          end
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it 'should raise an error' do
        expect { described_class.presence_constraint value }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: string' do
        let(:error_message) do
          'value present must be true or false or a constraint'
        end

        it 'should raise an error' do
          expect do
            described_class.presence_constraint value, as: 'value present'
          end
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with a Constraint' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:copy)       { described_class.presence_constraint constraint }

      it { expect(copy).not_to be constraint }

      it { expect(copy).to be_a constraint.class }

      it { expect(copy.options).to be == constraint.options }

      describe 'with options: values' do
        let(:options) { { optional: true, key: 'value' } }

        it 'should set the options' do
          expect(
            described_class.presence_constraint(constraint, **options).options
          )
            .to be == constraint.options.merge(options)
        end
      end
    end

    describe 'with false' do
      let(:options)  { {} }
      let(:expected) { options }

      it 'should return an absence constraint' do
        expect(described_class.presence_constraint false)
          .to be_a Stannum::Constraints::Absence
      end

      it 'should set the options' do
        expect(described_class.presence_constraint(false).options)
          .to be == expected
      end

      describe 'with a block' do
        let(:block) do
          lambda do |value, **options|
            Stannum::Constraint.new(expected: value, **options)
          end
        end
        let(:expected) { { expected: false } }

        it 'should build a constraint using the block' do
          expect(described_class.presence_constraint(false, &block))
            .to be_a Stannum::Constraint
        end

        it 'should set the options' do
          expect(described_class.presence_constraint(false, &block).options)
            .to be == expected
        end

        describe 'with options: values' do
          let(:options)  { { optional: true, key: 'value' } }
          let(:expected) { super().merge(options) }

          it 'should set the options' do
            expect(
              described_class.presence_constraint(false, **options, &block)
              .options
            )
              .to be == expected
          end
        end
      end

      describe 'with options: values' do
        let(:options) { { optional: true, key: 'value' } }

        it 'should set the options' do
          expect(described_class.presence_constraint(false, **options).options)
            .to be == expected
        end
      end
    end

    describe 'with true' do
      let(:options)  { {} }
      let(:expected) { options }

      it 'should return a presence constraint' do
        expect(described_class.presence_constraint true)
          .to be_a Stannum::Constraints::Presence
      end

      it 'should set the options' do
        expect(described_class.presence_constraint(true).options)
          .to be == expected
      end

      describe 'with a block' do
        let(:block) do
          lambda do |value, **options|
            Stannum::Constraint.new(expected: value, **options)
          end
        end
        let(:expected) { { expected: true } }

        it 'should build a constraint using the block' do
          expect(described_class.presence_constraint(true, &block))
            .to be_a Stannum::Constraint
        end

        it 'should set the options' do
          expect(described_class.presence_constraint(true, &block).options)
            .to be == expected
        end

        describe 'with options: values' do
          let(:options)  { { optional: true, key: 'value' } }
          let(:expected) { super().merge(options) }

          it 'should set the options' do
            expect(
              described_class.presence_constraint(true, **options, &block)
              .options
            )
              .to be == expected
          end
        end
      end

      describe 'with options: values' do
        let(:options) { { optional: true, key: 'value' } }

        it 'should set the options' do
          expect(described_class.presence_constraint(true, **options).options)
            .to be == expected
        end
      end
    end
  end

  describe '.type_constraint' do
    let(:error_message) { 'type must be a Class or Module or a constraint' }

    it 'should define the class method' do
      expect(described_class).to respond_to(:type_constraint)
        .with(1).argument
        .and_keywords(:allow_nil, :as)
        .and_any_keywords
    end

    describe 'with nil' do
      it 'should raise an error' do
        expect { described_class.type_constraint nil }
          .to raise_error ArgumentError, error_message
      end

      describe 'with allow_nil: true' do
        it 'should return nil' do
          expect(described_class.type_constraint nil, allow_nil: true)
            .to be nil
        end
      end

      describe 'with as: string' do
        let(:error_message) do
          'custom type must be a Class or Module or a constraint'
        end

        it 'should raise an error' do
          expect { described_class.type_constraint nil, as: 'custom type' }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with an Object' do
      let(:value) { Object.new.freeze }

      it 'should raise an error' do
        expect { described_class.type_constraint value }
          .to raise_error ArgumentError, error_message
      end

      describe 'with as: string' do
        let(:error_message) do
          'custom type must be a Class or Module or a constraint'
        end

        it 'should raise an error' do
          expect { described_class.type_constraint value, as: 'custom type' }
            .to raise_error ArgumentError, error_message
        end
      end
    end

    describe 'with a Constraint' do
      let(:constraint) { Stannum::Constraints::Base.new }
      let(:copy)       { described_class.type_constraint constraint }

      it { expect(copy).not_to be constraint }

      it { expect(copy).to be_a constraint.class }

      it { expect(copy.options).to be == constraint.options }

      describe 'with options: values' do
        let(:options) { { optional: true, key: 'value' } }

        it 'should set the options' do
          expect(described_class.type_constraint(constraint, **options).options)
            .to be == constraint.options.merge(options)
        end
      end
    end

    describe 'with a Class' do
      let(:options) { {} }
      let(:expected) do
        Stannum::Constraints::Type.new(String, **options).options
      end

      it 'should return a type constraint' do
        expect(described_class.type_constraint String)
          .to be_a Stannum::Constraints::Type
      end

      it 'should set the expected type' do
        expect(described_class.type_constraint(String).expected_type)
          .to be String
      end

      it 'should set the options' do
        expect(described_class.type_constraint(String).options)
          .to be == expected
      end

      describe 'with a block' do
        let(:block) do
          lambda do |value, **options|
            Stannum::Constraint.new(expected: value, **options)
          end
        end
        let(:expected) { { expected: String } }

        it 'should build a constraint using the block' do
          expect(described_class.type_constraint(String, &block))
            .to be_a Stannum::Constraint
        end

        it 'should set the options' do
          expect(described_class.type_constraint(String, &block).options)
            .to be == expected
        end

        describe 'with options: values' do
          let(:options)  { { optional: true, key: 'value' } }
          let(:expected) { super().merge(options) }

          it 'should set the options' do
            expect(
              described_class.type_constraint(String, **options, &block)
              .options
            )
              .to be == expected
          end
        end
      end

      describe 'with options: values' do
        let(:options) { { optional: true, key: 'value' } }

        it 'should set the options' do
          expect(described_class.type_constraint(String, **options).options)
            .to be == expected
        end
      end
    end
  end
end
