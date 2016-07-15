class Dlycorp < ActiveRecord::Base
	self.table_name = 'sdb_b2c_dlycorp'
	has_many :delivery, :foreign_key=>"logi_id"

end
