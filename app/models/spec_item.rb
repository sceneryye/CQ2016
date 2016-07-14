#encoding:utf-8
class SpecItem < ActiveRecord::Base
	self.table_name = 'sdb_b2c_spec_items'

	has_many :good_spec_items, :foreign_key=>"spec_item_id",:dependent=>:destroy
	validates_presence_of :name,:message=>"名称不能为空 !"
end