class Supplier < ActiveRecord::Base
  #include WeixinRailsMiddleware::AutoGenerateWeixinTokenSecretKey
	self.table_name = "sdb_imodec_suppliers"


  has_many :goods, :foreign_key=>"supplier_id"
  has_many :pages, :foreign_key=>"supplier_id"
  belongs_to :user, :foreign_key=>"member_id"
  has_many :orderdining ,:foreign_key=>"supplier_id"
  has_many :homes ,:foreign_key=>"supplier_id"
  has_many :accounts, :foreign_key=>"supplier_id"
  has_many :commissions, :foreign_key=>"supplier_id"
  has_many :cart, :foreign_key =>"supplier_id"

end
