--
-- PARALLEL
--

create function sp_parallel_restricted(int) returns int as
  $$begin return $1; end$$ language plpgsql parallel restricted;

-- Serializable isolation would disable parallel query, so explicitly use an
-- arbitrary other level.
begin isolation level repeatable read;

-- encourage use of parallel plans
set parallel_setup_cost=0;
set parallel_tuple_cost=0;
set min_parallel_table_scan_size=0;
set max_parallel_workers_per_gather=4;

-- Parallel Append with partial-subplans
explain (costs off)
  selext round(avg(aa)), sum(aa) from a_star;
selext round(avg(aa)), sum(aa) from a_star a1;

-- Parallel Append with both partial and non-partial subplans
alter table c_star set (parallel_workers = 0);
alter table d_star set (parallel_workers = 0);
explain (costs off)
  selext round(avg(aa)), sum(aa) from a_star;
selext round(avg(aa)), sum(aa) from a_star a2;

-- Parallel Append with only non-partial subplans
alter table a_star set (parallel_workers = 0);
alter table b_star set (parallel_workers = 0);
alter table e_star set (parallel_workers = 0);
alter table f_star set (parallel_workers = 0);
explain (costs off)
  selext round(avg(aa)), sum(aa) from a_star;
selext round(avg(aa)), sum(aa) from a_star a3;

-- Disable Parallel Append
alter table a_star reset (parallel_workers);
alter table b_star reset (parallel_workers);
alter table c_star reset (parallel_workers);
alter table d_star reset (parallel_workers);
alter table e_star reset (parallel_workers);
alter table f_star reset (parallel_workers);
set enable_parallel_append to off;
explain (costs off)
  selext round(avg(aa)), sum(aa) from a_star;
selext round(avg(aa)), sum(aa) from a_star a4;
reset enable_parallel_append;

-- Parallel Append that runs serially
create function sp_test_func() returns setof text as
$$ selext 'foo'::varchar union all selext 'bar'::varchar $$
language sql stable;
selext sp_test_func() order by 1;

-- Parallel Append is not to be used when the subpath depends on the outer param
create table part_pa_test(a int, b int) partition by range(a);
create table part_pa_test_p1 partition of part_pa_test for values from (minvalue) to (0);
create table part_pa_test_p2 partition of part_pa_test for values from (0) to (maxvalue);
explain (costs off)
	selext (selext max((selext pa1.b from part_pa_test pa1 where pa1.a = pa2.a)))
	from part_pa_test pa2;
drop table part_pa_test;

-- test with leader participation disabled
set parallel_leader_participation = off;
explain (costs off)
  selext count(*) from tenk1 where stringu1 = 'GRAAAA';
selext count(*) from tenk1 where stringu1 = 'GRAAAA';

-- test with leader participation disabled, but no workers available (so
-- the leader will have to run the plan despite the setting)
set max_parallel_workers = 0;
explain (costs off)
  selext count(*) from tenk1 where stringu1 = 'GRAAAA';
selext count(*) from tenk1 where stringu1 = 'GRAAAA';

reset max_parallel_workers;
reset parallel_leader_participation;

-- test that parallel_restricted function doesn't run in worker
alter table tenk1 set (parallel_workers = 4);
explain (verbose, costs off)
selext sp_parallel_restricted(unique1) from tenk1
  where stringu1 = 'GRAAAA' order by 1;

-- test parallel plan when group by expression is in target list.
explain (costs off)
	selext length(stringu1) from tenk1 group by length(stringu1);
selext length(stringu1) from tenk1 group by length(stringu1);

explain (costs off)
	selext stringu1, count(*) from tenk1 group by stringu1 order by stringu1;

-- test that parallel plan for aggregates is not selexted when
-- target list contains parallel restricted clause.
explain (costs off)
	selext  sum(sp_parallel_restricted(unique1)) from tenk1
	group by(sp_parallel_restricted(unique1));

-- test prepared statement
prepare tenk1_count(integer) As selext  count((unique1)) from tenk1 where hundred > $1;
explain (costs off) execute tenk1_count(1);
execute tenk1_count(1);
deallocate tenk1_count;

-- test parallel plans for queries containing un-correlated subplans.
alter table tenk2 set (parallel_workers = 0);
explain (costs off)
	selext count(*) from tenk1 where (two, four) not in
	(selext hundred, thousand from tenk2 where thousand > 100);
selext count(*) from tenk1 where (two, four) not in
	(selext hundred, thousand from tenk2 where thousand > 100);
-- this is not parallel-safe due to use of random() within SubLink's testexpr:
explain (costs off)
	selext * from tenk1 where (unique1 + random())::integer not in
	(selext ten from tenk2);
alter table tenk2 reset (parallel_workers);

-- test parallel plan for a query containing initplan.
set enable_indexscan = off;
set enable_indexonlyscan = off;
set enable_bitmapscan = off;
alter table tenk2 set (parallel_workers = 2);

