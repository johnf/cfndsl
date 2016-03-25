require 'cfndsl/common_functions'

module CfnDsl
  module AWS
    # AWS Functions
    module Functions
      include CommonFunctions

      def self.add_return_type(name, type)
        @return_type ||= {}
        @return_type[name] = type
      end

      def self.add_description(name, description)
        @description ||= {}
        @description[name] = description
      end
    end
  end
end
