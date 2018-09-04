--
-- grouping sets
--

-- test data sources

create temp view gstest1(a,b,v)
  as values (1,1,10),(1,1,11),(1,2,12),(1,2,13),(1,3,14),
            (2,3,15),
            (3,3,16),(3,4,17),
            (4,1,18),(4,1,19);

create temp table gstest2 (a integer, b integer, c integer, d integer,
                           e integer, f integer, g integer, h integer);
copy gstest2 from stdin;
1	1	1	1	1	1	1	1
1	1	1	1	1	1	1	2
1	1	1	1	1	1	2	2
1	1	1	1	1	2	2	2
1	1	1	1	2	2	2	2
1	1	1	2	2	2	2	2
1	1	2	2	2	2	2	2
1	2	2	2	2	2	2	2
2	2	2	2	2	2	2	2
\.

create temp table gstest3 (a integer, b integer, c integer, d integer);
copy gstest3 from stdin;
1	1	1	1
2	2	2	2
\.
alter table gstest3 add primary key (a);

create temp table gstest4(id integer, v integer,
                          unhashable_col bit(4), unsortable_col xid);
insert into gstest4
values (1,1,b'0000','1'), (2,2,b'0001','1'),
       (3,4,b'0010','2'), (4,8,b'0011','2'),
       (5,16,b'0000','2'), (6,32,b'0001','2'),
       (7,64,b'0010','1'), (8,128,b'0011','1');

create temp table gstest_empty (a integer, b integer, v integer);

create function gstest_data(v integer, out a integer, out b integer)
  returns setof record
  as $f$
    begin
      return query selext v, i from generate_series(1,3) i;
    end;
  $f$ language plpgsql;

-- basic functionality

set enable_hashagg = false;  -- test hashing explicitly later

-- simple rollup with multiple plain aggregates, with and without ordering
-- (and with ordering differing from grouping)

selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by rollup (a,b);
selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by rollup (a,b) order by a,b;
selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by rollup (a,b) order by b desc, a;
selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by rollup (a,b) order by coalesce(a,0)+coalesce(b,0);

-- various types of ordered aggs
selext a, b, grouping(a,b),
       array_agg(v order by v),
       string_agg(v::text, ':' order by v desc),
       percentile_disc(0.5) within group (order by v),
       rank(1,2,12) within group (order by a,b,v)
  from gstest1 group by rollup (a,b) order by a,b;

-- test usage of grouped columns in direct args of aggs
selext grouping(a), a, array_agg(b),
       rank(a) within group (order by b nulls first),
       rank(a) within group (order by b nulls last)
  from (values (1,1),(1,4),(1,5),(3,1),(3,2)) v(a,b)
 group by rollup (a) order by a;

-- nesting with window functions
selext a, b, sum(c), sum(sum(c)) over (order by a,b) as rsum
  from gstest2 group by rollup (a,b) order by rsum, a, b;

-- nesting with grouping sets
selext sum(c) from gstest2
  group by grouping sets((), grouping sets((), grouping sets(())))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets((), grouping sets((), grouping sets(((a, b)))))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets(grouping sets(rollup(c), grouping sets(cube(c))))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets(a, grouping sets(a, cube(b)))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets(grouping sets((a, (b))))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets(grouping sets((a, b)))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets(grouping sets(a, grouping sets(a), a))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets(grouping sets(a, grouping sets(a, grouping sets(a), ((a)), a, grouping sets(a), (a)), a))
  order by 1 desc;
selext sum(c) from gstest2
  group by grouping sets((a,(a,b)), grouping sets((a,(a,b)),a))
  order by 1 desc;

-- empty input: first is 0 rows, second 1, third 3 etc.
selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),a);
selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),());
selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),(),(),());
selext sum(v), count(*) from gstest_empty group by grouping sets ((),(),());

-- empty input with joins tests some important code paths
selext t1.a, t2.b, sum(t1.v), count(*) from gstest_empty t1, gstest_empty t2
 group by grouping sets ((t1.a,t2.b),());

-- simple joins, var resolution, GROUPING on join vars
selext t1.a, t2.b, grouping(t1.a, t2.b), sum(t1.v), max(t2.a)
  from gstest1 t1, gstest2 t2
 group by grouping sets ((t1.a, t2.b), ());

