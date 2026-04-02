require "test_helper"

class TestPasswordRouteTest < ActionDispatch::IntegrationTest
  test "returns a plaintext argon2 hash for test123" do
    get "/example.txt"

    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.headers["content-type"]
    assert Argon2::Password.verify_password("test123", response.body)
  end
end
