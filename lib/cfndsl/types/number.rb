require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Number type
    class Number < JSONable
      include JSONSerialisableObject

      attr_reader :value

      def initialize(value)
        @value = value
      end
    end
  end
end
