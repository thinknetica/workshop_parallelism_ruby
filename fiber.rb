require 'fiber'

def load_data
  puts "Этап 1: Загрузка данных..."
  sleep(1) && (1..10).to_a
end

def filter_data(data)
  puts "Этап 2: Фильтрация данных..."
  sleep(1) && data.select { |x| x.even? } # Оставляем только четные числа
end

def save_data(filtered_data)
  puts "Этап 3: Сохранение данных..."
  sleep(1) && "Сохранено #{filtered_data.size} элементов"
end

load_fiber = Fiber.new do
  data = load_data
  Fiber.yield(data)
end

filter_fiber = Fiber.new do |data|
  filtered_data = filter_data(data)
  Fiber.yield(filtered_data)
end

save_fiber = Fiber.new do |filtered_data|
  result = save_data(filtered_data)
  Fiber.yield(result)
end

data = load_fiber.resume
filtered_data = filter_fiber.resume(data)
result = save_fiber.resume(filtered_data)

puts result

###

def fact(count)
  (1..count).inject(:*)
end

factorial = Fiber.new do
  count = 1
  loop do
    Fiber.yield fact(count)
    count += 1
  end
end

factorial.resume # 1
factorial.resume # 2
factorial.resume # 6..
