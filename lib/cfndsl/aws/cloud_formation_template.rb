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

module CfnDsl
  # Cloud Formation Templates
  class CloudFormationTemplate < JSONable
    include AWS::Functions # TODO: Should we include this here?
    include CfnDsl::ConditionFunctions

    def self.root_resources
      CfnDsl::AWS::Types::Resources
    end

    def self.functions
      CfnDsl::AWS::Types::Functions
    end

    def self.root
      CfnDsl::AWS::Types::Root
    end

    def self.create_properties(object, parent_klass)
      object['properties'].each do |property_name, property|
        next if %w(Resources).include?(property_name) # TODO: implement these

        create_property(parent_klass, property_name, property)
      end
    end

    def self.create_property(parent_klass, property_name, property)
      type = property.delete('type')

      parent_klass.add_required(property_name) if property.delete('required')
      parent_klass.add_description(property_name, property.delete('description'))
      # TODO: what can we do with these
      _disable_refs = property.delete('disable-refs')
      _disable_functions = property.delete('disable-functions')

      case type
      when 'String', 'Number', 'Json'
        define_string_method(parent_klass, property_name, property)
      when 'Array'
        define_array_method(parent_klass, property_name, property)
      when 'Named-Array'
        define_named_array_method(parent_klass, property_name, property)
      when 'ConditionDeclaration'
        define_condition_declaration_method(parent_klass, property_name, property)
        # when 'Named-String'
        #   define_named_string_method(property_name, property, options)
      else
        raise("Can't deal with #{type} yet")
      end

      raise("Didn't process properties #{property.keys}") unless property.empty?
    end

    # TODO: Rename to cover String and Number
    def self.define_string_method(parent_klass, property_name, property)
      klass = Class.new(Types::String)
      parent_klass.const_set(property_name, klass)

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

      parent_klass.class_eval do
        define_method(property_name) do |array|
          Errors.error("Array elements must all be of class #{array_class}", caller) unless array.map { |e| e.class.to_s }.compact.uniq.first == array_class

          property_obj = klass.new(array)

          instance_variable_set(:"@#{property_name}", property_obj)

          property_obj
        end
      end

      klass
    end

    def self.define_named_array_method(parent_klass, property_name, property)
      case property_name
      when 'Outputs'
        klass = Types::Output
      when 'Mappings'
        klass = Types::Mapping
      else
        klass = Class.new(Types::NamedArray)
        parent_klass.const_set(property_name, klass)
      end

      instance_variable_name = "@#{property_name}"
      method_name = property_name.sub(/s$/, '')

      parent_klass.class_eval do
        define_method(method_name) do |name, *args, &block|
          object = klass.new(*args)

          hash = instance_variable_get(instance_variable_name)
          hash = instance_variable_set(instance_variable_name, {}) unless hash

          hash[name] = object

          object.instance_eval(&block) if block

          object
        end
      end

      child_schema = property.delete('default-child-schema')
      type = child_schema.delete('type')
      child_schema.delete('required') # TODO: Should we validate this somehow?

      # Our definitions are better
      return klass if type == 'ConditionDefinitions'

      case type
      when 'Object'
        create_properties(child_schema, klass)
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

    # # TODO: Deal with
    # # - required
    # # - properties
    # # - return-values
    # def self.define_resource_method(resource_name, resource)
    #   name = resource_name.gsub(/::/, '_').gsub(/^AWS_/, '')

    #   klass = Class.new(Types::Resource)
    #   klass.type = resource_name
    #   const_set(name, klass)

    #   define_method(name) do |instance_name, &block|
    #     resource_obj = klass.new
    #     @Resources ||= {}
    #     @Resources[instance_name] = resource_obj

    #     resource_obj.instance_eval(&block) if block

    #     resource_obj
    #   end

    #   return unless resource_name == 'AWS::EC2::Instance'
    #   resource['properties'].each do |property_name, property|
    #     next if %w(Type CreationPolicy Condition DependsOn DeletionPolicy Metadata).include?(property_name)
    #     p property_name

    #     create_properties(property, klass: klass, object_type: :properties)
    #   end
    # end

    # def self.create_properties(parent_property, options = {})
    #   parent_property['properties'].each do |property_name, property|
    #     next if property_name == 'SsmAssociations'

    #     type = property['type']

    #     case type
    #     when 'String'
    #       define_string_method(property_name, property, options)
    #     when 'Array'
    #       define_array_method(property_name, property, options)
    #     when 'Number'
    #       define_number_method(property_name, property, options)
    #     when 'Boolean'
    #       define_boolean_method(property_name, property, options)
    #     when 'ConditionDeclaration'
    #       define_condition_decleration_method(property_name, property, options)
    #     when 'Object', 'Json', 'Resource'
    #       puts property_name
    #       puts "Implement #{type}"
    #       # TODO: Implement
    #     else
    #       raise("Can't deal with #{type} yet")
    #     end
    #   end
    # end

    # # TODO: Deal with
    # # - type
    # # - array-type
    # # - required
    # # - description
    # def self.define_array_method(property_name, property, options = {})
    #   klass = Class.new(Types::Array)

    #   eval_klass = options[:klass] || self
    #   object_type = options[:object_type] || :instance

    #   allowed_values = property['allowed-values']
    #   array_class = property['array-type']

    #   # parent_klass.const_set(property_name, klass)
    #   property_name = property_name.sub(/Fn::/, 'Fn_')

    #   eval_klass.class_eval do
    #     define_method(property_name) do |array|
    #       raise(ArgumentError, "Argument #{array} must be one of [\"#{allowed_values.join('","')}\"]", caller) unless allowed_values?(array, allowed_values)
    #       raise(ArgumentError, "Array elements must be of class #{array_class}", caller) if array_class != 'Json' &&
    #                                                                                         array.map { |e| e.class.to_s }.compact != array_class

    #       property_obj = klass.new(array)

    #       case object_type
    #       when :properties
    #         @Properties ||= {}
    #         @Properties[property_name] = property_obj
    #       when :instance
    #         instance_variable_set(:"@#{property_name}", property_obj)
    #       else
    #         raise("Unknown object type #{object_type}")
    #       end

    #       property_obj
    #     end
    #   end
    # end

    # # TODO: Deal with
    # # - required
    # def self.define_number_method(property_name, property, options)
    #   klass = Class.new(Types::Number)

    #   # parent_klass.const_set(property_name, klass)

    #   eval_klass = options[:klass] || self
    #   object_type = options[:object_type] || :instance

    #   allowed_values = property['allowed-values']

    #   eval_klass.class_eval do
    #     define_method(property_name) do |number|
    #       raise(ArgumentError, "Argument #{string} must be one of [\"#{allowed_values.join('","')}\"]", caller) unless allowed_values?(string, allowed_values)
    #       raise(ArgumentError, 'Argument must be a number', caller) unless number.is_a?(Integer)

    #       property_obj = klass.new(number)

    #       case object_type
    #       when :properties
    #         @Properties ||= {}
    #         @Properties[property_name] = property_obj
    #       when :instance
    #         instance_variable_set(:"@#{property_name}", property_obj)
    #       else
    #         raise("Unknown object type #{object_type}")
    #       end

    #       property_obj
    #     end
    #   end
    # end

    # # TODO: Deal with
    # # - required
    # def self.define_boolean_method(property_name, _property, options = {})
    #   klass = Class.new(Types::Boolean)

    #   eval_klass = options[:klass] || self
    #   object_type = options[:object_type] || :instance

    #   # parent_klass.const_set(property_name, klass)

    #   eval_klass.class_eval do
    #     define_method(property_name) do |boolean|
    #       raise(ArgumentError, 'Argument must be a boolean', caller) unless boolean.is_a?(TrueClass) || boolean.is_a?(FalseClass)

    #       property_obj = klass.new(boolean)

    #       case object_type
    #       when :properties
    #         @Properties ||= {}
    #         @Properties[property_name] = property_obj
    #       when :instance
    #         instance_variable_set(:"@#{property_name}", property_obj)
    #       else
    #         raise("Unknown object type #{object_type}")
    #       end

    #       property_obj
    #     end
    #   end
    # end

    # # TODO: Implement these
    # # - Mappings
    # # - Metadata
    # # - Conditions
    # # - Outputs
    # def self.create_resources
    #   root_resources['child-schemas'].each do |resource_name, resource|
    #     define_resource_method(resource_name, resource)
    #   end
    # end

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
          Fn.new(function_name, args)
        end
      end

      raise("Didn't process properties #{property.keys}") unless property.empty?
    end

    create_properties(root, self)
    create_functions
    # create_resources
  end
end
