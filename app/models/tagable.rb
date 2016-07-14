class Tagable < ActiveRecord::Base
	self.table_name = "sdb_desktop_tag_rel"
	

	belongs_to :teg, :foreign_key=>"tag_id"

	belongs_to :good,->{where(["sdb_desktop_tag_rel.tag_type = ?","goods"])}, :foreign_key=>"rel_id"
	belongs_to :order,->{where(["sdb_desktop_tag_rel.tag_type = ?","orders"])}, :foreign_key=>"rel_id"
	belongs_to :user,->{where(["sdb_desktop_tag_rel.tag_type = ?","members"])}, :foreign_key=>"rel_id"
	
end