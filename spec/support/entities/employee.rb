# frozen_string_literal: true

require 'stannum'

module Spec
  class Employee
    include Stannum::Entity

    AccessCard = Struct.new(:employee_id, :full_name)

    attribute :employee_id, String, default: -> { SecureRandom.uuid }
    attribute :full_name,   String, default: lambda { |employee|
      "#{employee.first_name} #{employee.last_name}"
    }
    attribute :first_name,  String, default: 'Jane'
    attribute :last_name,   String, default: 'Doe'
    attribute :access_card, AccessCard, default: lambda { |employee|
      AccessCard.new(employee.employee_id, employee.full_name)
    }
  end
end
