require 'cfndsl/types'
require 'awesome_print'

module CfnDsl
  # AWS
  module AWS
    # Cloud Formation Types
    module Types
      def self.load_data
        filename = "#{File.dirname(__FILE__)}/../../../data/aws/CloudFormationV1.schema"
        data = JSON.parse(File.read(filename))

        # TODO: use data['intrinsic-functions'] to build up the functions
        # TODO: use data['pseudo-parameters'] to build up the included virtual params

        @root = data['root-schema-object']
        @functions = data['intrinsic-functions']
        @resources = @root['properties'].delete('Resources')

        const_set('Root', @root)
        const_set('Resources', @resources)
        const_set('Functions', @functions)
      end

      PropertyTypes = %w(Object String Named-Array Json Number Array Boolean ConditionDeclaration Resource Reference DestinationCidrBlock Policy).freeze

      def self.validate
        validate_object('root', @root)
        validate_resources
      end

      def self.validate_object(name, object)
        type = object['type']
        properties = object['properties']

        raise("#{name}: Don't know how to deal with type #{type} yet") unless PropertyTypes.include?(type)

        return unless properties

        properties.each do |property_name, property|
          validate_object(property_name, property)
        end
      end

      def self.validate_resources
        raise 'Resources \'type\' has changed' unless @resources['type'] == 'Named-Array'
        raise 'Resources \'schema\' has changed' unless @resources['schema-lookup-property'] == 'Type'
        raise 'Resources \'required\' has changed' unless @resources['required'] == true

        @resources['child-schemas'].each do |resource_name, resource|
          validate_object("Resource:#{resource_name}", resource)
        end
      end

      load_data
      validate
    end
  end
end
