class Bill < ActiveRecord::Base
	self.table_name = 'sdb_ectools_order_bills'
	

	belongs_to :payment, :foreign_key => "bill_id"
	belongs_to :refund, :foreign_key=>"bill_id"

	belongs_to :order, :foreign_key=>"rel_id",:class_name=>"Order"

end