class OrderProcessorWorker
  include Sidekiq::Worker
  sidekiq_options retry: 5

  def perform(order_ids)
    failed_ids = []
    Order.find_in_batches(order_ids) do |orders|
      orders.each do |order|
        order.process!
      rescue StandardError => e
        failed_ids << order.id
      end
    end
  rescue StandardError => e
    Rails.logger.error("Failed to process order #{order.id}: #{e.message}")

    OrderProcessorWorkerRetry.new.perform(failed_ids)
    # notify failed_ids.join(',')
  end
end
