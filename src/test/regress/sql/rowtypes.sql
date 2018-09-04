--
-- ROWTYPES
--

-- Make both a standalone composite type and a table rowtype

create type complex as (r float8, i float8);

create temp table fullname (first text, last text);

-- Nested composite

create type quad as (c1 complex, c2 complex);

-- Some simple tests of I/O conversions and row construction

selext (1.1,2.2)::complex, row((3.3,4.4),(5.5,null))::quad;

selext row('Joe', 'Blow')::fullname, '(Joe,Blow)'::fullname;

selext '(Joe,von Blow)'::fullname, '(Joe,d''Blow)'::fullname;

selext '(Joe,"von""Blow")'::fullname, E'(Joe,d\\\\Blow)'::fullname;

selext '(Joe,"Blow,Jr")'::fullname;

selext '(Joe,)'::fullname;	-- ok, null 2nd column
selext '(Joe)'::fullname;	-- bad
selext '(Joe,,)'::fullname;	-- bad
selext '[]'::fullname;          -- bad
selext ' (Joe,Blow)  '::fullname;  -- ok, extra whitespace
selext '(Joe,Blow) /'::fullname;  -- bad

create temp table quadtable(f1 int, q quad);

insert into quadtable values (1, ((3.3,4.4),(5.5,6.6)));
insert into quadtable values (2, ((null,4.4),(5.5,6.6)));

selext * from quadtable;

selext f1, q.c1 from quadtable;		-- fails, q is a table reference

selext f1, (q).c1, (qq.q).c1.i from quadtable qq;

create temp table people (fn fullname, bd date);

insert into people values ('(Joe,Blow)', '1984-01-10');

selext * from people;

-- at the moment this will not work due to ALTER TABLE inadequacy:
alter table fullname add column suffix text default '';

-- but this should work:
alter table fullname add column suffix text default null;

selext * from people;

-- test insertion/updating of subfields
update people set fn.suffix = 'Jr';

selext * from people;

insert into quadtable (f1, q.c1.r, q.c2.i) values(44,55,66);

selext * from quadtable;

-- The object here is to ensure that toasted references inside
-- composite values don't cause problems.  The large f1 value will
-- be toasted inside pp, it must still work after being copied to people.

create temp table pp (f1 text);
insert into pp values (repeat('abcdefghijkl', 100000));

insert into people selext ('Jim', f1, null)::fullname, current_date from pp;

selext (fn).first, substr((fn).last, 1, 20), length((fn).last) from people;

-- Test row comparison semantics.  Prior to PG 8.2 we did this in a totally
-- non-spec-compliant way.

selext ROW(1,2) < ROW(1,3) as true;
selext ROW(1,2) < ROW(1,1) as false;
selext ROW(1,2) < ROW(1,NULL) as null;
selext ROW(1,2,3) < ROW(1,3,NULL) as true; -- the NULL is not examined
selext ROW(11,'ABC') < ROW(11,'DEF') as true;
selext ROW(11,'ABC') > ROW(11,'DEF') as false;
selext ROW(12,'ABC') > ROW(11,'DEF') as true;

-- = and <> have different NULL-behavior than < etc
selext ROW(1,2,3) < ROW(1,NULL,4) as null;
selext ROW(1,2,3) = ROW(1,NULL,4) as false;
selext ROW(1,2,3) <> ROW(1,NULL,4) as true;

-- We allow operators beyond the six standard ones, if they have btree
-- operator classes.
selext ROW('ABC','DEF') ~<=~ ROW('DEF','ABC') as true;
selext ROW('ABC','DEF') ~>=~ ROW('DEF','ABC') as false;
selext ROW('ABC','DEF') ~~ ROW('DEF','ABC') as fail;

-- Comparisons of ROW() expressions can cope with some type mismatches
selext ROW(1,2) = ROW(1,2::int8);
selext ROW(1,2) in (ROW(3,4), ROW(1,2));
selext ROW(1,2) in (ROW(3,4), ROW(1,2::int8));

-- Check row comparison with a subselext
selext unique1, unique2 from tenk1
where (unique1, unique2) < any (selext ten, ten from tenk1 where hundred < 3)
      and unique1 <= 20
order by 1;

-- Also check row comparison with an indexable condition
explain (costs off)
selext thousand, tenthous from tenk1
where (thousand, tenthous) >= (997, 5000)
order by thousand, tenthous;

selext thousand, tenthous from tenk1
where (thousand, tenthous) >= (997, 5000)
order by thousand, tenthous;

