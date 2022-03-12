module Test
  module DB
    module Helpers
      module_function

      def relations
        rom.relations
      end

      def rom
        Hanami.application["persistence.rom"]
      end

      def db
        Hanami.application["persistence.db"]
      end
    end

    class FactoryHelper < Module
      attr_reader :type

      def initialize(type = nil)
        @type = type

        factory = entity_namespace ? Factory.struct_namespace(entity_namespace) : Factory

        define_method(:factory) do
          factory
        end
      end

      def entity_namespace
        @entity_namespace ||=
          begin
            case type
            when :main
              Main::Entities
            else
              Ecommerce::Entities
            end
          end
      end
    end
  end
end
