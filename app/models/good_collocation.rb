class GoodCollocation < ActiveRecord::Base
  self.table_name = "sdb_b2c_goods_collocations"

  belongs_to :good, :foreign_key=>"goods_id"

  serialize :collocations, Array

  
end
