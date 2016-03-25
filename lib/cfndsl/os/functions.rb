require 'cfndsl/common_functions'

module CfnDsl
  module OS
    # Functions
    module Functions
      include CommonFunctions
      include ConditonFunctions
      # Equivalent to the CloudFormation template built in function Ref
      def Ref(value)
        RefDefinition.new(value)
      end

      # Equivalent to the CloudFormation template built in function Fn::Base64
      def FnBase64(value)
        Fn.new('Base64', value)
      end

      # Equivalent to the CloudFormation template built in function Fn::FindInMap
      def FnFindInMap(map, key, value)
        Fn.new('FindInMap', [map, key, value])
      end

      # Equivalent to the CloudFormation template built in function Fn::GetAtt
      def FnGetAtt(logical_resource, attribute)
        Fn.new('GetAtt', [logical_resource, attribute])
      end

      # Equivalent to the CloudFormation template built in function Fn::GetAZs
      def FnGetAZs(region)
        Fn.new('GetAZs', region)
      end

      # Equivalent to the CloudFormation template built in function Fn::Join
      def FnJoin(string, array)
        Fn.new('Join', [string, array])
      end

      # Equivalent to the CloudFormation template built in function Fn::Select
      def FnSelect(index, array)
        Fn.new('Select', [index, array])
      end
    end
  end
end
