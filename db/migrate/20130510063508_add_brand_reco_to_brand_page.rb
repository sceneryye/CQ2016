class AddBrandRecoToBrandPage < ActiveRecord::Migration
  def change
    add_column :sdb_b2c_brand_pages, :brand_reco, :text
  end
  
  def connection
  	@connection = Base.connection
  end

end
