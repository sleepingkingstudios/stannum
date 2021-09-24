# frozen_string_literal: true

{
  en: {
    stannum: {
      constraints: {
        absent: 'is nil or empty',
        anything: 'is a value',
        does_not_have_methods: 'does not respond to the methods',
        has_methods: 'responds to the methods',
        invalid: 'is invalid',
        is_boolean: 'is true or false',
        is_in_list: 'is in the list',
        is_in_union: 'matches one of the constraints',
        is_equal_to: 'is equal to',
        is_not_boolean: 'is not true or false',
        is_not_equal_to: 'is not equal to',
        is_not_in_list: 'is not in the list',
        is_not_in_union: 'does not match any of the constraints',
        is_not_type: ->(_type, data) { "is not a #{data[:type]}" },
        is_not_value: 'is not the expected value',
        is_type: ->(_type, data) { "is a #{data[:type]}" },
        is_value: 'is the expected value',
        present: 'is not nil or empty',
        valid: 'is valid'
      }
    }
  }
}
