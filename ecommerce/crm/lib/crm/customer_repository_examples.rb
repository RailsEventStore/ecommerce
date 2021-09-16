module Crm
  module CustomerRepositoryExamples
    def test_find_non_existing
      refute repository.find(SecureRandom.uuid)
    end

    def test_create
      refute repository.create(Customer.new(id: SecureRandom.uuid))
      refute_empty repository.all
    end

    def test_all
      repository.create(Customer.new(id: id = SecureRandom.uuid))
      assert_equal_serialized [Customer.new(id: id)], repository.all
    end

    def test_find_existing
      id = SecureRandom.uuid
      repository.create(customer = Customer.new(id: id))
      assert_equal_serialized customer, repository.find(id)
    end

    def test_find_or_initialize_by_id
      id = SecureRandom.uuid
      assert_equal_serialized Customer.new(id: id),
        repository.find_or_initialize_by_id(id)

      repository.create(Customer.new(id: id, name: "Fake Name"))

      assert_equal_serialized Customer.new(id: id, name: "Fake Name"),
        repository.find_or_initialize_by_id(id)
    end

    def assert_equal_serialized(expected, actual)
      assert_equal Array(expected).map(&:to_h), Array(actual).map(&:to_h)
    end
  end
end
