require 'test_helper'

class OrderTypesControllerTest < ActionController::TestCase
  setup do
    @order_type = order_types(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:order_types)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create order_type" do
    assert_difference('OrderType.count') do
      post :create, order_type: {  }
    end

    assert_redirected_to order_type_path(assigns(:order_type))
  end

  test "should show order_type" do
    get :show, id: @order_type
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @order_type
    assert_response :success
  end

  test "should update order_type" do
    patch :update, id: @order_type, order_type: {  }
    assert_redirected_to order_type_path(assigns(:order_type))
  end

  test "should destroy order_type" do
    assert_difference('OrderType.count', -1) do
      delete :destroy, id: @order_type
    end

    assert_redirected_to order_types_path
  end
end