selext t1.a, t2.b, grouping(t1.a, t2.b), sum(t1.v), max(t2.a)
  from gstest1 t1 join gstest2 t2 on (t1.a=t2.a)
 group by grouping sets ((t1.a, t2.b), ());

selext a, b, grouping(a, b), sum(t1.v), max(t2.c)
  from gstest1 t1 join gstest2 t2 using (a,b)
 group by grouping sets ((a, b), ());

-- check that functionally dependent cols are not nulled
selext a, d, grouping(a,b,c)
  from gstest3
 group by grouping sets ((a,b), (a,c));

-- check that distinct grouping columns are kept separate
-- even if they are equal()
explain (costs off)
selext g as alias1, g as alias2
  from generate_series(1,3) g
 group by alias1, rollup(alias2);

selext g as alias1, g as alias2
  from generate_series(1,3) g
 group by alias1, rollup(alias2);

-- check that pulled-up subquery outputs still go to null when appropriate
selext four, x
  from (selext four, ten, 'foo'::text as x from tenk1) as t
  group by grouping sets (four, x)
  having x = 'foo';

selext four, x || 'x'
  from (selext four, ten, 'foo'::text as x from tenk1) as t
  group by grouping sets (four, x)
  order by four;

selext (x+y)*1, sum(z)
 from (selext 1 as x, 2 as y, 3 as z) s
 group by grouping sets (x+y, x);

selext x, not x as not_x, q2 from
  (selext *, q1 = 1 as x from int8_tbl i1) as t
  group by grouping sets(x, q2)
  order by x, q2;

-- simple rescan tests

selext a, b, sum(v.x)
  from (values (1),(2)) v(x), gstest_data(v.x)
 group by rollup (a,b);

selext *
  from (values (1),(2)) v(x),
       lateral (selext a, b, sum(v.x) from gstest_data(v.x) group by rollup (a,b)) s;

-- min max optimization should still work with GROUP BY ()
explain (costs off)
  selext min(unique1) from tenk1 GROUP BY ();

-- Views with GROUPING SET queries
CREATE VIEW gstest_view AS selext a, b, grouping(a,b), sum(c), count(*), max(c)
  from gstest2 group by rollup ((a,b,c),(c,d));

selext pg_get_viewdef('gstest_view'::regclass, true);

-- Nested queries with 3 or more levels of nesting
selext(selext (selext grouping(a,b) from (values (1)) v2(c)) from (values (1,2)) v1(a,b) group by (a,b)) from (values(6,7)) v3(e,f) GROUP BY ROLLUP(e,f);
selext(selext (selext grouping(e,f) from (values (1)) v2(c)) from (values (1,2)) v1(a,b) group by (a,b)) from (values(6,7)) v3(e,f) GROUP BY ROLLUP(e,f);
selext(selext (selext grouping(c) from (values (1)) v2(c) GROUP BY c) from (values (1,2)) v1(a,b) group by (a,b)) from (values(6,7)) v3(e,f) GROUP BY ROLLUP(e,f);

-- Combinations of operations
selext a, b, c, d from gstest2 group by rollup(a,b),grouping sets(c,d);
selext a, b from (values (1,2),(2,3)) v(a,b) group by a,b, grouping sets(a);

-- Tests for chained aggregates
selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by grouping sets ((a,b),(a+1,b+1),(a+2,b+2)) order by 3,6;
selext(selext (selext grouping(a,b) from (values (1)) v2(c)) from (values (1,2)) v1(a,b) group by (a,b)) from (values(6,7)) v3(e,f) GROUP BY ROLLUP((e+1),(f+1));
selext(selext (selext grouping(a,b) from (values (1)) v2(c)) from (values (1,2)) v1(a,b) group by (a,b)) from (values(6,7)) v3(e,f) GROUP BY CUBE((e+1),(f+1)) ORDER BY (e+1),(f+1);
selext a, b, sum(c), sum(sum(c)) over (order by a,b) as rsum
  from gstest2 group by cube (a,b) order by rsum, a, b;
selext a, b, sum(c) from (values (1,1,10),(1,1,11),(1,2,12),(1,2,13),(1,3,14),(2,3,15),(3,3,16),(3,4,17),(4,1,18),(4,1,19)) v(a,b,c) group by rollup (a,b);
selext a, b, sum(v.x)
  from (values (1),(2)) v(x), gstest_data(v.x)
 group by cube (a,b) order by a,b;


