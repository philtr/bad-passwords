require "test_helper"

class SessionsControllerTest < ActiveSupport::TestCase
  test "returns the verifier message for non-infrastructure login failures" do
    controller = SessionsController.new
    verification = RemotePasswordVerifier::Result.new(status: :other_failure, message: "Custom verifier failure")

    assert_equal "Custom verifier failure", controller.send(:login_error_message, verification)
  end
end
