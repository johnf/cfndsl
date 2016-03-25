require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Resource type
    class Resource < JSONable
      def initialize
        super
        type = self.class.instance_variable_get(:@Type)
        instance_variable_set(:@Type, type)
      end

      def self.type=(type)
        instance_variable_set(:@Type, type)
      end
    end
  end
end
