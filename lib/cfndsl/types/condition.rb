require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Condition
    class Condition < JSONable
      include JSONSerialisableObject

      def initialize(value)
        super()
        @value = value
      end
    end
  end
end
