-- create table to store ticket numbers
create table t0
(
    i integer,
    constraint pk_i primary key (i)
);

select * from generate_series(1, 10);

-- show free/used statistics
select min(i)               as min_number_used,
       max(i)               as max_number_used,
       1000000 - count(1)   as free_numbers_count,
       count(1)             as used_numbers_count,
       (count(1) * 1.0/1000000) * 100 as percent_used
from t0;

-- select some tickets
select * from t0 order by i limit 10;

-- delete all
delete from t0 where 1=1;

-- insert 100 thousand
with recursive sequence(i) as (
    select 1
    union
    select i + 1 from sequence where i < 100000
)
insert into t0(i) select i from sequence;

-- insert 1 million
with recursive sequence(i) as (
    select 1
    union
    select i + 1 from sequence where i < 1000000
)
insert into t0(i) select i from sequence;

-- delete 11 tickets in [20..30]
delete from t0 where i between 20 and 30;

-- delete 11 tickets in [1..10]
delete from t0 where i between 1 and 10;

delete from t0 where i  > 1000000 - 10;

-- delete 101 tickets in [100..300]
delete from t0 where i between 100 and 200;

-- delete every fifth ticket (20%)
delete from t0 where i % 5 = 0;

-- delete every (33%)
delete from t0 where (i % 151) < 50;

-- delete one ticket
delete from t0 where i between 5000 and 5000;

-- delete two tickets
delete from t0 where i between 5000 and 5001;

-- delete 5000 + 1 tickets
delete from t0 where i between 10000 and 15000;

delete from t0 where i between 20000 and 20200 and (i % 13 == 0);

delete from t0 where i > 99999;

delete from t0 where (i % 2 == 0);

delete from t0 where (i % 13 == 0);

select 1, min(i) from t0;
select i from t0 order by i limit 100;

select t0.i a, (select min(t1.i) from t0 t1 where t1.i > t0.i) b
from t0; --middle range

-- O(2 * n lg(n)) + O(n)
with start_range(a,b) as (
        select 1 as a, (select min(i) from t0 where i > 0) as b -- start range (from 0 or variable)
    ),
    middle_range(a,b) as (
        select 1 + lag(i, 1) over (order by i) as a, i  as b from t0
    ),
    end_range(a, b) as (
        select (select 1 + coalesce(max(i), 0) from t0 where i > 0) as a, 1000000 + 1 as b
    ),
    all_ranges(a,b) as (
              select a, b from start_range  where b - a > 0
        union select a, b from middle_range where b - a > 0
        union select a, b from end_range    where b - a > 0
    ),
    stat_table(min_number_used,
               max_number_used,
               free_count,
               used_count,
               percent_used) as (
        select min(i)               as min_number_used,
               max(i)               as max_number_used,
               1000000 - count(1)   as free_numbers_count,
               count(1)             as used_numbers_count,
               (count(1) * 1.0/1000000) * 100 as percent_used
        from t0
    ) --select a, b, b - a as size from all_ranges order by (b - a) desc, a asc limit 10;
    --select a, b from all_ranges;
--     select count(1)       as range_count,
--            sum(b - a)     as num_free,
--            min(b - a)     as min_range_size,
--            max(b - a)     as max_range_size,
--     from all_ranges;

      select coalesce(count(1), 0)            as range_count,
             coalesce(sum(b - a), 1000000)    as num_free,
             coalesce(min(b - a), 0)          as min_range_size,
             coalesce(max(b - a), 0)          as max_range_size
      from all_ranges;

    select min_number_used,
           max_number_used,
           free_count,
           used_count,
           percent_used
    from stat_table;

-- O(3 * n lg(n))
with stat_table(min_number_used,
               max_number_used,
               free_count,
               used_count,
               percent_used) as (
        select min(i) as min_number_used,
               max(i) as max_number_used,
               1000000 - count(1) as free_count,
               count(1) as used_count,
               (count(1) * 1.0/1000000) * 100 percent_used
        from t0
    ),
    s(a, b) as (
        select a + 1, b
        from (
                 select 0                                   as a,
                        (select min(i) from t0 where i > 0) as b -- start range (from 0 or variable)
                 union
                 select t0.i as a, (select min(t1.i) from t0 as t1 where t1.i > t0.i) as b -- O(n*lgn)
                 from t0 --middle range
                 union
                 select (select coalesce(max(i), 0) from t0 where i > 0) as a, 1000000 + 1 as b -- end range (to 1M or variable)
             )
        where b - a - 1 > 0 -- range must not be empty
    )
--select a, b, b - a as size from s order by a;
select count(1) as count_ranges,
       sum(b - a) as num_free,
       min(b - a) as min_range,
       max(b - a) as max_range
    from s;

select min_number_used,
    max_number_used,
    free_count,
    used_count,
    percent_used
    from stat_table;

with recursive s(a, b) as (
    select a + 1 as a, b
    from (
             select 0                                   a,
                    (select min(i) from t0 where i > 0) b -- start range (from 0 or variable)
             union
             select t0.i a, (select min(t1.i) from t0 t1 where t1.i > t0.i) b
             from t0 --middle range
             union
             select (select coalesce(max(i) + 1, 0) from t0 where i > 0) a,
                    1000000 b-- end range (to 1M or variable)
         )
    where b - a > 1 -- range must not be empty
    union
    select a + 1, b
    from s
    where a + 1 < b
)
select count(a)
from s
order by a;


with start_range(a,b) as (
        select 1 as a, (select min(i) from t0 where i > 0) as b -- start range (from 0 or variable)
    ),
    middle_range(a,b) as (
        select 1 + lag(i, 1) over (order by i) as a, i  as b from t0
    ),
    end_range(a, b) as (
        select (select 1 + coalesce(max(i), 0) from t0 where i > 0) as a, 1000000 + 1 as b
    ),
    all_ranges(a,b) as (
              select a, b from start_range  where b - a > 0
        union select a, b from middle_range where b - a > 0
        union select a, b from end_range    where b - a > 0
    ),
    sequence(a,b) as (
        select a, b from all_ranges where a < b
        union
        select a + 1 as a, b as b from sequence where a + 1 < b
    )
--select a from sequence order by a limit 100;
select count(a) from sequence order by a;
--select a,b,(b-a) z from all_ranges order by a limit 100;
