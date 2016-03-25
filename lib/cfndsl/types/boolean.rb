require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Boolean type
    class Boolean < JSONable
      include JSONSerialisableObject

      attr_reader :value

      def initialize(value)
        @value = value
      end
    end
  end
end
