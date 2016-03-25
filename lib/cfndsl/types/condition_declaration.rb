require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # String type
    class ConditionDeclaration < JSONable
      include JSONSerialisableObject

      attr_reader :value

      def initialize(value)
        @value = value
      end
    end
  end
end
