require 'test_helper'

class ModelsControllerTest < ActionController::TestCase
  test "should get orders" do
    get :orders
    assert_response :success
  end

  test "should get customers" do
    get :customers
    assert_response :success
  end

end
