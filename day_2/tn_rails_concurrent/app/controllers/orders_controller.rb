class OrdersController < ApplicationController
  def top_products_report
    top_products = Order.all
    render json: top_products
  end
end
