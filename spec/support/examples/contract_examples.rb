# frozen_string_literal: true

require 'rspec/sleeping_king_studios/concerns/shared_example_group'

require 'support/examples'

module Spec::Support::Examples
  module ContractExamples
    extend RSpec::SleepingKingStudios::Concerns::SharedExampleGroup

    def be_a_constraint_definition(properties)
      be_a(Stannum::Contracts::Definition).and(have_attributes(properties))
    end

    shared_context 'when #each_pair is stubbed' do
      let(:actual)      { nil }
      let(:constraints) { [] }
      let(:definitions) do
        constraints.map.with_index do |constraint, index|
          Stannum::Contracts::Definition.new(
            constraint: constraint,
            contract:   Stannum::Contracts::Base.new,
            options:    { index: index }
          )
        end
      end
      let(:values) do
        Array.new(constraints.size) { |index| "value #{index}" }
      end

      before(:example) do
        receive_each_pair = receive(:each_pair)

        definitions.zip(values).each do |definition, value|
          receive_each_pair.and_yield(definition, value)
        end

        allow(contract).to receive_each_pair
      end
    end

    shared_context 'when #each_pair yields a non-matching constraint' do
      let(:constraints) { [Stannum::Constraints::Nothing.new] }
    end

    shared_context 'when #each_pair yields a matching constraint' do
      let(:constraints) { [Stannum::Constraints::Anything.new] }
    end

    shared_context 'when #each_pair yields many non-matching constraints' do
      let(:constraints) do
        [
          Stannum::Constraints::Nothing.new,
          Stannum::Constraints::Nothing.new,
          Stannum::Constraints::Nothing.new
        ]
      end
    end

    shared_context 'when #each_pair yields many non-matching and matching' \
                   ' constraints' \
    do
      let(:constraints) do
        [
          Stannum::Constraints::Anything.new,
          Stannum::Constraints::Nothing.new,
          Stannum::Constraints::Anything.new
        ]
      end
    end

    shared_context 'when #each_pair yields many matching constraints' do
      let(:constraints) do
        [
          Stannum::Constraints::Anything.new,
          Stannum::Constraints::Anything.new,
          Stannum::Constraints::Anything.new
        ]
      end
    end

    shared_context 'when #map_errors is stubbed' do
      let(:errors) do
        Array.new(constraints.size) { Stannum::Errors.new }
      end

      before(:example) do
        definitions.each.with_index do |definition, index|
          allow(definition.contract)
            .to receive(:map_errors)
            .and_return(errors[index])
        end
      end
    end

    # rubocop:disable RSpec/RepeatedExampleGroupBody
    shared_examples 'should implement the Contract methods' do
      shared_examples 'should match each constraint' do |negated: false|
        let(:matches_method) { negated ? :does_not_match? : :matches? }

        context 'when the contract has one constaint' do
          let(:constraints) do
            Array.new(1) do
              instance_double(
                Stannum::Constraints::Base,
                matches_method => true
              )
            end
          end

          it 'should match the constraint', :aggregate_failures do
            contract.send(match_method, actual)

            constraints.each.with_index do |constraint, index|
              expect(constraint)
                .to have_received(matches_method)
                .with(values[index])
            end
          end
        end

        context 'when the contract has many constaints' do
          let(:constraints) do
            Array.new(3) do
              instance_double(
                Stannum::Constraints::Base,
                matches_method => true
              )
            end
          end

          it 'should match the constraints', :aggregate_failures do
            contract.send(match_method, actual)

            constraints.each.with_index do |constraint, index|
              expect(constraint)
                .to have_received(matches_method)
                .with(values[index])
            end
          end
        end
      end

      shared_examples 'should match and update errors for each constraint' \
      do |negated: false|
        shared_examples 'should map the errors' do
          wrap_context 'when #map_errors is stubbed' do
            before(:example) do
              constraints.each do |constraint|
                allow(constraint)
                  .to receive(matches_method)
                  .and_return(false)
              end
            end

            it 'should map the errors', :aggregate_failures do
              contract.send(match_method, actual)

              definitions.each do |definition|
                expect(definition.contract)
                  .to have_received(:map_errors)
                  .with(
                    an_instance_of(Stannum::Errors),
                    **definition.options
                  )
              end
            end

            it 'should pass the mapped errors to the constraint' do
              contract.send(match_method, actual)

              definitions.each.with_index do |definition, index|
                expect(definition.constraint)
                  .to have_received(update_errors_method)
                  .with(
                    actual: values[index],
                    errors: errors[index]
                  )
              end
            end
          end
        end

        let(:update_errors_method) do
          negated ? :update_negated_errors_for : :update_errors_for
        end
        let(:matches_method) { negated ? :does_not_match? : :matches? }

        context 'when the contract has one constraint' do
          let(:constraints) do
            Array.new(1) do
              instance_double(
                Stannum::Constraints::Base,
                matches_method       => true,
                update_errors_method => nil
              )
            end
          end

          include_context 'should map the errors'

          it 'should match the constraint', :aggregate_failures do
            contract.send(match_method, actual)

            constraints.each.with_index do |constraint, index|
              expect(constraint)
                .to have_received(matches_method)
                .with(values[index])
            end
          end

          context 'when the constraint does not match the object' do
            before(:example) do
              allow(constraints.first)
                .to receive(matches_method)
                .and_return(false)
            end

            it 'should update the errors', :aggregate_failures do
              contract.send(match_method, actual)

              constraints.each.with_index do |constraint, index|
                expect(constraint)
                  .to have_received(update_errors_method)
                  .with(
                    actual: values[index],
                    errors: an_instance_of(Stannum::Errors)
                  )
              end
            end
          end

          context 'when the constraint matches the object' do
            before(:example) do
              allow(constraints.first).to receive(:matches?).and_return(true)
            end

            it 'should not update the errors' do
              contract.send(match_method, actual)

              expect(constraints.first)
                .not_to have_received(update_errors_method)
            end
          end
        end

        context 'when the contract has many constraints' do
          let(:constraints) do
            Array.new(3) do
              instance_double(
                Stannum::Constraints::Base,
                matches_method       => true,
                update_errors_method => nil
              )
            end
          end

          include_context 'should map the errors'

          it 'should match the constraint', :aggregate_failures do
            contract.send(match_method, actual)

            constraints.each.with_index do |constraint, index|
              expect(constraint)
                .to have_received(matches_method)
                .with(values[index])
            end
          end

          context 'when the constraints do not match the object' do
            before(:example) do
              constraints.each do |constraint|
                allow(constraint).to receive(matches_method).and_return(false)
              end
            end

            it 'should update the errors', :aggregate_failures do
              contract.send(match_method, actual)

              constraints.each.with_index do |constraint, index|
                expect(constraint)
                  .to have_received(update_errors_method)
                  .with(
                    actual: values[index],
                    errors: an_instance_of(Stannum::Errors)
                  )
              end
            end
          end

          context 'when some of the constraints match the object' do
            before(:example) do
              constraints.each.with_index do |constraint, index|
                allow(constraint)
                  .to receive(matches_method)
                  .and_return(index.even?)
              end
            end

            it 'should update the errors', :aggregate_failures do # rubocop:disable RSpec/ExampleLength
              contract.send(match_method, actual)

              constraints.each.with_index do |constraint, index|
                if index.even?
                  expect(constraint).not_to have_received(update_errors_method)
                else
                  expect(constraint)
                    .to have_received(update_errors_method)
                    .with(
                      actual: values[index],
                      errors: an_instance_of(Stannum::Errors)
                    )
                end
              end
            end
          end

          context 'when the constraints match the object' do
            before(:example) do
              constraints.each do |constraint|
                allow(constraint).to receive(matches_method).and_return(true)
              end
            end

            it 'should not update the errors', :aggregate_failures do
              contract.send(match_method, actual)

              constraints.each do |constraint|
                expect(constraint).not_to have_received(update_errors_method)
              end
            end
          end
        end
      end

      describe '#does_not_match?' do
        include_context 'when #each_pair is stubbed'

        let(:match_method) { :does_not_match? }

        include_examples 'should match each constraint', negated: true

        it 'should delegate to #each_pair' do
          contract.does_not_match?(actual)

          expect(contract).to have_received(:each_pair).with(actual)
        end

        context 'when the contract has no constraints' do
          it { expect(contract.does_not_match? actual).to be true }
        end

        wrap_context 'when #each_pair yields a non-matching constraint' do
          it { expect(contract.does_not_match? actual).to be true }
        end

        wrap_context 'when #each_pair yields a matching constraint' do
          it { expect(contract.does_not_match? actual).to be false }
        end

        wrap_context 'when #each_pair yields many non-matching constraints' do
          it { expect(contract.does_not_match? actual).to be true }
        end

        wrap_context 'when #each_pair yields many non-matching and matching' \
                     ' constraints' \
        do
          it { expect(contract.does_not_match? actual).to be false }
        end

        wrap_context 'when #each_pair yields many matching constraints' do
          it { expect(contract.does_not_match? actual).to be false }
        end
      end

      describe '#errors_for' do
        include_context 'when #each_pair is stubbed'

        let(:wrapped_errors) do
          (expected_errors.is_a?(Array) ? expected_errors : [expected_errors])
            .map do |error|
              {
                data:    {},
                message: nil,
                path:    []
              }.merge(error)
            end
        end
        let(:match_method) { :errors_for }

        include_examples 'should match and update errors for each constraint'

        it { expect(contract.errors_for(actual)).to be_a Stannum::Errors }

        it 'should delegate to #each_pair' do
          contract.errors_for(actual)

          expect(contract).to have_received(:each_pair).with(actual)
        end

        context 'when the contract has no constraints' do
          it { expect(contract.errors_for(actual)).to be == [] }
        end

        wrap_context 'when #each_pair yields a non-matching constraint' do
          let(:expected_errors) do
            [{ type: Stannum::Constraints::Nothing::TYPE }]
          end

          it 'should return the expected errors' do
            expect(contract.errors_for(actual).to_a).to be == wrapped_errors
          end
        end

        wrap_context 'when #each_pair yields a matching constraint' do
          it { expect(contract.errors_for actual).to be == [] }
        end

        wrap_context 'when #each_pair yields many non-matching constraints' do
          let(:expected_errors) do
            [
              { type: Stannum::Constraints::Nothing::TYPE },
              { type: Stannum::Constraints::Nothing::TYPE },
              { type: Stannum::Constraints::Nothing::TYPE }
            ]
          end

          it 'should return the expected errors' do
            expect(contract.errors_for(actual).to_a).to be == wrapped_errors
          end
        end

        wrap_context 'when #each_pair yields many non-matching and matching' \
                     ' constraints' \
        do
          let(:expected_errors) do
            [{ type: Stannum::Constraints::Nothing::TYPE }]
          end

          it 'should return the expected errors' do
            expect(contract.errors_for(actual).to_a).to be == wrapped_errors
          end
        end

        wrap_context 'when #each_pair yields many matching constraints' do
          it { expect(contract.errors_for(actual).to_a).to be == [] }
        end
      end

      describe '#match' do
        include_context 'when #each_pair is stubbed'

        let(:wrapped_errors) do
          (expected_errors.is_a?(Array) ? expected_errors : [expected_errors])
            .map do |error|
              {
                data:    {},
                message: nil,
                path:    []
              }.merge(error)
            end
        end
        let(:match_method) { :match }
        let(:status)       { contract.match(actual).first }
        let(:errors)       { contract.match(actual).last }

        include_examples 'should match and update errors for each constraint'

        context 'when the contract has no constraints' do
          it { expect(status).to be true }

          it { expect(errors).to be == [] }
        end

        wrap_context 'when #each_pair yields a non-matching constraint' do
          let(:expected_errors) do
            [{ type: Stannum::Constraints::Nothing::TYPE }]
          end

          it { expect(status).to be false }

          it { expect(errors).to be == wrapped_errors }
        end

        wrap_context 'when #each_pair yields a matching constraint' do
          it { expect(status).to be true }

          it { expect(errors).to be == [] }
        end

        wrap_context 'when #each_pair yields many non-matching constraints' do
          let(:expected_errors) do
            [
              { type: Stannum::Constraints::Nothing::TYPE },
              { type: Stannum::Constraints::Nothing::TYPE },
              { type: Stannum::Constraints::Nothing::TYPE }
            ]
          end

          it { expect(status).to be false }

          it { expect(errors).to be == wrapped_errors }
        end

        wrap_context 'when #each_pair yields many non-matching and matching' \
                     ' constraints' \
        do
          let(:expected_errors) do
            [{ type: Stannum::Constraints::Nothing::TYPE }]
          end

          it { expect(status).to be false }

          it { expect(errors).to be == wrapped_errors }
        end

        wrap_context 'when #each_pair yields many matching constraints' do
          it { expect(status).to be true }

          it { expect(errors).to be == [] }
        end
      end

      describe '#matches?' do
        include_context 'when #each_pair is stubbed'

        let(:match_method) { :matches? }

        include_examples 'should match each constraint'

        it 'should delegate to #each_pair' do
          contract.matches?(actual)

          expect(contract).to have_received(:each_pair).with(actual)
        end

        context 'when the contract has no constraints' do
          it { expect(contract.matches? actual).to be true }
        end

        wrap_context 'when #each_pair yields a non-matching constraint' do
          it { expect(contract.matches? actual).to be false }
        end

        wrap_context 'when #each_pair yields a matching constraint' do
          it { expect(contract.matches? actual).to be true }
        end

        wrap_context 'when #each_pair yields many non-matching constraints' do
          it { expect(contract.matches? actual).to be false }
        end

        wrap_context 'when #each_pair yields many non-matching and matching' \
                     ' constraints' \
        do
          it { expect(contract.matches? actual).to be false }
        end

        wrap_context 'when #each_pair yields many matching constraints' do
          it { expect(contract.matches? actual).to be true }
        end
      end

      describe '#negated_errors_for' do
        include_context 'when #each_pair is stubbed'

        let(:wrapped_errors) do
          (expected_errors.is_a?(Array) ? expected_errors : [expected_errors])
            .map do |error|
              {
                data:    {},
                message: nil,
                path:    []
              }.merge(error)
            end
        end
        let(:match_method) { :negated_errors_for }

        include_examples 'should match and update errors for each constraint',
          negated: true

        it 'should return an errors object' do
          expect(contract.negated_errors_for(actual)).to be_a Stannum::Errors
        end

        it 'should delegate to #each_pair' do
          contract.negated_errors_for(actual)

          expect(contract).to have_received(:each_pair).with(actual)
        end

        wrap_context 'when #each_pair yields a non-matching constraint' do
          it { expect(contract.negated_errors_for actual).to be == [] }
        end

        wrap_context 'when #each_pair yields a matching constraint' do
          let(:expected_errors) do
            [{ type: Stannum::Constraints::Anything::NEGATED_TYPE }]
          end

          it 'should return the expected errors' do
            expect(contract.negated_errors_for(actual).to_a)
              .to be == wrapped_errors
          end
        end

        wrap_context 'when #each_pair yields many non-matching constraints' do
          it { expect(contract.negated_errors_for actual).to be == [] }
        end

        wrap_context 'when #each_pair yields many non-matching and matching' \
                     ' constraints' \
        do
          let(:expected_errors) do
            [
              { type: Stannum::Constraints::Anything::NEGATED_TYPE },
              { type: Stannum::Constraints::Anything::NEGATED_TYPE }
            ]
          end

          it 'should return the expected errors' do
            expect(contract.negated_errors_for(actual).to_a)
              .to be == wrapped_errors
          end
        end

        wrap_context 'when #each_pair yields many matching constraints' do
          let(:expected_errors) do
            [
              { type: Stannum::Constraints::Anything::NEGATED_TYPE },
              { type: Stannum::Constraints::Anything::NEGATED_TYPE },
              { type: Stannum::Constraints::Anything::NEGATED_TYPE }
            ]
          end

          it 'should return the expected errors' do
            expect(contract.negated_errors_for(actual).to_a)
              .to be == wrapped_errors
          end
        end
      end

      describe '#negated_match' do
        include_context 'when #each_pair is stubbed'

        let(:wrapped_errors) do
          (expected_errors.is_a?(Array) ? expected_errors : [expected_errors])
            .map do |error|
              {
                data:    {},
                message: nil,
                path:    []
              }.merge(error)
            end
        end
        let(:match_method) { :negated_match }
        let(:status)       { contract.negated_match(actual).first }
        let(:errors)       { contract.negated_match(actual).last }

        include_examples 'should match and update errors for each constraint',
          negated: true

        wrap_context 'when #each_pair yields a non-matching constraint' do
          it { expect(status).to be true }

          it { expect(errors).to be == [] }
        end

        wrap_context 'when #each_pair yields a matching constraint' do
          let(:expected_errors) do
            [{ type: Stannum::Constraints::Anything::NEGATED_TYPE }]
          end

          it { expect(status).to be false }

          it { expect(errors).to be == wrapped_errors }
        end

        wrap_context 'when #each_pair yields many non-matching constraints' do
          it { expect(status).to be true }

          it { expect(errors).to be == [] }
        end

        wrap_context 'when #each_pair yields many non-matching and matching' \
                     ' constraints' \
        do
          let(:expected_errors) do
            [
              { type: Stannum::Constraints::Anything::NEGATED_TYPE },
              { type: Stannum::Constraints::Anything::NEGATED_TYPE }
            ]
          end

          it { expect(status).to be false }

          it { expect(errors).to be == wrapped_errors }
        end

        wrap_context 'when #each_pair yields many matching constraints' do
          let(:expected_errors) do
            [
              { type: Stannum::Constraints::Anything::NEGATED_TYPE },
              { type: Stannum::Constraints::Anything::NEGATED_TYPE },
              { type: Stannum::Constraints::Anything::NEGATED_TYPE }
            ]
          end

          it { expect(status).to be false }

          it { expect(errors).to be == wrapped_errors }
        end
      end
    end
    # rubocop:enable RSpec/RepeatedExampleGroupBody
  end
end
