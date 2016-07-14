class InventoryLog < ActiveRecord::Base

  belongs_to :product, :foreign_key=>"product_id"
  belongs_to :good, :foreign_key=>"goods_id"
  # belongs_to :order_item, :foreign_key=>"order_items_id"
  belongs_to :order,:foreign_key=>"order_id"

  def in_out_text
  	return '入库' if self.in_out == 1
  	return '出库' if self.in_out == -1
  end
  
end