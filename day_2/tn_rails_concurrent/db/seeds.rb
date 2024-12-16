Product.create!(Array.new(100) { { name: "Product #{rand(1..1000)}", stock: rand(1..50), price: rand(10..100) } })
puts "Products created: #{Product.count}"
Order.create!(Array.new(200) { { product_id: rand(1..100), quantity: rand(1..10), current_status: "pending" } })
puts "Orders created: #{Order.count}"
