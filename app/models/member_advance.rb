class MemberAdvance < ActiveRecord::Base
	self.table_name = "member_advance"
	belongs_to :user,:foreign_key=>"member_id"


	def logged_at
		Time.at(mtime).strftime("%Y-%m-%d %H:%M:%S")
	end
end