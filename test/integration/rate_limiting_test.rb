require "test_helper"

class RateLimitingTest < ActionDispatch::IntegrationTest
  setup do
    Rails.cache.clear
    Rails.configuration.x.jwt.issuer = "bad-passwords-test"
    JwtIssuer.reset_keys!

    password = "test123"
    password_hash = Argon2::Password.create(password)
    User.create!(email: "user@example.com", password_hash_url: "https://example.com/hash.txt")
    stub_request(:get, "https://example.com/hash.txt").to_return(status: 200, body: password_hash)
  end

  test "returns 429 for html requests after the per-ip limit is exceeded" do
    60.times do
      get "/"
      assert_response :success
    end

    get "/"

    assert_response :too_many_requests
    assert_equal "Too many requests.", response.body
  end

  test "returns 429 json for api requests after the per-ip limit is exceeded" do
    60.times do
      post "/login", params: { email: "user@example.com", password: "test123" }, as: :json
      assert_response :success
    end

    post "/login", params: { email: "user@example.com", password: "test123" }, as: :json

    assert_response :too_many_requests
    assert_equal "Too many requests.", JSON.parse(response.body)["error"]
  end
end