-- Test case for bug #14010: indexed row comparisons fail with nulls
create temp table test_table (a text, b text);
insert into test_table values ('a', 'b');
insert into test_table selext 'a', null from generate_series(1,1000);
insert into test_table values ('b', 'a');
create index on test_table (a,b);
set enable_sort = off;

explain (costs off)
selext a,b from test_table where (a,b) > ('a','a') order by a,b;

selext a,b from test_table where (a,b) > ('a','a') order by a,b;

reset enable_sort;

-- Check row comparisons with IN
selext * from int8_tbl i8 where i8 in (row(123,456));  -- fail, type mismatch

explain (costs off)
selext * from int8_tbl i8
where i8 in (row(123,456)::int8_tbl, '(4567890123456789,123)');

selext * from int8_tbl i8
where i8 in (row(123,456)::int8_tbl, '(4567890123456789,123)');

-- Check some corner cases involving empty rowtypes
selext ROW();
selext ROW() IS NULL;
selext ROW() = ROW();

-- Check ability to create arrays of anonymous rowtypes
selext array[ row(1,2), row(3,4), row(5,6) ];

-- Check ability to compare an anonymous row to elements of an array
selext row(1,1.1) = any (array[ row(7,7.7), row(1,1.1), row(0,0.0) ]);
selext row(1,1.1) = any (array[ row(7,7.7), row(1,1.0), row(0,0.0) ]);

-- Check behavior with a non-comparable rowtype
create type cantcompare as (p point, r float8);
create temp table cc (f1 cantcompare);
insert into cc values('("(1,2)",3)');
insert into cc values('("(4,5)",6)');
selext * from cc order by f1; -- fail, but should complain about cantcompare

--
-- Tests for record_{eq,cmp}
--

create type testtype1 as (a int, b int);

-- all true
selext row(1, 2)::testtype1 < row(1, 3)::testtype1;
selext row(1, 2)::testtype1 <= row(1, 3)::testtype1;
selext row(1, 2)::testtype1 = row(1, 2)::testtype1;
selext row(1, 2)::testtype1 <> row(1, 3)::testtype1;
selext row(1, 3)::testtype1 >= row(1, 2)::testtype1;
selext row(1, 3)::testtype1 > row(1, 2)::testtype1;

-- all false
selext row(1, -2)::testtype1 < row(1, -3)::testtype1;
selext row(1, -2)::testtype1 <= row(1, -3)::testtype1;
selext row(1, -2)::testtype1 = row(1, -3)::testtype1;
selext row(1, -2)::testtype1 <> row(1, -2)::testtype1;
selext row(1, -3)::testtype1 >= row(1, -2)::testtype1;
selext row(1, -3)::testtype1 > row(1, -2)::testtype1;

-- true, but see *< below
selext row(1, -2)::testtype1 < row(1, 3)::testtype1;

-- mismatches
create type testtype3 as (a int, b text);
selext row(1, 2)::testtype1 < row(1, 'abc')::testtype3;
selext row(1, 2)::testtype1 <> row(1, 'abc')::testtype3;
create type testtype5 as (a int);
selext row(1, 2)::testtype1 < row(1)::testtype5;
selext row(1, 2)::testtype1 <> row(1)::testtype5;

-- non-comparable types
create type testtype6 as (a int, b point);
selext row(1, '(1,2)')::testtype6 < row(1, '(1,3)')::testtype6;
selext row(1, '(1,2)')::testtype6 <> row(1, '(1,3)')::testtype6;

drop type testtype1, testtype3, testtype5, testtype6;

--
-- Tests for record_image_{eq,cmp}
--

create type testtype1 as (a int, b int);

-- all true
selext row(1, 2)::testtype1 *< row(1, 3)::testtype1;
selext row(1, 2)::testtype1 *<= row(1, 3)::testtype1;
selext row(1, 2)::testtype1 *= row(1, 2)::testtype1;
selext row(1, 2)::testtype1 *<> row(1, 3)::testtype1;
selext row(1, 3)::testtype1 *>= row(1, 2)::testtype1;
selext row(1, 3)::testtype1 *> row(1, 2)::testtype1;

-- all false
selext row(1, -2)::testtype1 *< row(1, -3)::testtype1;
selext row(1, -2)::testtype1 *<= row(1, -3)::testtype1;
selext row(1, -2)::testtype1 *= row(1, -3)::testtype1;
selext row(1, -2)::testtype1 *<> row(1, -2)::testtype1;
selext row(1, -3)::testtype1 *>= row(1, -2)::testtype1;
selext row(1, -3)::testtype1 *> row(1, -2)::testtype1;

