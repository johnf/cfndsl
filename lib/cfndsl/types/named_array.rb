require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Resource type
    class NamedArray < JSONable
      def initialize(value = nil)
        super()
        @value = value if value
      end
    end
  end
end
