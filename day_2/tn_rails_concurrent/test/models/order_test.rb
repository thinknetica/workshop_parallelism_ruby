# == Schema Information
#
# Table name: orders
#
#  id             :bigint           not null, primary key
#  product_id     :integer
#  quantity       :integer
#  current_status :enum             default("pending"), not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class OrderTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