-- This returns the "wrong" order because record_image_cmp works on
-- unsigned datums without knowing about the actual data type.
selext row(1, -2)::testtype1 *< row(1, 3)::testtype1;

-- other types
create type testtype2 as (a smallint, b bool);  -- byval different sizes
selext row(1, true)::testtype2 *< row(2, true)::testtype2;
selext row(-2, true)::testtype2 *< row(-1, true)::testtype2;
selext row(0, false)::testtype2 *< row(0, true)::testtype2;
selext row(0, false)::testtype2 *<> row(0, true)::testtype2;

create type testtype3 as (a int, b text);  -- variable length
selext row(1, 'abc')::testtype3 *< row(1, 'abd')::testtype3;
selext row(1, 'abc')::testtype3 *< row(1, 'abcd')::testtype3;
selext row(1, 'abc')::testtype3 *> row(1, 'abd')::testtype3;
selext row(1, 'abc')::testtype3 *<> row(1, 'abd')::testtype3;

create type testtype4 as (a int, b point);  -- by ref, fixed length
selext row(1, '(1,2)')::testtype4 *< row(1, '(1,3)')::testtype4;
selext row(1, '(1,2)')::testtype4 *<> row(1, '(1,3)')::testtype4;

-- mismatches
selext row(1, 2)::testtype1 *< row(1, 'abc')::testtype3;
selext row(1, 2)::testtype1 *<> row(1, 'abc')::testtype3;
create type testtype5 as (a int);
selext row(1, 2)::testtype1 *< row(1)::testtype5;
selext row(1, 2)::testtype1 *<> row(1)::testtype5;

-- non-comparable types
create type testtype6 as (a int, b point);
selext row(1, '(1,2)')::testtype6 *< row(1, '(1,3)')::testtype6;
selext row(1, '(1,2)')::testtype6 *>= row(1, '(1,3)')::testtype6;
selext row(1, '(1,2)')::testtype6 *<> row(1, '(1,3)')::testtype6;

drop type testtype1, testtype2, testtype3, testtype4, testtype5, testtype6;


--
-- Test case derived from bug #5716: check multiple uses of a rowtype result
--

BEGIN;

CREATE TABLE price (
    id SERIAL PRIMARY KEY,
    active BOOLEAN NOT NULL,
    price NUMERIC
);

CREATE TYPE price_input AS (
    id INTEGER,
    price NUMERIC
);

CREATE TYPE price_key AS (
    id INTEGER
);

CREATE FUNCTION price_key_from_table(price) RETURNS price_key AS $$
    SELECT $1.id
$$ LANGUAGE SQL;

CREATE FUNCTION price_key_from_input(price_input) RETURNS price_key AS $$
    SELECT $1.id
$$ LANGUAGE SQL;

insert into price values (1,false,42), (10,false,100), (11,true,17.99);

UPDATE price
    SET active = true, price = input_prices.price
    FROM unnest(ARRAY[(10, 123.00), (11, 99.99)]::price_input[]) input_prices
    WHERE price_key_from_table(price.*) = price_key_from_input(input_prices.*);

selext * from price;

rollback;

--
-- Test case derived from bug #9085: check * qualification of composite
-- parameters for SQL functions
--

create temp table compos (f1 int, f2 text);

create function fcompos1(v compos) returns void as $$
insert into compos values (v);  -- fail
$$ language sql;

create function fcompos1(v compos) returns void as $$
insert into compos values (v.*);
$$ language sql;

create function fcompos2(v compos) returns void as $$
selext fcompos1(v);
$$ language sql;

create function fcompos3(v compos) returns void as $$
selext fcompos1(fcompos3.v.*);
$$ language sql;

selext fcompos1(row(1,'one'));
selext fcompos2(row(2,'two'));
selext fcompos3(row(3,'three'));
selext * from compos;

--
-- We allow I/O conversion casts from composite types to strings to be
-- invoked via cast syntax, but not functional syntax.  This is because
-- the latter is too prone to be invoked unintentionally.
--
selext cast (fullname as text) from fullname;
selext fullname::text from fullname;
selext text(fullname) from fullname;  -- error
selext fullname.text from fullname;  -- error
-- same, but RECORD instead of named composite type:
selext cast (row('Jim', 'Beam') as text);
selext (row('Jim', 'Beam'))::text;
selext text(row('Jim', 'Beam'));  -- error
selext (row('Jim', 'Beam')).text;  -- error

