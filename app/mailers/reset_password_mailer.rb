#encoding:utf-8
class ResetPasswordMailer < ActionMailer::Base
  default from: "昌麒投资茶<cs@iotps.com>"


  def reset_password_email(user)
  	@user = user
  	site  = "http://wwww.cq2016.cc/"
  	@reset_password_url = "#{site}/users/reset_password?u=#{@user.member_id}&token=#{@user.reset_password_token}"
  	mail(:to => user.email, :subject => "忘记密码")
  end

end
