require 'parallel'
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
  x.report('sequential:') do
    10.times { fetch_random_image }
  end
  x.report('parralel(2):') do
    Parallel.map(1..10, in_threads: 2) do
      fetch_random_image
    end
  end
  x.report('parralel(4):') do
    Parallel.map(1..10, in_threads: 4) do
      fetch_random_image
    end
  end
  x.report('parralel(8):') do
    Parallel.map(1..10, in_threads: 8) do
      fetch_random_image
    end
  end
  x.report('parralel(10):') do
    Parallel.map(1..10, in_threads: 10) do
      fetch_random_image
    end
  end
end

#                   user     system      total        real
# sequential:     0.399376   0.088084   0.487460 (  5.914949)
# parralel(2):    0.423674   0.089017   0.512691 (  3.873784)
# parralel(4):    0.363313   0.074513   0.437826 (  2.208030)
# parralel(8):    0.298710   0.058157   0.356867 (  1.389456)
# parralel(10):   0.228698   0.035831   0.264529 (  1.255302)