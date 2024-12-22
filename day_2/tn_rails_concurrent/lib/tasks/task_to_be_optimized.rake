require 'net/http'
require 'uri'
require 'json'

namespace :orders do
  desc "Process orders with an HTTP request"
  task to_be_optimized: :environment do
    require 'benchmark'

    Order.destroy_all
    data = Array.new(200) { { product_id: rand(1..100), quantity: rand(1..10), current_status: :pending } }
    Order.import!(data)

    time = Benchmark.realtime do
      puts pending_orders.count

      batches = pending_orders.find_in_batches(batch_size: 50)
      results = Parallel.flat_map(batches, in_threads: batches.size) do |batch|
        process_batch_with_http(batch)
      end

      result = Order.import!(results, options)
      result.ids.each { |order_id| puts "Successfully processed Order ##{order_id}" }
    end

    puts "Processed orders in #{time.round(2)} seconds with HTTP request"
  end

  def process_batch_with_http(batch)
    Parallel.map(batch, in_threads: batch.size) do |order|
      response = send_to_external_service
      if response.code.to_i == 200
        { id: order.id, current_status: :processed }
      else
        raise "Failed to process Order ##{order.id}: #{response.body}"
      end
    end
  rescue StandardError => e
    Rails.logger.error("Error processing Orders #{e.message}")
  end

  def options
    {
      on_duplicate_key_update: {
        conflict_target: [:id],
        columns:         [:current_status],
      },
    }
  end

  def pending_orders
    @pending_orders ||= Order.pending
  end

  def send_to_external_service
    uri = URI.parse("https://yandex.ru")
    sleep 0.1
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true if uri.scheme == 'https'

    request = Net::HTTP::Post.new(uri.path, { 'Content-Type' => 'application/json' })
    http.request(request)
  end
end
