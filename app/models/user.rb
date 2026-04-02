class User < ApplicationRecord
  validates :email, presence: true, uniqueness: true
  validates :password_hash_url, presence: true
end
