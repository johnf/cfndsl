require 'cfndsl/errors'
# require 'cfndsl/ref_check'
require 'cfndsl/json_serialisable_object'
require 'cfndsl/checks'

module CfnDsl
  # This is the base class for just about everything useful in the
  # DSL. It knows how to turn DSL Objects into the corresponding
  # json, and it lets you create new built in function objects
  # from inside the context of a dsl object.
  class JSONable
    include Checks
    # include Functions
    # extend Functions

    class << self
      attr_accessor :required
    end

    attr_reader :_kaller

    def initialize
      @_kaller = caller
    end

    # Use instance variables to build a json object. Instance
    # variables that begin with a single underscore are elided.
    # Instance variables that begin with two underscores have one of
    # them removed.
    def as_json(_options = {})
      hash = {}
      instance_variables.each do |var|
        name = var[1..-1]

        if name =~ /^__/
          # if a variable starts with double underscore, strip one off
          name = name[1..-1]
        elsif name =~ /^_/
          # Hide variables that start with single underscore
          name = nil
        elsif name =~ /^Fn_/
          name = name.sub(/^Fn_/, 'Fn::')
        end

        hash[name] = instance_variable_get(var) if name
      end

      hash
    end

    def to_json(*a)
      as_json.to_json(*a)
    end

    # def ref_children
    #   instance_variables.map { |var| instance_variable_get(var) }
    # end

    def declare(&block)
      instance_eval(&block) if block_given?
    end

    def method_missing(meth, *args, &_block)
      error = "Undefined symbol or method: #{meth}"
      error = "#{error}(" + args.inspect[1..-2] + ')' unless args.empty?
      CfnDsl::Errors.error(error, caller)
    end

    def allowed_values?(value, allowed_values)
      return true unless allowed_values

      return true if allowed_values.include?('*')

      return true if allowed_values.include?(value)

      false
    end

    def self.add_required(name)
      @required ||= []
      @required << name
    end

    def self.add_description(name, description)
      @description ||= {}
      @description[name] = description
    end
  end
end
