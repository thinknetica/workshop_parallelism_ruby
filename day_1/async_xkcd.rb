require 'async'
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
    10.times.map { fetch_random_image }
  end

  x.report('async:') do
    Async do |task| # ускоряет работу с блокирующими IO операциями
      10.times.map do
        task.async do
          fetch_random_image.tap do |result|
            results << result
          end
        end
      end.each(&:wait)
    end
  end
end

#                 user     system      total        real
# sequential:   0.416017   0.093929   0.509946 (  6.541203)
# async:        0.206131   0.034727   0.240858 (  1.035334)
