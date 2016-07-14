class MemberLv < ActiveRecord::Base
	self.table_name = "sdb_b2c_member_lv"

	 has_many :users, :foreign_key=>"member_lv_id"

end