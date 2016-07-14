class ReshipItem < ActiveRecord::Base
	self.table_name = 'sdb_b2c_reship_items'
	
	
	belongs_to :reship, :foreign_key=>"reship_id"

	belongs_to :product, :foreign_key=>"product_id"

end