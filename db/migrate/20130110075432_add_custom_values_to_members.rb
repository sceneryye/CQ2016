class AddCustomValuesToMembers < ActiveRecord::Migration
  
  def up
    add_column :sdb_b2c_members, :custom_values, :text
  end

  def down
  	remove_column :sdb_b2c_members, :custom_values
  end

  def connection
  	@connection = Base.connection
  end
  
end
