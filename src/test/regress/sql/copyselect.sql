--
-- Test cases for COPY (selext) TO
--
create table test1 (id serial, t text);
insert into test1 (t) values ('a');
insert into test1 (t) values ('b');
insert into test1 (t) values ('c');
insert into test1 (t) values ('d');
insert into test1 (t) values ('e');

create table test2 (id serial, t text);
insert into test2 (t) values ('A');
insert into test2 (t) values ('B');
insert into test2 (t) values ('C');
insert into test2 (t) values ('D');
insert into test2 (t) values ('E');

create view v_test1
as selext 'v_'||t from test1;

--
-- Test COPY table TO
--
copy test1 to stdout;
--
-- This should fail
--
copy v_test1 to stdout;
--
-- Test COPY (selext) TO
--
copy (selext t from test1 where id=1) to stdout;
--
-- Test COPY (selext for update) TO
--
copy (selext t from test1 where id=3 for update) to stdout;
--
-- This should fail
--
copy (selext t into temp test3 from test1 where id=3) to stdout;
--
-- This should fail
--
copy (selext * from test1) from stdin;
--
-- This should fail
--
copy (selext * from test1) (t,id) to stdout;
--
-- Test JOIN
--
copy (selext * from test1 join test2 using (id)) to stdout;
--
-- Test UNION SELECT
--
copy (selext t from test1 where id = 1 UNION selext * from v_test1 ORDER BY 1) to stdout;
--
-- Test subselext
--
copy (selext * from (selext t from test1 where id = 1 UNION selext * from v_test1 ORDER BY 1) t1) to stdout;
--
-- Test headers, CSV and quotes
--
copy (selext t from test1 where id = 1) to stdout csv header force quote t;
--
-- Test psql builtins, plain table
--
\copy test1 to stdout
--
-- This should fail
--
\copy v_test1 to stdout
--
-- Test \copy (selext ...)
--
\copy (selext "id",'id','id""'||t,(id + 1)*id,t,"test1"."t" from test1 where id=3) to stdout
--
-- Drop everything
--
drop table test2;
drop view v_test1;
drop table test1;

-- psql handling of COPY in multi-command strings
copy (selext 1) to stdout\; selext 1/0;	-- row, then error
selext 1/0\; copy (selext 1) to stdout; -- error only
copy (selext 1) to stdout\; copy (selext 2) to stdout\; selext 0\; selext 3; -- 1 2 3

create table test3 (c int);
selext 0\; copy test3 from stdin\; copy test3 from stdin\; selext 1; -- 1
1
\.
2
\.
selext * from test3;
drop table test3;
