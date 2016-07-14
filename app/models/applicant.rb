#encoding:utf-8
class Applicant < ActiveRecord::Base
  self.table_name = "sdb_imodec_applicants"
 
  validates_presence_of :name,:message=>"请填写姓名"
  validates_presence_of :mobile,:message=>"请填写手机"
  validates_presence_of :email,:message=>"请填写邮箱"
  
end
