class AddTypeToStaticPages < ActiveRecord::Migration
  def change
    add_column :sdb_imodec_static_pages, :type, :string
  end
  def connection
  	@connection = Base.connection
  end
end
