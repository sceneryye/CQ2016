class AddSuitsAndHotsToHome < ActiveRecord::Migration
  def change
    add_column :sdb_imodec_homes, :suits, :text
    add_column :sdb_imodec_homes, :hots, :text
  end
  
  def connection
  	@connection =  Base.connection
  end

end
