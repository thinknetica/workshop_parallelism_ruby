# День 2, Применение параллельных вычислений в Rails проектах

Для настройки проекта запустить:

1. `bundle install`
2. `bundle exec rails db:setup`

Примеры заданий обработки и демонстрация проблем при обработке данных с конкурентностью:

`rake orders:deadlock`
`rake orders:non_repeatable_read`
`rake orders:dirty_read`
`rake orders:in_thread`
`rake orders:parallel`
`rake orders:async`
`rake orders:sync_noranges`
`rake orders:sync_ranges`
`rake orders:ractors`
`rake orders:fibers`
`rake orders:race_condition`

## links

```ruby
1000.times { |i| Product.create(name: "name-#{i}") }
# Product.create([{name: "name-#{i}"}])

#Время выполнения?
#- 1000мс
#- 2000мс
#- 3000мс
#- 4000мс

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
Product.create!(Array.new(1000) { { name: "name-#{rand(1..1000)}", stock: rand(1..50), price: rand(10..100) } })
puts "processed in #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time}" # processed in 0.1521700001321733

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
1000.times { |i| Product.create! name: "name-#{i}", stock: rand(1..50), price: rand(10..100) }
puts "processed in #{Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time}" # processed in 0.5186629998497665

```