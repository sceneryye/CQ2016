class AddDetailDescToBrands < ActiveRecord::Migration
  def change
    #add_column :sdb_b2c_brand, :detail_desc, :text
  end

  def connection
  	@connection =  Base.connection
  end
end
