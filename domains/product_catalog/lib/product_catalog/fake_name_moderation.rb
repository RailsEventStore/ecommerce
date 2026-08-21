module ProductCatalog

  class FakeNameModeration
    def allowed?(name)
      !name.downcase.include?("curse")
    end
  end
end
