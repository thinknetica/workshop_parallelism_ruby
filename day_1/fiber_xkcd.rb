# require 'fiber' # входит в стандартную библиотеку Ruby
require 'open-uri'
require 'json'
require 'benchmark'

results = []

def maximum
  url = 'http://xkcd.com/info.0.json'
  data = JSON.parse(URI.open(url).read)
  data['num']
end

def fetch_random_image
  random_num = rand(0..maximum)
  random_response = URI.open("http://xkcd.com/#{random_num}/info.0.json").read
  JSON.parse(random_response)['img']
end

Benchmark.bm do |x|
  x.report('sequential:') do
    10.times { fetch_random_image }
  end

  x.report('fiber:') do
    fiber = Fiber.new do
      result = Fiber.yield fetch_random_image
      results << result
    end

    # Ensure all fibers complete
    10.times { fiber.resume if fiber.alive? }
  end
end

#                 user     system      total        real
# sequential:   0.422525   0.104132   0.526657 (  6.714657)
# fiber:        0.036570   0.008626   0.045196 (  0.657261)