module CfnDsl
  # DSL Checks
  module Checks
    def perform_checks
      return if ignored_class?

      check_required

      instance_variables.each do |instance_variable|
        next if instance_variable =~ /^@_/

        variable = instance_variable_get(instance_variable)

        case variable
        when Hash
          variable.values.each do |value|
            value.perform_checks if value.respond_to?(:perform_checks)
          end
        else
          variable.perform_checks if variable.respond_to?(:perform_checks)
        end
      end
    end

    def ignored_class?
      self.class.to_s !~ /^CfnDsl/
    end

    def check_required
      return unless self.class.required

      missing = self.class.required - instance_variables.map { |i| i.to_s.sub(/^@/, '') }

      return if missing.empty?

      missing.each do |name|
        Errors.error("#{name} is required", _kaller)
      end
    end
  end
end
