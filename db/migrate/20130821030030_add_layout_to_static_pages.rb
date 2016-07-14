class AddLayoutToStaticPages < ActiveRecord::Migration
  def up
   # add_column :sdb_imodec_static_pages, :layout, :string
    Page.update_all :layout=>"standard"
  end

  def down
   #  remove_column :sdb_imodec_static_pages, :layout
  end

  def connection
  	@connection = Base.connection
  end
  
end
