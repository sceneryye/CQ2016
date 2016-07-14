#encoding:utf-8
class ValidationMailer < ActionMailer::Base
  default from: "CQ2016<cs@iotps.com>"


  def verify_email(user)
  	@user = user
  	site  = "http://www.cq2016.cc/"
  	site  = "http://www.cq2016.cc/" if Rails.env == "production"
  	@verify_email_url = "#{site}/validation/verify_email?u=#{user.member_id}&token=#{user.email_code}"
  	mail(:to => user.email, :subject => "昌麒投资茶验证邮件")
  end


end
