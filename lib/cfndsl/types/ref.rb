module CfnDsl
  module Types
    # Ref
    class Ref < JSONable
      def initialize(value)
        @Ref = value
      end

      # def all_refs
      #   [@Ref]
      # end
    end
  end
end
