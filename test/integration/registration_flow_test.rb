require "test_helper"

class RegistrationFlowTest < ActionDispatch::IntegrationTest
  setup do
    @password = "correct horse battery staple"
    @hash = Argon2::Password.create(@password)
    stub_request(:get, "https://example.com/hash.txt").to_return(status: 200, body: @hash)
    stub_request(:get, "https://example.com/not-hash.txt").to_return(status: 200, body: "not-an-argon-hash")
    stub_request(:get, "https://example.com/missing.txt").to_return(status: 404, body: "")
  end

  test "registers a user with a matching remote hash" do
    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/hash.txt", password: @password }

    assert_redirected_to "/"

    follow_redirect!
    assert_response :success
    assert_equal "user@example.com", User.last.email
    assert_match "Registration succeeded.", response.body
  end

  test "returns json for successful registration" do
    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/hash.txt", password: @password }, as: :json

    assert_response :created
    body = JSON.parse(response.body)

    assert_equal "user@example.com", body["email"]
    assert_equal "https://example.com/hash.txt", body["password_hash_url"]
  end

  test "rejects duplicate email addresses" do
    User.create!(email: "user@example.com", password_hash_url: "https://example.com/hash.txt")

    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/hash.txt", password: @password }

    assert_redirected_to "/"

    follow_redirect!
    assert_response :success
    assert_match "Email has already been taken", response.body
  end

  test "returns json errors for invalid registration" do
    User.create!(email: "user@example.com", password_hash_url: "https://example.com/hash.txt")

    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/hash.txt", password: @password }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Email has already been taken", JSON.parse(response.body)["error"]
  end

  test "rejects unreachable remote hashes" do
    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/missing.txt", password: @password }

    assert_redirected_to "/"

    follow_redirect!
    assert_response :success
    assert_match "Could not fetch password hash URL.", response.body
  end

  test "rejects invalid remote hash content" do
    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/not-hash.txt", password: @password }

    assert_redirected_to "/"

    follow_redirect!
    assert_response :success
    assert_match "did not return an Argon2 hash", response.body
  end

  test "rejects a password that does not match the remote hash" do
    post "/register", params: { email: "user@example.com", password_hash_url: "https://example.com/hash.txt", password: "wrong password" }

    assert_redirected_to "/"

    follow_redirect!
    assert_response :success
    assert_match "does not match the remote Argon2 hash", response.body
  end
end
