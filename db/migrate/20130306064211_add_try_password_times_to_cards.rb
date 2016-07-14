class AddTryPasswordTimesToCards < ActiveRecord::Migration
  def up
    	add_column :sdb_imodec_cards, :try_password_times, :integer,:default=>0
  end

  def down
  	remove_column :sdb_imodec_cards, :try_password_times
  end


  def connection
  	@connection =  Base.connection
  end
end
