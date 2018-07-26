require 'test_helper'

class ProjectionsControllerTest < ActionController::TestCase
  setup do
    @projection = projections(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:projections)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create projection" do
    assert_difference('Projection.count') do
      post :create, projection: { created_by: @projection.created_by, created_by_id: @projection.created_by_id, customer_id: @projection.customer_id, customer_name: @projection.customer_name, q_avgluc: @projection.q_avgluc, q_bottles: @projection.q_bottles, q_lines: @projection.q_lines, quarter: @projection.quarter, recent: @projection.recent, sale_name_name: @projection.sale_name_name, sale_rep_id: @projection.sale_rep_id }
    end

    assert_redirected_to projection_path(assigns(:projection))
  end

  test "should show projection" do
    get :show, id: @projection
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @projection
    assert_response :success
  end

  test "should update projection" do
    patch :update, id: @projection, projection: { created_by: @projection.created_by, created_by_id: @projection.created_by_id, customer_id: @projection.customer_id, customer_name: @projection.customer_name, q_avgluc: @projection.q_avgluc, q_bottles: @projection.q_bottles, q_lines: @projection.q_lines, quarter: @projection.quarter, recent: @projection.recent, sale_name_name: @projection.sale_name_name, sale_rep_id: @projection.sale_rep_id }
    assert_redirected_to projection_path(assigns(:projection))
  end

  test "should destroy projection" do
    assert_difference('Projection.count', -1) do
      delete :destroy, id: @projection
    end

    assert_redirected_to projections_path
  end
end
