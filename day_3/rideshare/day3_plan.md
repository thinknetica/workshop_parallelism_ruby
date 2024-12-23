# Day 3

https://danielabaron.me/blog/rails-query-perf/
https://blog.appsignal.com/2024/10/30/optimize-database-performance-in-ruby-on-rails-and-activerecord.html


```ruby
bundle exec database_consistency -c .database_consistency.config
```

```ruby
rails g migration AddMissingIndexes
```

## create report

  - Trip completed date
  - Rating given by the rider
  - Driver that provided the trip
  - Rider that took the trip
  - Location where the trip started
  
  
### Trip completed date

```ruby
class Trip < ApplicationRecord
  scope :recently_completed, -> {
    where('completed_at >= ?', 1.week.ago)
  }
end

results = Trip.recently_completed
# SELECT "trips".* FROM "trips" WHERE (completed_at >= '2024-12-16 03:41:22.580544');

results.length
# => 1000

results.first.attributes
# =>
# {"id"=>1,
#  "trip_request_id"=>1,
#  "driver_id"=>20040,
#  "completed_at"=>Sun, 22 Dec 2024 18:12:46.291753000 CST -06:00,
#  "rating"=>3,
#  "created_at"=>Sun, 22 Dec 2024 18:11:46.307708000 CST -06:00,
#  "updated_at"=>Sun, 22 Dec 2024 18:11:46.307708000 CST -06:00}
```

```sh
bin/rails dbconsole

rideshare_development=> EXPLAIN (ANALYZE) SELECT "trips".* FROM "trips" WHERE (completed_at >= '2024-12-16 03:41:22.580544');
                                                              QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------
 Finalize Aggregate  (cost=156193.14..156193.15 rows=1 width=8) (actual time=183.851..186.521 rows=1 loops=1)
   ->  Gather  (cost=156192.93..156193.14 rows=2 width=8) (actual time=183.631..186.516 rows=3 loops=1)
         Workers Planned: 2
         Workers Launched: 2
         ->  Partial Aggregate  (cost=155192.93..155192.94 rows=1 width=8) (actual time=169.149..169.149 rows=1 loops=3)
               ->  Parallel Seq Scan on trips  (cost=0.00..155191.54 rows=554 width=8) (actual time=108.487..169.122 rows=333 loops=3)
                     Filter: (completed_at >= '2024-12-16 03:41:22.580544'::timestamp without time zone)
                     Rows Removed by Filter: 3333333
 Planning Time: 0.172 ms
 Execution Time: 186.552 ms
(10 rows)

rideshare_development=> \d trips
                                           Table "rideshare.trips"
     Column      |              Type              | Collation | Nullable |              Default
-----------------+--------------------------------+-----------+----------+-----------------------------------
 id              | bigint                         |           | not null | nextval('trips_id_seq'::regclass)
 trip_request_id | bigint                         |           | not null |
 driver_id       | integer                        |           | not null |
 completed_at    | timestamp without time zone    |           |          |
 rating          | integer                        |           |          |
 created_at      | timestamp(6) without time zone |           | not null |
 updated_at      | timestamp(6) without time zone |           | not null |
Indexes:
    "trips_pkey" PRIMARY KEY, btree (id)
    "index_trips_on_driver_id" btree (driver_id)
    "index_trips_on_rating" btree (rating)
    "index_trips_on_trip_request_id" btree (trip_request_id)
    # NO index for completed_at field
Check constraints:
    "chk_rails_4743ddc2d2" CHECK (completed_at > created_at) NOT VALID
    "rating_check" CHECK (rating >= 1 AND rating <= 5)
Foreign-key constraints:
    "fk_rails_6d92acb430" FOREIGN KEY (trip_request_id) REFERENCES trip_requests(id)
    "fk_rails_e7560abc33" FOREIGN KEY (driver_id) REFERENCES users(id)
Referenced by:
    TABLE "trip_positions" CONSTRAINT "fk_rails_9688ac8706" FOREIGN KEY (trip_id) REFERENCES trips(id)

```

https://cloud.google.com/sql/docs/postgres/optimize-cpu-usage


```
SELECT 
  relname, 
  idx_scan,  
  seq_scan, 
  n_live_tup 
FROM 
  pg_stat_user_tables 
WHERE 
  seq_scan > 0 
ORDER BY 
  n_live_tup desc;

```





### Rating given by the rider
### Driver that provided the trip
### Rider that took the trip
### Location where the trip started
