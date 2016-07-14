class TagExt < ActiveRecord::Base
	self.table_name = "sdb_desktop_tag_ext"
	belongs_to :tag, :foreign_key=>"tag_id", :class_name=>"TagName"

	attr_accessor :tag_id,:tag_name,:deadline,:cover_url,:issue_no,:title,:disabled

	
end