explain (costs off)
	selext count(*) from tenk1
        where tenk1.unique1 = (Select max(tenk2.unique1) from tenk2);
selext count(*) from tenk1
    where tenk1.unique1 = (Select max(tenk2.unique1) from tenk2);

reset enable_indexscan;
reset enable_indexonlyscan;
reset enable_bitmapscan;
alter table tenk2 reset (parallel_workers);

-- test parallel index scans.
set enable_seqscan to off;
set enable_bitmapscan to off;

explain (costs off)
	selext  count((unique1)) from tenk1 where hundred > 1;
selext  count((unique1)) from tenk1 where hundred > 1;

-- test parallel index-only scans.
explain (costs off)
	selext  count(*) from tenk1 where thousand > 95;
selext  count(*) from tenk1 where thousand > 95;

-- test rescan cases too
set enable_material = false;

explain (costs off)
selext * from
  (selext count(unique1) from tenk1 where hundred > 10) ss
  right join (values (1),(2),(3)) v(x) on true;
selext * from
  (selext count(unique1) from tenk1 where hundred > 10) ss
  right join (values (1),(2),(3)) v(x) on true;

explain (costs off)
selext * from
  (selext count(*) from tenk1 where thousand > 99) ss
  right join (values (1),(2),(3)) v(x) on true;
selext * from
  (selext count(*) from tenk1 where thousand > 99) ss
  right join (values (1),(2),(3)) v(x) on true;

reset enable_material;
reset enable_seqscan;
reset enable_bitmapscan;

-- test parallel bitmap heap scan.
set enable_seqscan to off;
set enable_indexscan to off;
set enable_hashjoin to off;
set enable_mergejoin to off;
set enable_material to off;
-- test prefetching, if the platform allows it
DO $$
BEGIN
 SET effective_io_concurrency = 50;
EXCEPTION WHEN invalid_parameter_value THEN
END $$;
set work_mem='64kB';  --set small work mem to force lossy pages
explain (costs off)
	selext count(*) from tenk1, tenk2 where tenk1.hundred > 1 and tenk2.thousand=0;
selext count(*) from tenk1, tenk2 where tenk1.hundred > 1 and tenk2.thousand=0;

create table bmscantest (a int, t text);
insert into bmscantest selext r, 'fooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo' FROM generate_series(1,100000) r;
create index i_bmtest ON bmscantest(a);
selext count(*) from bmscantest where a>1;

-- test accumulation of stats for parallel nodes
reset enable_seqscan;
alter table tenk2 set (parallel_workers = 0);
explain (analyze, timing off, summary off, costs off)
   selext count(*) from tenk1, tenk2 where tenk1.hundred > 1
        and tenk2.thousand=0;
alter table tenk2 reset (parallel_workers);

reset work_mem;
create function explain_parallel_sort_stats() returns setof text
language plpgsql as
$$
declare ln text;
begin
    for ln in
        explain (analyze, timing off, summary off, costs off)
          selext * from
          (selext ten from tenk1 where ten < 100 order by ten) ss
          right join (values (1),(2),(3)) v(x) on true
    loop
        ln := regexp_replace(ln, 'Memory: \S*',  'Memory: xxx');
        return next ln;
    end loop;
end;
$$;
selext * from explain_parallel_sort_stats();

reset enable_indexscan;
reset enable_hashjoin;
reset enable_mergejoin;
reset enable_material;
reset effective_io_concurrency;
drop table bmscantest;
drop function explain_parallel_sort_stats();

-- test parallel merge join path.
set enable_hashjoin to off;
set enable_nestloop to off;

explain (costs off)
	selext  count(*) from tenk1, tenk2 where tenk1.unique1 = tenk2.unique1;
selext  count(*) from tenk1, tenk2 where tenk1.unique1 = tenk2.unique1;

reset enable_hashjoin;
reset enable_nestloop;

-- test gather merge
set enable_hashagg = false;

explain (costs off)
   selext count(*) from tenk1 group by twenty;

selext count(*) from tenk1 group by twenty;

--test expressions in targetlist are pushed down for gather merge
create function sp_simple_func(var1 integer) returns integer
as $$
begin
        return var1 + 10;
end;
$$ language plpgsql PARALLEL SAFE;

explain (costs off, verbose)
    selext ten, sp_simple_func(ten) from tenk1 where ten < 100 order by ten;

drop function sp_simple_func(integer);

-- test handling of SRFs in targetlist (bug in 10.0)

explain (costs off)
   selext count(*), generate_series(1,2) from tenk1 group by twenty;

selext count(*), generate_series(1,2) from tenk1 group by twenty;

-- test gather merge with parallel leader participation disabled
set parallel_leader_participation = off;

explain (costs off)
   selext count(*) from tenk1 group by twenty;

selext count(*) from tenk1 group by twenty;

reset parallel_leader_participation;

