class AddDisabledToTagExts < ActiveRecord::Migration
  def change
  	add_column :sdb_desktop_tag_ext,:disabled,:boolean,:default=>false
  end

  def connection
  	@connection =  Base.connection
  end

end
