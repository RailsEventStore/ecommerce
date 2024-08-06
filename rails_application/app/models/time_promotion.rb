# frozen_string_literal: true

class TimePromotion < ApplicationRecord
  def self.current
    where("start_time < ? AND end_time > ?", Time.current, Time.current)
  end
end
