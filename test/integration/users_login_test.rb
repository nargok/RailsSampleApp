require 'test_helper'

class UsersLoginTest < ActionDispatch::IntegrationTest

  def setup
    @user = users(:michael)
  end

  # ログイン用のパスを開く
  #  新しいセッションのフォームが正しく表示されたことを確認する
  #  わざと無効なparamsハッシュを使用してセッション用パスにPOSTする
  #  新しいセッションのフォームが再度表示され、フラッシュメッセージが追加されることを確認する
  #  別のページ (Homeページなど) にいったん移動する
  #  移動先のページでフラッシュメッセージが表示されていないことを確認する
  test "login with invalid information" do
    get login_path
    assert_template "sessions/new"
    post login_path, params: {session: { email: "", password: "" }}
    assert_template "sessions/new"
    assert_not flash.empty?
    get root_path
    assert flash.empty?
  end

  # ログイン用のパスを開く
  # セッション用パスに有効な情報をpostする
  # ログイン用リンクが表示されなくなったことを確認する
  # ログアウト用リンクが表示されていることを確認する
  # プロフィール用リンクが表示されていることを確認する
  test "login with valid information followed by logout" do
    get login_path
    post login_path, params: { session: { email: @user.email,
                                         password: 'password' }}
    assert_redirected_to @user # リダイレクト先が正しいかを確認する
    follow_redirect!           # リダイレクト先に移動する
    assert_template "users/show"
    assert_select "a[href=?]", login_path, count: 0 # ログインしたので、ログイン用のリンク先がないことを確認する
    assert_select "a[href=?]", logout_path
    assert_select "a[href=?]", user_path(@user)

    # ログアウト
    delete logout_path
    assert_not is_logged_in?
    assert_redirected_to root_path
    delete logout_path
    follow_redirect!
    assert_select "a[href=?]", login_path
    assert_select "a[href=?]", logout_path, count: 0
    assert_select "a[href=?]", user_path(@user), count: 0
  end

  test "login with remembering " do
    log_in_as(@user, remember_me: '1')
    assert_not_empty cookies['remember_token'] # テスト内ではcookiesにシンボルが使えない
  end

  test "login without rememberging" do
    # クッキーを保存してログイン
    log_in_as(@user, remember_me: '1')
    delete logout_path
    # クッキーを削除してログイン
    log_in_as(@user, remember_me: '0')
    assert_empty cookies['remember_token']
  end


end
