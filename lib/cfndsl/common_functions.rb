module CfnDsl
  # Common Functions
  module CommonFunctions
    # Usage
    #  FnFormat('This is a %0. It is 100%% %1', 'test', 'effective')
    # or
    #  FnFormat('This is a %{test}. It is 100%% %{effective}',
    #            :test => 'test",
    #            :effective => 'effective')
    #
    # These will each generate a call to Fn::Join that when
    # evaluated will produce the string "This is a test. It is 100%
    # effective."
    #
    # Think of this as %0, %1, etc in the format string being replaced by the
    # corresponding arguments given after the format string. '%%' is replaced
    # by the '%' character.
    #
    # The actual Fn::Join call corresponding to the above FnFormat call would be
    # {"Fn::Join": ["",["This is a ","test",". It is 100","%"," ","effective"]]}
    #
    # If no arguments are given, or if a hash is given and the format
    # variable name does not exist in the hash, it is used as a Ref
    # to an existing resource or parameter.
    #
    # TODO Can we simplyfy this somehow?
    # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
    def FnFormat(string, *arguments)
      array = []

      if arguments.empty? || (arguments.length == 1 && arguments[0].instance_of?(Hash))
        hash = arguments[0] || {}
        string.scan(/(.*?)(?:%(%|\{([\w:]+)\})|\z)/m) do |x, y, z|
          array.push x if x && !x.empty?

          next unless y

          array.push(y == '%' ? '%' : (hash[z] || hash[z.to_sym] || Ref(z)))
        end
      else
        string.scan(/(.*?)(?:%(%|\d+)|\z)/m) do |x, y|
          array.push x if x && !x.empty?

          next unless y

          array.push(y == '%' ? '%' : arguments[y.to_i])
        end
      end
      Fn.new('Join', ['', array])
    end
    # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
  end

  # Condition Functions
  module ConditionFunctions
    # Equivalent to the CloudFormation template built in function Fn::And
    def FnAnd(array)
      if !array || array.count < 2 || array.count > 10
        raise 'The array passed to Fn::And must have at least 2 elements and no more than 10'
      end
      Fn.new('And', array)
    end

    # Equivalent to the Cloudformation template built in function Fn::Equals
    def FnEquals(value1, value2)
      Fn.new('Equals', [value1, value2])
    end

    # Equivalent to the Cloudformation template built in function Fn::If
    def FnIf(condition_name, true_value, false_value)
      Fn.new('If', [condition_name, true_value, false_value])
    end

    # Equivalent to the Cloudformation template built in function Fn::Not
    def FnNot(value)
      Fn.new('Not', value)
    end

    # Equivalent to the CloudFormation template built in function Fn::Or
    def FnOr(array)
      if !array || array.count < 2 || array.count > 10
        raise 'The array passed to Fn::Or must have at least 2 elements and no more than 10'
      end
      Fn.new('Or', array)
    end
  end

  # Handles all of the Fn:: objects
  class Fn < JSONable
    def initialize(function, argument) # , refs = [])
      @function = function
      @argument = argument
      # @_refs = refs
    end

    def as_json(_options = {})
      hash = {}
      hash["Fn::#{@function}"] = @argument
      hash
    end

    def to_json(*a)
      as_json.to_json(*a)
    end

    # def references
    #   @_refs
    # end

    # def ref_children
    #   [@argument]
    # end
  end

  # Handles the Ref objects
  class Ref < JSONable
    def initialize(value)
      @Ref = value
    end

    # def all_refs
    #   [@Ref]
    # end
  end
end
