require "test_helper"

class LoginFlowTest < ActionDispatch::IntegrationTest
  setup do
    Rails.configuration.x.jwt.issuer = "bad-passwords-local"
    JwtIssuer.reset_keys!
    @password = "correct horse battery staple"
    @hash = Argon2::Password.create(@password)
    User.create!(email: "user@example.com", password_hash_url: "https://example.com/hash.txt")
    stub_request(:get, "https://example.com/hash.txt").to_return(status: 200, body: @hash)
    stub_request(:get, "https://example.com/not-hash.txt").to_return(status: 200, body: "not-an-argon-hash")
    stub_request(:get, "https://example.com/missing.txt").to_return(status: 404, body: "")
  end

  test "returns JSON token data for a successful login" do
    Rails.configuration.x.jwt.issuer = "bad-passwords-test"

    post "/login", params: { email: "user@example.com", password: @password }, as: :json

    assert_response :success
    body = JSON.parse(response.body)

    assert_equal "Bearer", body["token_type"]
    assert_equal "user@example.com", body["email"]

    payload = JwtIssuer.decode(body["token"])
    assert_equal "user@example.com", payload["sub"]
    assert_equal "bad-passwords-test", payload["iss"]
    assert_equal User.find_by(email: "user@example.com").current_token_version, payload["ver"]
    assert_operator payload["exp"], :>, payload["iat"]
  end

  test "uses the default issuer from test environment config" do
    assert_equal "bad-passwords-local", Rails.configuration.x.jwt.issuer

    post "/login", params: { email: "user@example.com", password: @password }, as: :json

    assert_response :success
    payload = JwtIssuer.decode(JSON.parse(response.body)["token"])

    assert_equal "bad-passwords-local", payload["iss"]
  end

  test "renders the HTML result page with token details" do
    Rails.configuration.x.jwt.issuer = "bad-passwords-test"

    post "/login", params: { email: "user@example.com", password: @password }

    assert_response :success
    assert_match JwtIssuer.public_key.to_pem, response.body
    assert_match "Login succeeded.", response.body
    assert_match "Decoded Token", response.body
    assert_match "user@example.com", response.body
    assert_match "bad-passwords-test", response.body
  end

  test "rejects an unknown email" do
    post "/login", params: { email: "missing@example.com", password: @password }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Invalid email or password.", JSON.parse(response.body)["error"]
  end

  test "rejects an incorrect password" do
    post "/login", params: { email: "user@example.com", password: "wrong password" }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Invalid email or password.", JSON.parse(response.body)["error"]
  end

  test "redirects html login failures back to the home page" do
    post "/login", params: { email: "user@example.com", password: "wrong password" }

    assert_response :unprocessable_entity
    assert_match "Invalid email or password.", response.body
  end

  test "rotates token version from the html login fieldset flow" do
    old_version = User.find_by(email: "user@example.com").current_token_version

    delete "/logout", params: { email: "user@example.com", password: @password }

    assert_redirected_to "/"

    follow_redirect!
    assert_response :success
    assert_match "Logout succeeded. Existing tokens revoked.", response.body

    assert_not_equal old_version, User.find_by(email: "user@example.com").current_token_version
  end

  test "rejects unreachable remote hashes" do
    User.last.update!(password_hash_url: "https://example.com/missing.txt")

    post "/login", params: { email: "user@example.com", password: @password }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Could not verify the password hash URL.", JSON.parse(response.body)["error"]
  end

  test "rejects invalid remote hash content" do
    User.last.update!(password_hash_url: "https://example.com/not-hash.txt")

    post "/login", params: { email: "user@example.com", password: @password }, as: :json

    assert_response :unprocessable_entity
    assert_equal "Could not verify the password hash URL.", JSON.parse(response.body)["error"]
  end
end
