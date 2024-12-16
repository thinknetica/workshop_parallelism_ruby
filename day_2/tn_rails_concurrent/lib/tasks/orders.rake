namespace :orders do
  desc "Simulate database deadlock"
  task deadlock: :environment do
    order1 = Order.create!(product_id: 1, quantity: 1, current_status: 'pending')
    order2 = Order.create!(product_id: 2, quantity: 1, current_status: 'pending')

    threads = []

    threads << Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction do
          puts "Thread 1 locking Order 1"
          order1.lock!
          sleep(2)
          puts "Thread 1 trying to lock Order 2"
          order2.lock!
          puts "Thread 1 locked both orders"
        end
      end
    end

    threads << Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction do
          puts "Thread 2 locking Order 2"
          order2.lock!
          sleep(2)
          puts "Thread 2 trying to lock Order 1"
          order1.lock!
          puts "Thread 2 locked both orders"
        end
      end
    end

    threads.each(&:join)
  end

  desc "Simulate read_committed read"
  task non_repeatable_read: :environment do
    order = Order.create!(product_id: 1, quantity: 1, current_status: 'pending')

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction do
          sleep(2) # Wait for Transaction 2 to start
          order.update!(quantity: 99)
          puts "Transaction 1 updated quantity to 99: #{order.reload.quantity}"
        end
      end
    end

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction(isolation: :read_committed) do
          puts "Transaction 2 reads quantity: #{order.reload.quantity} should be 1"
          sleep(5) # Simulate delay
          puts "Transaction 2 re-reads quantity: #{order.reload.quantity}"
        end
      end
    end.join
  end

  desc "Simulate dirty read"
  task dirty_read: :environment do
    order = Order.create!(product_id: 1, quantity: 1, current_status: 'pending')

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction do
          order.update!(quantity: 99)
          sleep(5) # Simulate delay before commit
          puts "Transaction 1 committed quantity: #{order.reload.quantity}"
        end
      end
    end

    Thread.new do
      ActiveRecord::Base.connection_pool.with_connection do
        ActiveRecord::Base.transaction(isolation: :read_uncommitted) do
          sleep(1) # Wait for Transaction 1 to start
          puts "Transaction 2 reads quantity: #{order.reload.quantity} (uncommitted)"
        end
      end
    end.join
  end

  desc "Process orders concurrently using threads"
  task in_thread: :environment do
    threads = []
    Order.pending.find_each do |order|
      threads << Thread.new do
        order.process!
      end
    end
    threads.each(&:join)
  end

  desc "Process orders in parallel using the 'parallel' gem"
  task parallel: :environment do
    Parallel.each(Order.pending, in_processes: 4) do |order|
      order.process!
    end
  end

  desc "Process orders async with 'sidekiq' gem"
  task async: :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    Order.pending.in_batches(of: 20) do |orders|
      puts "Processing #{orders.size} ids: #{orders.map(&:id).join(',')}"
      OrderProcessorWorker.perform_async(orders.map(&:id))
    end
  end

  desc "Process orders in_batches without range option"
  task sync_noranges: :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    Order.pending.in_batches(of: 20, use_ranges: false) do |orders|
      puts "Processing #{orders.size} ids: #{orders.map(&:id).join(',')}"
      orders.each { |order| order.process! }
    end
  end

  desc "Process orders in_batches with range option"
  task sync_ranges: :environment do
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    Order.pending.in_batches(of: 20, use_ranges: true) do |orders|
      puts "Processing #{orders.size} ids: #{orders.map(&:id).join(',')}"
      orders.each { |order| order.process! }
    end
  end

  desc "Process orders using Ractors"
  task ractors: :environment do
    orders = Order.pending
    ractor = Ractor.new(orders.to_a) do |orders_batch|
      orders_batch.each do |order|
        order.process!
      end
    end
    ractor.take
  end

  desc "Process orders using fibers"
  task fibers: :environment do
    fibers = []
    Order.pending.find_each do |order|
      fibers << Fiber.new { order.process! }
    end
    fibers.each(&:resume)
  end

  desc "Simulate race condition"
  task race_condition: :environment do
    order = Order.create!(product_id: 1, quantity: 1, current_status: 'pending')
    threads = []

    2.times do |i|
      threads << Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          ActiveRecord::Base.transaction do
            puts "Thread #{i} reading order quantity: #{order.reload.quantity} #{order.quantity}"
            sleep(5) # Simulate delay before writing
            order.update!(quantity: order.quantity + 1)
            puts "Thread #{i} updated order quantity to: #{order.reload.quantity} #{order.quantity}"
          end
        end
      end
    end

    threads.each(&:join)

    puts "Final order quantity: #{order.reload.quantity} #{order.quantity}"
  end
end
