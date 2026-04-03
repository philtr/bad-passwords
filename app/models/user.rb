class User < ApplicationRecord
  has_one :token_version, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :password_hash_url, presence: true

  after_create :ensure_token_version!

  def current_token_version
    ensure_token_version!.token_version
  end

  def rotate_token_version!
    ensure_token_version!.rotate!
  end

  def ensure_token_version!
    token_version || create_token_version!
  end
end
