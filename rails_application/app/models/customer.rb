class Customer < ApplicationRecord
  has_many :orders

  def full_name
    "#{first_name} #{last_name}"
  end

  def promote_to_vip
    raise AlreadyVip if vip
    update!(vip: true)
  end
end
