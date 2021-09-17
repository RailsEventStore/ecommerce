module ProductCatalog
  module ProductRepositoryExamples
    def self.for(repository)
      Module.new do
        include TestMethods

        define_method :before_setup do
          super()
          @repository = repository.call
        end
      end
    end

    module TestMethods
      attr_reader :repository

      def test_find_non_existing
        refute repository.find(SecureRandom.uuid)
      end

      def test_upsert
        refute repository.upsert(Product.new(id: SecureRandom.uuid))
        refute_empty repository.all
      end

      def test_all
        repository.upsert(Product.new(id: id = SecureRandom.uuid))
        assert_equal_serialized [Product.new(id: id)], repository.all
      end

      def test_find_existing
        id = SecureRandom.uuid
        repository.upsert(customer = Product.new(id: id))
        assert_equal_serialized customer, repository.find(id)
      end

      def test_find_or_initialize_by_id
        id = SecureRandom.uuid
        assert_equal_serialized Product.new(id: id),
          repository.find_or_initialize_by_id(id)

        repository.upsert(Product.new(id: id, name: "Fake Name"))

        assert_equal_serialized Product.new(id: id, name: "Fake Name"),
          repository.find_or_initialize_by_id(id)
      end

      def assert_equal_serialized(expected, actual)
        assert_equal Array(expected).map(&:to_h), Array(actual).map(&:to_h)
      end
    end
  end
end
