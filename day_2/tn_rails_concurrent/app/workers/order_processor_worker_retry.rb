class OrderProcessorWorkerRetry
  include Sidekiq::Worker
  # sidekiq_options retry: 5
  sidekiq_options queue: :orders,
                  retry: 5,
                  backtrace: true,
                  failures: :exhausted # gem 'sidekiq-failures'
  # Sidekiq::Failures.count
  # Sidekiq::Failures.clear_failures
  # config.failures_max_count = 1000

  # deanpcmad/sidekiq-limit_fetch
  # :queues:
  #   - priority_payment # update payments paid/cancelled/refund
  #   - ofd
  #   - low
  #   - default
  # :blocking:
  #   - priority_payment
  # Sidekiq::Queue['orders'].pause # .unpause

  # gem 'sidekiq-scheduler'
  # config/sidekiq.yml
  # :scheduler:
  #   :schedule:
  #     order_updated:
  #       cron: '0 * * * * *'   # Runs once per minute
  #       class: OrderProcessorWorker
  def perform(order_ids)
    orders = Order.find(order_ids)
    failed_orders = []

    orders.each do |order|
      process_order(order)
    rescue StandardError => e
      failed_orders << order.id
      Rails.logger.error("Failed to process order #{order.id}: #{e.message}")
    end

    retry_failed_orders(failed_orders) if failed_orders.any?
  end

  private

  def process_order(order)
    raise "Simulated failure" if order.id % 10 == 0 # Simulate failure for specific orders
    sleep(1)
    order.update!(status: "processed")
    Rails.logger.info("Processed Order ##{order.id}")
  end

  def retry_failed_orders(failed_order_ids)
    self.class.perform_async(failed_order_ids)
  end
end

#  Sidekiq::Queue['orders'].pause
#  Products.in_batches(of: 50, use_range: true) { |p| p.update stock: 50 }