class AddStatusToBrand < ActiveRecord::Migration
  def change
    add_column :sdb_b2c_brand, :status, :string, :default=>"normal"
  end

  def connection
  	@connection = Base.connection
  end
end
