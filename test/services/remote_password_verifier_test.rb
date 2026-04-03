require "test_helper"

class RemotePasswordVerifierTest < ActiveSupport::TestCase
  test "verifies a matching password against a remote argon hash" do
    password = "correct horse battery staple"
    password_hash = Argon2::Password.create(password)
    stub_request(:get, "https://example.com/hash.txt").to_return(status: 200, body: password_hash)

    result = RemotePasswordVerifier.new(password: password, password_hash_url: "https://example.com/hash.txt").call

    assert result.success?
    assert_equal :success, result.status
    assert_equal password_hash, result.password_hash
  end

  test "rejects invalid uri strings" do
    result = RemotePasswordVerifier.new(password: "secret", password_hash_url: "::not a uri::").call

    assert_not result.success?
    assert_equal :invalid_url, result.status
    assert_equal "Password hash URL is invalid.", result.message
  end

  test "rejects empty successful responses" do
    stub_request(:get, "https://example.com/empty.txt").to_return(status: 200, body: "")

    result = RemotePasswordVerifier.new(password: "secret", password_hash_url: "https://example.com/empty.txt").call

    assert_not result.success?
    assert_equal :invalid_hash, result.status
    assert_equal "Password hash URL did not return an Argon2 hash.", result.message
  end

  test "handles unexpected fetch errors" do
    singleton = Net::HTTP.singleton_class
    original = Net::HTTP.method(:get_response)

    singleton.define_method(:get_response) do |_uri|
      raise StandardError, "boom"
    end

    begin
      result = RemotePasswordVerifier.new(password: "secret", password_hash_url: "https://example.com/hash.txt").call

      assert_not result.success?
      assert_equal :fetch_error, result.status
      assert_equal "Could not fetch password hash URL.", result.message
    ensure
      singleton.define_method(:get_response, original)
    end
  end
end
