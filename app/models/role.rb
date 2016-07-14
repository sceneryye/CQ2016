#encoding:utf-8
class Role < ActiveRecord::Base
  self.table_name = "sdb_desktop_roles"
  self.primary_key = 'role_id'
  

  has_many :hasrole, :foreign_key=>"role_id"

end