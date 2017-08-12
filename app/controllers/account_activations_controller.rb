class AccountActivationsController < ApplicationController

  def edit
    user = User.find_by(email: params[:email])
    # まだ有効になっていないユーザで、activation_tokenとactivation_digestの整合性がとれたとき
    # 対象ユーザを有効にする
    if user && !user.activated? && user.authenticated?(:activation, params[:id])
      user.activate
      log_in user
      flash[:success] = "Account activated!"
      redirect_to user
    else
      flash[:danger] = "Invalid activation link"
      redirect_to root_url
    end
  end

end
