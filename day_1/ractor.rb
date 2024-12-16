require 'open-uri'
require 'json'
require 'benchmark'

# Fail
2.times.map do
  Ractor.new do
    URI.open("http://xkcd.com/#{rand(0..2000)}/info.0.json")
    # Ractor::IsolationError => URI не совместим, используй async
  end
end.each(&:take)

# Success
def factorial(count)
  (1..count).inject(:*)
end

Benchmark.bm do |x|
  x.report('sequential:') do
    5.times do
      2000.times { factorial(1000) }
    end
  end

  x.report('ractors:') do
    ractors = []
    5.times do
      ractors << Ractor.new do
        2000.times { factorial(1000) }
      end
    end
    ractors.each(&:take)
  end
end

#                 user     system      total        real
# sequential:   3.906651   0.192582   4.099233 (  4.158449)
# ractors:      8.169126   0.362028   8.531154 (  2.555159)