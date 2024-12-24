require 'net/http'
require 'uri'
require 'json'

namespace :orders do
  desc "Process orders with an HTTP request"
  task to_be_optimized: :environment do
    require 'benchmark'

    Order.delete_all

    orders = Array.new(200) do
      {
        product_id: rand(1..100),
        quantity: rand(1..10),
        current_status: :pending
      }
    end

    Order.insert_all(orders)

    time = Benchmark.realtime do
      size_orders = Order.pending.size
      puts size_orders
      threads = []

      Order.pending.in_batches(of: size_orders / 4, use_ranges: true) do |batch|
        threads << Thread.new do
          process_batch_with_http(batch)
        end
      end
      threads.each(&:join)
    end

    puts "Processed orders in #{time.round(2)} seconds with HTTP request"
  end

  def process_batch_with_http(batch)
    threads = []
      batch.each do |order|
        threads << Thread.new do

        response = send_to_external_service
        if response.code.to_i == 200
          order.process!
          puts "Successfully processed Order ##{order.id}"
        else
          raise "Failed to process Order ##{order.id}: #{response.body}"
        end
      rescue StandardError => e
        Rails.logger.error("Error processing Order ##{order.id}: #{e.message}")
      end
    end

    threads.each(&:join)
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
