module Follows
  class Follow < ApplicationRecord
    self.table_name = "follows"
  end
  private_constant :Follow

  def self.followees_of(follower_id)
    Follow.where(follower_id: follower_id).pluck(:followee_id)
  end

  class AddFollow
    def call(event)
      Follow.create!(
        follower_id: event.data.fetch(:follower_id),
        followee_id: event.data.fetch(:followee_id)
      )
    end
  end

  class RemoveFollow
    def call(event)
      Follow.where(
        follower_id: event.data.fetch(:follower_id),
        followee_id: event.data.fetch(:followee_id)
      ).delete_all
    end
  end

  class Configuration
    def call(event_store)
      event_store.subscribe(AddFollow.new, to: [::Social::UserFollowed])
      event_store.subscribe(RemoveFollow.new, to: [::Social::UserUnfollowed])
    end
  end
end
