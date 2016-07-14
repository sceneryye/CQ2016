#encoding:utf-8
class Spec < ActiveRecord::Base
	self.table_name = "sdb_b2c_specification"
	self.primary_key = "spec_id"
	

	has_many :spec_values,:foreign_key=>"spec_id", :class_name=>"SpecValue"
	accepts_nested_attributes_for :spec_values, allow_destroy: true


	validates_presence_of :spec_name, :message=>"规格名称不能为空"


	def memo_name
		"#{spec_name}[#{spec_memo}]"
	end
	
	

end