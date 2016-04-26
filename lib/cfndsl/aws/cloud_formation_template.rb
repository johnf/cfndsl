require 'cfndsl/aws/types'
require 'cfndsl/aws/functions'
require 'cfndsl/types/string'
require 'cfndsl/types/resource'
require 'cfndsl/types/array'
require 'cfndsl/types/number'
require 'cfndsl/types/boolean'
require 'cfndsl/types/condition_declaration'
require 'cfndsl/types/named_string'
require 'cfndsl/types/named_array'
require 'cfndsl/types/output'
require 'cfndsl/types/mapping'
require 'cfndsl/types/condition'
require 'cfndsl/types/property'

module CfnDsl
  # Cloud Formation Templates
  class CloudFormationTemplate < JSONable
    include AWS::Functions # TODO: Should we include this here?
    include CfnDsl::ConditionFunctions

    def self.resources
      CfnDsl::AWS::Types::Resources
    end

    def self.functions
      CfnDsl::AWS::Types::Functions
    end

    def self.root
      CfnDsl::AWS::Types::Root
    end

    def self.create_properties(object, parent_klass, options = {})
      object['properties'].each do |property_name, property|
        create_property(parent_klass, property_name, property, options)
      end
    end

    def self.create_resources
      resources['child-schemas'].each do |property_name, property|
        property['type'] = 'RootResource'
        create_property(self, property_name, property)
      end
    end

    def self.create_property(parent_klass, property_name, property, options = {})
      return if %w(AWS::Elasticsearch::Domain AWS::WAF::SqlInjectionMatchSet).include?(property_name)
      type = property.delete('type')
      type = 'Object' if options[:resource_property]

      required = property.delete('required')
      parent_klass.add_required(property_name) if required && property_name != 'Resources' # Don't make resources requirred
      parent_klass.add_description(property_name, property.delete('description'))

      if property_name == 'ImageId'
        p property_name
        ap property
        ap options
        p type
      end

      case type
      when 'String', 'Number', 'Json', 'Boolean', 'Policy',
        'Resource', 'Reference', 'DestinationCidrBlock' # FIXME: Not sure about these
        define_string_method(parent_klass, property_name, property)
      when 'Array'
        define_array_method(parent_klass, property_name, property)
      when 'Named-Array', 'Object'
        define_named_array_method(parent_klass, property_name, property, options)
      when 'ConditionDeclaration'
        define_condition_declaration_method(parent_klass, property_name, property)
      when 'RootResource'
        property_name = property_name.gsub(/::/, '_').sub(/^AWS_/, '')

        # FIXME: Moo
        if property_name == 'EC2_Instance'
          define_named_array_method(parent_klass, property_name, property, root_resource: true)
        else
          property.delete('properties')
          property.delete('allowed-values')
        end
      else
        ap parent_klass
        ap property_name
        raise("Can't deal with #{type} yet")
      end

      # TODO: what can we do with these
      _disable_refs = property.delete('disable-refs')
      _disable_functions = property.delete('disable-functions')
      _resource_ref_type = property.delete('resource-ref-type')
      _return_values = property.delete('return-values')
      _schema_lookup_property = property.delete('schema-lookup-property')

      unless property.empty?
        # p parent_klass
        # ap property_name
        # ap type
        # ap property
        #raise("Didn't process properties #{property.keys}")
      end
    end

    # TODO: Rename to cover String and Number
    def self.define_string_method(parent_klass, property_name, property)
      klass = Class.new(Types::String)
      parent_klass.const_set(property_name, klass) unless property_name =~ /^[a-z]/ # FIXME: Better way to deal with this?

      allowed_values = property.delete('allowed-values')

      parent_klass.class_eval do
        define_method(property_name) do |string|
          Errors.error("Argument #{string} must be one of [\"#{allowed_values.join('","')}\"]", caller) unless allowed_values?(string, allowed_values)

          property_obj = klass.new(string)

          instance_variable_set(:"@#{property_name}", property_obj)

          property_obj
        end
      end

      klass
    end

    def self.define_array_method(parent_klass, property_name, property)
      klass = Class.new(Types::Array)
      parent_klass.const_set(property_name, klass)

      array_class = property.delete('array-type')
      allowed_values = property.delete('allowed-values')
      resource_ref_type = property.delete('resource-ref-type')

      if array_class == 'Object'
        if resource_ref_type
          array_class = resource_ref_type.sub(/^AWS::/, '').gsub(/::/, '_')
        else
          klass = define_named_array_method(klass, "#{property_name}Array", property)
          array_class = klass.to_s
        end
      end

      parent_klass.class_eval do
        define_method(property_name) do |array|
          Errors.error("Array elements must all be of class #{array_class}", caller) unless array.map { |e| e.class.to_s }.compact.uniq.first == array_class
          array.each do |value|
            Errors.error("Array element #{value} must be one of [\"#{allowed_values.join('","')}\"]", caller) unless allowed_values?(value, allowed_values)
          end

          property_obj = klass.new(array)

          instance_variable_set(:"@#{property_name}", property_obj)

          property_obj
        end
      end

      klass
    end

    def self.define_named_array_method(parent_klass, property_name, property, options = {})
      case property_name
      when 'Outputs'
        klass = Types::Output
      when 'Mappings'
        klass = Types::Mapping
      when 'Conditions'
        klass = Types::Condition
      when 'Properties'
        # FIXME: Are we only doing this for top level Resource?
        # Pull Properties into Resource
        child_schema = {
          'properties' => property.delete('properties')
        }
        create_properties(child_schema, parent_klass, resource_property: true)
        return
      else
        if options[:resource_property]
          klass = Class.new(Types::Property)
          instance_variable_name = '@Properties'
        elsif options[:root_resource]
          klass = Class.new(Types::Resource)
          instance_variable_name = '@Resources'
        else
          klass = Class.new(Types::NamedArray)
        end

        parent_klass.const_set(property_name, klass)
      end

      instance_variable_name ||= "@#{property_name}"

      method_name = property_name.sub(/s$/, '')

      parent_klass.class_eval do
        # p "#{parent_klass} : #{method_name}"
        define_method(method_name) do |name, *args, &block|
          object = klass.new(*args)

          hash = instance_variable_get(instance_variable_name)
          hash = instance_variable_set(instance_variable_name, {}) unless hash

          hash[name] = object

          object.instance_eval(&block) if block

          object
        end
      end

      return if options[:resource_property]

      if property['child-schemas']
        child_schema = {
          'properties' => property.delete('child-schemas')
        }
        type = 'Object'
      elsif property['properties'] # For Resource Property
        child_schema = {
          'properties' => property.delete('properties')
        }
        type = 'Object'
      else # For Resource
        child_schema = property.delete('default-child-schema')
        # p 'MOO'
        # p parent_klass
        # p property_name
        # p property
        # p child_schema
        type = child_schema.delete('type')
        options[:resource_property] = true
      end

      child_schema.delete('required') # TODO: Should we validate this somehow?

      # Our definitions are better
      return klass if type == 'ConditionDefinitions'

      case type
      when 'Object'
        create_properties(child_schema, klass, options)
      when 'Json'
        # TODO: This is only really for Mapping, should we capture that?
      else
        raise("Don't know how to deal with #{type}") unless %w(Object).include?(type)
      end

      klass
    end

    # TODO: Do a ref check on the conditons
    def self.define_condition_declaration_method(parent_klass, property_name, property)
      klass = Class.new(Types::ConditionDeclaration)
      parent_klass.const_set(property_name, klass)

      raise("Don't know how to deal with ConditionDeclaration") unless property == {}

      parent_klass.class_eval do
        define_method(property_name) do |_declaration|
          property_obj = klass.new(string)

          instance_variable_set(:"@#{property_name}", property_obj)

          property_obj
        end
      end

      klass
    end

    def self.create_functions
      functions.each do |function_name, property|
        create_function(function_name, property)
      end
    end

    # TODO: FInish this
    def self.create_function(function_name, property)
      _parameter = property.delete('parameter')
      _skeleton = property.delete('skeleton')

      AWS::Functions.add_return_type(function_name, property.delete('return-type'))
      AWS::Functions.add_description(function_name, property.delete('description'))

      method_name = function_name.sub(/Fn::/, 'Fn')

      AWS::Functions.module_eval do
        define_method(method_name) do |*args|
          if method_name =~ /Fn/
            Fn.new(function_name, args)
          else
            Ref.new(*args)
          end
        end
      end

      raise("Didn't process properties #{property.keys}") unless property.empty?
    end

    create_properties(root, self)
    create_functions
    create_resources
  end
end
