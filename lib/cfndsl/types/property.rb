require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Property type
    class Property < JSONable
      include JSONSerialisableObject
    end
  end
end