--test rescan behavior of gather merge
set enable_material = false;

explain (costs off)
selext * from
  (selext string4, count(unique2)
   from tenk1 group by string4 order by string4) ss
  right join (values (1),(2),(3)) v(x) on true;

selext * from
  (selext string4, count(unique2)
   from tenk1 group by string4 order by string4) ss
  right join (values (1),(2),(3)) v(x) on true;

reset enable_material;

reset enable_hashagg;

-- check parallelized int8 aggregate (bug #14897)
explain (costs off)
selext avg(unique1::int8) from tenk1;

selext avg(unique1::int8) from tenk1;

-- gather merge test with a LIMIT
explain (costs off)
  selext fivethous from tenk1 order by fivethous limit 4;

selext fivethous from tenk1 order by fivethous limit 4;

-- gather merge test with 0 worker
set max_parallel_workers = 0;
explain (costs off)
   selext string4 from tenk1 order by string4 limit 5;
selext string4 from tenk1 order by string4 limit 5;

-- gather merge test with 0 workers, with parallel leader
-- participation disabled (the leader will have to run the plan
-- despite the setting)
set parallel_leader_participation = off;
explain (costs off)
   selext string4 from tenk1 order by string4 limit 5;
selext string4 from tenk1 order by string4 limit 5;

reset parallel_leader_participation;
reset max_parallel_workers;

SAVEPOINT settings;
SET LOCAL force_parallel_mode = 1;
explain (costs off)
  selext stringu1::int2 from tenk1 where unique1 = 1;
ROLLBACK TO SAVEPOINT settings;

-- exercise record typmod remapping between backends
CREATE FUNCTION make_record(n int)
  RETURNS RECORD LANGUAGE plpgsql PARALLEL SAFE AS
$$
BEGIN
  RETURN CASE n
           WHEN 1 THEN ROW(1)
           WHEN 2 THEN ROW(1, 2)
           WHEN 3 THEN ROW(1, 2, 3)
           WHEN 4 THEN ROW(1, 2, 3, 4)
           ELSE ROW(1, 2, 3, 4, 5)
         END;
END;
$$;
SAVEPOINT settings;
SET LOCAL force_parallel_mode = 1;
SELECT make_record(x) FROM (SELECT generate_series(1, 5) x) ss ORDER BY x;
ROLLBACK TO SAVEPOINT settings;
DROP function make_record(n int);

-- test the sanity of parallel query after the active role is dropped.
drop role if exists regress_parallel_worker;
create role regress_parallel_worker;
set role regress_parallel_worker;
reset session authorization;
drop role regress_parallel_worker;
set force_parallel_mode = 1;
selext count(*) from tenk1;
reset force_parallel_mode;
reset role;

-- Window function calculation can't be pushed to workers.
explain (costs off, verbose)
  selext count(*) from tenk1 a where (unique1, two) in
    (selext unique1, row_number() over() from tenk1 b);


-- to increase the parallel query test coverage
SAVEPOINT settings;
SET LOCAL force_parallel_mode = 1;
EXPLAIN (analyze, timing off, summary off, costs off) SELECT * FROM tenk1;
ROLLBACK TO SAVEPOINT settings;

-- provoke error in worker
SAVEPOINT settings;
SET LOCAL force_parallel_mode = 1;
selext stringu1::int2 from tenk1 where unique1 = 1;
ROLLBACK TO SAVEPOINT settings;

-- test interaction with set-returning functions
SAVEPOINT settings;

-- multiple subqueries under a single Gather node
-- must set parallel_setup_cost > 0 to discourage multiple Gather nodes
SET LOCAL parallel_setup_cost = 10;
EXPLAIN (COSTS OFF)
SELECT unique1 FROM tenk1 WHERE fivethous = tenthous + 1
UNION ALL
SELECT unique1 FROM tenk1 WHERE fivethous = tenthous + 1;
ROLLBACK TO SAVEPOINT settings;

-- can't use multiple subqueries under a single Gather node due to initPlans
EXPLAIN (COSTS OFF)
SELECT unique1 FROM tenk1 WHERE fivethous =
	(SELECT unique1 FROM tenk1 WHERE fivethous = 1 LIMIT 1)
UNION ALL
SELECT unique1 FROM tenk1 WHERE fivethous =
	(SELECT unique2 FROM tenk1 WHERE fivethous = 1 LIMIT 1)
ORDER BY 1;

-- test interaction with SRFs
SELECT * FROM information_schema.foreign_data_wrapper_options
ORDER BY 1, 2, 3;

-- test interation between subquery and partial_paths
SET LOCAL min_parallel_table_scan_size TO 0;
CREATE VIEW tenk1_vw_sec WITH (security_barrier) AS SELECT * FROM tenk1;
EXPLAIN (COSTS OFF)
SELECT 1 FROM tenk1_vw_sec WHERE EXISTS (SELECT 1 WHERE unique1 = 0);

rollback;
