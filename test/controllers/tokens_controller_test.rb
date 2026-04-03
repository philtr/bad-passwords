require "test_helper"

class TokensControllerTest < ActiveSupport::TestCase
  test "new loads validation results from flash" do
    controller = TokensController.new
    flash_hash = ActionDispatch::Flash::FlashHash.new
    flash_hash[:validation_result] = {
      "success" => true,
      "message" => "Token is valid.",
      "token" => "abc"
    }

    controller.define_singleton_method(:flash) { flash_hash }
    controller.send(:new)

    assert_equal "", controller.instance_variable_get(:@token)
    assert_equal(
      { success: true, message: "Token is valid.", token: "abc" },
      controller.instance_variable_get(:@validation_result)
    )
  end
end
