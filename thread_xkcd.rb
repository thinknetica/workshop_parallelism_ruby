# require 'thread'
require 'open-uri'
require 'json'

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
  x.report('threads(2x5):') do
    results = []
    mutex = Mutex.new

    threads = 2.times.map do
      Thread.new do
        5.times do
          mutex.synchronize do
            results << fetch_random_image
          end
        end
      end
    end
    threads.each(&:join)
  end

  x.report('threads(5x2):') do
    results = []
    mutex = Mutex.new

    threads = 5.times.map do
      Thread.new do
        2.times do
          mutex.synchronize do
            results << fetch_random_image
          end
        end
      end
    end
    threads.each(&:join)
  end

  x.report('threads(10x1):') do
    results = []
    mutex = Mutex.new

    threads = 10.times.map do
      Thread.new do
        mutex.synchronize do
          results << fetch_random_image
        end
      end
    end
    threads.each(&:join)
  end
end

#                 user     system      total        real
# threads(2x5):  0.386624   0.093598   0.480222 (  7.138545)
# threads(5x2):  0.482596   0.119362   0.601958 (  8.082401)
# threads(10x1): 0.405196   0.114131   0.519327 (  6.899579)
