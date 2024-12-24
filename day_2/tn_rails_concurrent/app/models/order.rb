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
class Order < ApplicationRecord
  belongs_to :product, counter_cache: true

  scope :pending, -> { where(current_status: :pending) }
  scope :processed, -> { where(current_status: :processed) }
  scope :cancelled, -> { where(current_status: :cancelled) }

  def process!
    sleep(1)
    update!(current_status: :processed)
    Rails.logger.info("Processed Order ##{id}")
  end

  def self.process!(locked: true)
    transaction do
      sleep(1)
      if locked
        with_lock { update!(current_status: :processed) }
        Rails.logger.info("Processed Order with lock ##{id}")
      else
        update!(current_status: :processed)
        Rails.logger.info("Processed Order ##{id}")
      end
    end
  end

  def process_with_product!(locked: true)
    transaction do
      sleep(1)
      update!(current_status: :processed)
      product = Product.find(product_id)
      product.update! stock: product.stock - 1
      Rails.logger.info("Processed Order ##{id}")
    end
  end

  def self.process!(ids)
    transaction do
      where(id: ids).in_batches(of: 50, use_ranges: true) do |batch|
        batch.update_all current_status: :processed
      end
    end
  end

  # Order.transaction do
  #   # select * from accounts where name = 'first' limit 1 for update nowait
  #   first = Order.lock("FOR UPDATE NOWAIT").find_by(product_id: 1)
  #   second = Order.lock("FOR UPDATE NOWAIT").find_by(product_id: 2)
  #   # first = Order.find_by(product_id: 1)
  #   # first.lock
  #   first.quantity -= 100
  #   first.save!
  #   second.quantity += 100
  #   second.save!
  # end
end
