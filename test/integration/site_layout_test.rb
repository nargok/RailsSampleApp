require 'test_helper'

class SiteLayoutTest < ActionDispatch::IntegrationTest

  test "layout_links" do
    # root_urlにgetリクエストを送る
    get root_path
    # 正しいページテンプレートが描画されているか確かめる
    assert_template 'static_pages/home'
    # Home, Help, About, Contactの各ページへのリンクが正しく動くか確かめる
    assert_select "a[href=?]", root_path, count:2
    assert_select "a[href=?]", help_path
    assert_select "a[href=?]", about_path
    assert_select "a[href=?]", contact_path
    get contact_path
    assert_select "title", full_title("Contact")
    get signup_path
    assert_template 'users/new'
    assert_select "title", full_title("Sign up")
  end

end
