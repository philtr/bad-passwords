class TokenVersion < ApplicationRecord
  VERSION_LENGTH = 16
  VERSION_FORMAT = /\A[a-z0-9]{16}\z/

  belongs_to :user

  validates :token_version, presence: true, format: { with: VERSION_FORMAT }

  before_validation :assign_token_version, on: :create

  def rotate!
    update!(token_version: self.class.generate)
  end

  def self.generate
    SecureRandom.alphanumeric(VERSION_LENGTH).downcase
  end

  private

  def assign_token_version
    self.token_version ||= self.class.generate
  end
end
