class CreateOrders < ActiveRecord::Migration[7.1]
  def up
    create_enum :order_status, %w[pending processed cancelled]

    create_table :orders do |t|
      t.integer :product_id
      t.integer :quantity
      t.enum :current_status, enum_type: "order_status", default: "pending", null: false

      t.timestamps
    end
  end

  def down
    drop_table :orders
  end
end
