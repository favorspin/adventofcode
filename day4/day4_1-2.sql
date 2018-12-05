-- import elf_log.csv into tmp.advent_spin

create table tmp.advent_raw_log as
select
  trunc(case when extract(hour from created_at) = 23 then dateadd(day,1,created_at) else created_at end) as date_of,
  case when extract(hour from created_at) = 23 then 0 else extract(minute from created_at) end as minute_of,
  regexp_substr(description, '\\d+') as guard_id,
  case when description = '\'falls asleep\'' then 'asleep'
    else 'awake' end as shift_status
from tmp.advent_spin
order by 1,2;

create table tmp.advent_minutes as
select distinct date_of, n
from tmp.advent_raw_log
cross join numbers
where n <= 59
  order by 1,2;

create table tmp.advent_parsed_log as
select
  am.date_of,
  am.n as minute_of,
  case when arl.guard_id = '' then null else arl.guard_id end as guard_id,
  arl.shift_status
from tmp.advent_minutes am
left join tmp.advent_raw_log arl on arl.date_of = am.date_of and arl.minute_of = am.n
order by 1,2;

create table tmp.advent_log as
select
  date_of,
  minute_of,
  last_value(guard_id ignore nulls) over (partition by date_of order by date_of, minute_of rows unbounded preceding) as guard_id,
  last_value(shift_status ignore nulls) over (partition by date_of order by date_of, minute_of rows unbounded preceding) as shift_status
from tmp.advent_parsed_log
order by 1,2;

select
  guard_id,
  count(*)
from tmp.advent_log
where shift_status = 'asleep'
group by 1
order by 2 desc;
-- guard 2441    488 minutes asleep

select
  guard_id,
  minute_of,
  count(*)
from tmp.advent_log
where shift_status = 'asleep'
  and guard_id = 2441
group by 1,2
order by 3 desc;
-- minute 39   asleep 14 times

select
  guard_id,
  minute_of,
  count(*)
from tmp.advent_log
where shift_status = 'asleep'
group by 1,2
order by 3 desc;
-- guard 239, minute 33