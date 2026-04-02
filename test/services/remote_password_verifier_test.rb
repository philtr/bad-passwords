require "test_helper"

class RemotePasswordVerifierTest < ActiveSupport::TestCase
  test "verifies a matching password against a remote argon hash" do
    password = "correct horse battery staple"
    password_hash = Argon2::Password.create(password)
    stub_request(:get, "https://example.com/hash.txt").to_return(status: 200, body: password_hash)

    result = RemotePasswordVerifier.new(password: password, password_hash_url: "https://example.com/hash.txt").call

    assert result.success?
    assert_equal password_hash, result.password_hash
  end

  test "rejects invalid uri strings" do
    result = RemotePasswordVerifier.new(password: "secret", password_hash_url: "::not a uri::").call

    assert_not result.success?
    assert_equal "Password hash URL is invalid.", result.message
  end
end
