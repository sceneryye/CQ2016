class AddRecoToBrand < ActiveRecord::Migration

  def change
    add_column :sdb_b2c_brand, :reco, :boolean, :default=>false
  end

  def connection
  	@connection = Base.connection
  end

end
