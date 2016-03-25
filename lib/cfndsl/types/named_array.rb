require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Resource type
    class NamedArray < JSONable
      def initialize(value)
        super()
        @value = value
      end
    end
  end
end
