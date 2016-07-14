#encoding:utf-8
class Label < ActiveRecord::Base
	self.table_name = "sdb_imodec_labels"

	validates_presence_of :name,:message=>"名称不能为空"
end