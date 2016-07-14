class AddTitleToTagExt < ActiveRecord::Migration
  def change
  	add_column :sdb_desktop_tag_ext,:title,:string
  end

  def connection
  	@connection =  Base.connection
  end
   
end