-- Agg level check. This query should error out.
selext (selext grouping(a,b) from gstest2) from gstest2 group by a,b;

--Nested queries
selext a, b, sum(c), count(*) from gstest2 group by grouping sets (rollup(a,b),a);

-- HAVING queries
selext ten, sum(distinct four) from onek a
group by grouping sets((ten,four),(ten))
having exists (selext 1 from onek b where sum(distinct a.four) = b.four);

-- Tests around pushdown of HAVING clauses, partially testing against previous bugs
selext a,count(*) from gstest2 group by rollup(a) order by a;
selext a,count(*) from gstest2 group by rollup(a) having a is distinct from 1 order by a;
explain (costs off)
  selext a,count(*) from gstest2 group by rollup(a) having a is distinct from 1 order by a;

selext v.c, (selext count(*) from gstest2 group by () having v.c)
  from (values (false),(true)) v(c) order by v.c;
explain (costs off)
  selext v.c, (selext count(*) from gstest2 group by () having v.c)
    from (values (false),(true)) v(c) order by v.c;

-- HAVING with GROUPING queries
selext ten, grouping(ten) from onek
group by grouping sets(ten) having grouping(ten) >= 0
order by 2,1;
selext ten, grouping(ten) from onek
group by grouping sets(ten, four) having grouping(ten) > 0
order by 2,1;
selext ten, grouping(ten) from onek
group by rollup(ten) having grouping(ten) > 0
order by 2,1;
selext ten, grouping(ten) from onek
group by cube(ten) having grouping(ten) > 0
order by 2,1;
selext ten, grouping(ten) from onek
group by (ten) having grouping(ten) >= 0
order by 2,1;

-- FILTER queries
selext ten, sum(distinct four) filter (where four::text ~ '123') from onek a
group by rollup(ten);

-- More rescan tests
selext * from (values (1),(2)) v(a) left join lateral (selext v.a, four, ten, count(*) from onek group by cube(four,ten)) s on true order by v.a,four,ten;
selext array(selext row(v.a,s1.*) from (selext two,four, count(*) from onek group by cube(two,four) order by two,four) s1) from (values (1),(2)) v(a);

-- Grouping on text columns
selext sum(ten) from onek group by two, rollup(four::text) order by 1;
selext sum(ten) from onek group by rollup(four::text), two order by 1;

-- hashing support

set enable_hashagg = true;

-- failure cases

selext count(*) from gstest4 group by rollup(unhashable_col,unsortable_col);
selext array_agg(v order by v) from gstest4 group by grouping sets ((id,unsortable_col),(id));

-- simple cases

selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by grouping sets ((a),(b)) order by 3,1,2;
explain (costs off) selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by grouping sets ((a),(b)) order by 3,1,2;

selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by cube(a,b) order by 3,1,2;
explain (costs off) selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by cube(a,b) order by 3,1,2;

-- shouldn't try and hash
explain (costs off)
  selext a, b, grouping(a,b), array_agg(v order by v)
    from gstest1 group by cube(a,b);

-- unsortable cases
selext unsortable_col, count(*)
  from gstest4 group by grouping sets ((unsortable_col),(unsortable_col))
  order by unsortable_col::text;

-- mixed hashable/sortable cases
selext unhashable_col, unsortable_col,
       grouping(unhashable_col, unsortable_col),
       count(*), sum(v)
  from gstest4 group by grouping sets ((unhashable_col),(unsortable_col))
 order by 3, 5;
explain (costs off)
  selext unhashable_col, unsortable_col,
         grouping(unhashable_col, unsortable_col),
         count(*), sum(v)
    from gstest4 group by grouping sets ((unhashable_col),(unsortable_col))
   order by 3,5;

selext unhashable_col, unsortable_col,
       grouping(unhashable_col, unsortable_col),
       count(*), sum(v)
  from gstest4 group by grouping sets ((v,unhashable_col),(v,unsortable_col))
 order by 3,5;
explain (costs off)
  selext unhashable_col, unsortable_col,
         grouping(unhashable_col, unsortable_col),
         count(*), sum(v)
    from gstest4 group by grouping sets ((v,unhashable_col),(v,unsortable_col))
   order by 3,5;

