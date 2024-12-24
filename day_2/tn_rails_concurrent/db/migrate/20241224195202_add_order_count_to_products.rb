class AddOrderCountToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :orders_count, :integer
  end
end
