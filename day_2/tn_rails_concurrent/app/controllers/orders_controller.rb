class OrdersController < ApplicationController
  def top_products_report
    top10 = Product.order(orders_count: :desc).limit(10).pluck(:id, :created_at, :orders_count)

    top_products = []

    top10.each do |product|
      product_hash = { date: product[1].strftime('%d-%m-%Y'), product_id: product[0], total_quantity: product[2] }
      top_products << product_hash
    end

    render json: top_products
  end
end
