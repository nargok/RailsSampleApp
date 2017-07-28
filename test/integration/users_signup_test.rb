require 'test_helper'

class UsersSignupTest < ActionDispatch::IntegrationTest

  test "invalid signup information" do
    get signup_path
    # assert_no_differenceのブロックを実行する前後で引数の値 (User.count) が変わらないことをテストする
    assert_no_difference 'User.count' do
      post users_path, params: { user: { name: "",
                            email: "user@invalid",
                            password: "foo",
                            password_confirmation: "bar"}}
    end
    assert_template 'users/new'
    assert_select 'div#error_explanation'
    assert_select 'div.alert-danger'
    # assert_select 'div.alert-danger', "Password confirmation doesn't match Password"
    # assert_select 'div.alert-danger', "Password is too short (minimum is 6 characters)"
  end

  test "valid signup information" do
    get signup_path
    assert_difference 'User.count', 1 do
      post users_path, params: { user: { name: "Example User",
                          email: "user@example.com",
                          password: "password",
                          password_confirmation: "password"}}
    end
    follow_redirect!
    assert_template "users/show"
    assert_not flash.blank?
    assert is_logged_in?
  end

end
