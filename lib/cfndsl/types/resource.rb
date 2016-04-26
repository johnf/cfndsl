require 'cfndsl/jsonable'

module CfnDsl
  module Types
    # Resource type
    class Resource < JSONable
      def initialize
        super
        type = self.class.to_s.sub(/^CfnDsl::CloudFormationTemplate::/, '').gsub(/_/, '::')
        instance_variable_set(:@Type, "AWS::#{type}")
      end
    end
  end
end