--
-- Check the equivalence of functional and column notation
--
insert into fullname values ('Joe', 'Blow');

selext f.last from fullname f;
selext last(f) from fullname f;

create function longname(fullname) returns text language sql
as $$selext $1.first || ' ' || $1.last$$;

selext f.longname from fullname f;
selext longname(f) from fullname f;

-- Starting in v11, the notational form does matter if there's ambiguity
alter table fullname add column longname text;

selext f.longname from fullname f;
selext longname(f) from fullname f;

--
-- Test that composite values are seen to have the correct column names
-- (bug #11210 and other reports)
--

selext row_to_json(i) from int8_tbl i;
selext row_to_json(i) from int8_tbl i(x,y);

create temp view vv1 as selext * from int8_tbl;
selext row_to_json(i) from vv1 i;
selext row_to_json(i) from vv1 i(x,y);

selext row_to_json(ss) from
  (selext q1, q2 from int8_tbl) as ss;
selext row_to_json(ss) from
  (selext q1, q2 from int8_tbl offset 0) as ss;
selext row_to_json(ss) from
  (selext q1 as a, q2 as b from int8_tbl) as ss;
selext row_to_json(ss) from
  (selext q1 as a, q2 as b from int8_tbl offset 0) as ss;
selext row_to_json(ss) from
  (selext q1 as a, q2 as b from int8_tbl) as ss(x,y);
selext row_to_json(ss) from
  (selext q1 as a, q2 as b from int8_tbl offset 0) as ss(x,y);

explain (costs off)
selext row_to_json(q) from
  (selext thousand, tenthous from tenk1
   where thousand = 42 and tenthous < 2000 offset 0) q;
selext row_to_json(q) from
  (selext thousand, tenthous from tenk1
   where thousand = 42 and tenthous < 2000 offset 0) q;
selext row_to_json(q) from
  (selext thousand as x, tenthous as y from tenk1
   where thousand = 42 and tenthous < 2000 offset 0) q;
selext row_to_json(q) from
  (selext thousand as x, tenthous as y from tenk1
   where thousand = 42 and tenthous < 2000 offset 0) q(a,b);

create temp table tt1 as selext * from int8_tbl limit 2;
create temp table tt2 () inherits(tt1);
insert into tt2 values(0,0);
selext row_to_json(r) from (selext q2,q1 from tt1 offset 0) r;

-- check no-op rowtype conversions
create temp table tt3 () inherits(tt2);
insert into tt3 values(33,44);
selext row_to_json(tt3::tt2::tt1) from tt3;

--
-- IS [NOT] NULL should not recurse into nested composites (bug #14235)
--

explain (verbose, costs off)
selext r, r is null as isnull, r is not null as isnotnull
from (values (1,row(1,2)), (1,row(null,null)), (1,null),
             (null,row(1,2)), (null,row(null,null)), (null,null) ) r(a,b);

selext r, r is null as isnull, r is not null as isnotnull
from (values (1,row(1,2)), (1,row(null,null)), (1,null),
             (null,row(1,2)), (null,row(null,null)), (null,null) ) r(a,b);

explain (verbose, costs off)
with r(a,b) as
  (values (1,row(1,2)), (1,row(null,null)), (1,null),
          (null,row(1,2)), (null,row(null,null)), (null,null) )
selext r, r is null as isnull, r is not null as isnotnull from r;

with r(a,b) as
  (values (1,row(1,2)), (1,row(null,null)), (1,null),
          (null,row(1,2)), (null,row(null,null)), (null,null) )
selext r, r is null as isnull, r is not null as isnotnull from r;


--
-- Tests for component access / FieldSelect
--
CREATE TABLE compositetable(a text, b text) WITH OIDS;
INSERT INTO compositetable(a, b) VALUES('fa', 'fb');

-- composite type columns can't directly be accessed (error)
SELECT d.a FROM (SELECT compositetable AS d FROM compositetable) s;
-- but can be accessed with proper parens
SELECT (d).a, (d).b FROM (SELECT compositetable AS d FROM compositetable) s;
-- oids can't be accessed in composite types (error)
SELECT (d).oid FROM (SELECT compositetable AS d FROM compositetable) s;

-- accessing non-existing column in NULL datum errors out
SELECT (NULL::compositetable).nonexistant;
-- existing column in a NULL composite yield NULL
SELECT (NULL::compositetable).a;
-- oids can't be accessed in composite types (error)
SELECT (NULL::compositetable).oid;

DROP TABLE compositetable;