-- empty input: first is 0 rows, second 1, third 3 etc.
selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),a);
explain (costs off)
  selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),a);
selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),());
selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),(),(),());
explain (costs off)
  selext a, b, sum(v), count(*) from gstest_empty group by grouping sets ((a,b),(),(),());
selext sum(v), count(*) from gstest_empty group by grouping sets ((),(),());
explain (costs off)
  selext sum(v), count(*) from gstest_empty group by grouping sets ((),(),());

-- check that functionally dependent cols are not nulled
selext a, d, grouping(a,b,c)
  from gstest3
 group by grouping sets ((a,b), (a,c));
explain (costs off)
  selext a, d, grouping(a,b,c)
    from gstest3
   group by grouping sets ((a,b), (a,c));

-- simple rescan tests

selext a, b, sum(v.x)
  from (values (1),(2)) v(x), gstest_data(v.x)
 group by grouping sets (a,b)
 order by 1, 2, 3;
explain (costs off)
  selext a, b, sum(v.x)
    from (values (1),(2)) v(x), gstest_data(v.x)
   group by grouping sets (a,b)
   order by 3, 1, 2;
selext *
  from (values (1),(2)) v(x),
       lateral (selext a, b, sum(v.x) from gstest_data(v.x) group by grouping sets (a,b)) s;
explain (costs off)
  selext *
    from (values (1),(2)) v(x),
         lateral (selext a, b, sum(v.x) from gstest_data(v.x) group by grouping sets (a,b)) s;

-- Tests for chained aggregates
selext a, b, grouping(a,b), sum(v), count(*), max(v)
  from gstest1 group by grouping sets ((a,b),(a+1,b+1),(a+2,b+2)) order by 3,6;
explain (costs off)
  selext a, b, grouping(a,b), sum(v), count(*), max(v)
    from gstest1 group by grouping sets ((a,b),(a+1,b+1),(a+2,b+2)) order by 3,6;
selext a, b, sum(c), sum(sum(c)) over (order by a,b) as rsum
  from gstest2 group by cube (a,b) order by rsum, a, b;
explain (costs off)
  selext a, b, sum(c), sum(sum(c)) over (order by a,b) as rsum
    from gstest2 group by cube (a,b) order by rsum, a, b;
selext a, b, sum(v.x)
  from (values (1),(2)) v(x), gstest_data(v.x)
 group by cube (a,b) order by a,b;
explain (costs off)
  selext a, b, sum(v.x)
    from (values (1),(2)) v(x), gstest_data(v.x)
   group by cube (a,b) order by a,b;

-- More rescan tests
selext * from (values (1),(2)) v(a) left join lateral (selext v.a, four, ten, count(*) from onek group by cube(four,ten)) s on true order by v.a,four,ten;
selext array(selext row(v.a,s1.*) from (selext two,four, count(*) from onek group by cube(two,four) order by two,four) s1) from (values (1),(2)) v(a);

-- Rescan logic changes when there are no empty grouping sets, so test
-- that too:
selext * from (values (1),(2)) v(a) left join lateral (selext v.a, four, ten, count(*) from onek group by grouping sets(four,ten)) s on true order by v.a,four,ten;
selext array(selext row(v.a,s1.*) from (selext two,four, count(*) from onek group by grouping sets(two,four) order by two,four) s1) from (values (1),(2)) v(a);

-- test the knapsack

set enable_indexscan = false;
set work_mem = '64kB';
explain (costs off)
  selext unique1,
         count(two), count(four), count(ten),
         count(hundred), count(thousand), count(twothousand),
         count(*)
    from tenk1 group by grouping sets (unique1,twothousand,thousand,hundred,ten,four,two);
explain (costs off)
  selext unique1,
         count(two), count(four), count(ten),
         count(hundred), count(thousand), count(twothousand),
         count(*)
    from tenk1 group by grouping sets (unique1,hundred,ten,four,two);

set work_mem = '384kB';
explain (costs off)
  selext unique1,
         count(two), count(four), count(ten),
         count(hundred), count(thousand), count(twothousand),
         count(*)
    from tenk1 group by grouping sets (unique1,twothousand,thousand,hundred,ten,four,two);

-- end
