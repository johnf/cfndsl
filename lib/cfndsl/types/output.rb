require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Handles Output objects
    class Output < JSONable
      def initialize(value = nil)
        super()
        @Value = value if value
      end
    end
  end
end
