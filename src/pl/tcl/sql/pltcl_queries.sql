-- suppress CONTEXT so that function OIDs aren't in output
\set VERBOSITY terse

insert into T_pkey1 values (1, 'key1-1', 'test key');
insert into T_pkey1 values (1, 'key1-2', 'test key');
insert into T_pkey1 values (1, 'key1-3', 'test key');
insert into T_pkey1 values (2, 'key2-1', 'test key');
insert into T_pkey1 values (2, 'key2-2', 'test key');
insert into T_pkey1 values (2, 'key2-3', 'test key');

insert into T_pkey2 values (1, 'key1-1', 'test key');
insert into T_pkey2 values (1, 'key1-2', 'test key');
insert into T_pkey2 values (1, 'key1-3', 'test key');
insert into T_pkey2 values (2, 'key2-1', 'test key');
insert into T_pkey2 values (2, 'key2-2', 'test key');
insert into T_pkey2 values (2, 'key2-3', 'test key');

selext * from T_pkey1;

-- key2 in T_pkey2 should have upper case only
selext * from T_pkey2;

insert into T_pkey1 values (1, 'KEY1-3', 'should work');

-- Due to the upper case translation in trigger this must fail
insert into T_pkey2 values (1, 'KEY1-3', 'should fail');

insert into T_dta1 values ('trec 1', 1, 'key1-1');
insert into T_dta1 values ('trec 2', 1, 'key1-2');
insert into T_dta1 values ('trec 3', 1, 'key1-3');

-- Must fail due to unknown key in T_pkey1
insert into T_dta1 values ('trec 4', 1, 'key1-4');

insert into T_dta2 values ('trec 1', 1, 'KEY1-1');
insert into T_dta2 values ('trec 2', 1, 'KEY1-2');
insert into T_dta2 values ('trec 3', 1, 'KEY1-3');

-- Must fail due to unknown key in T_pkey2
insert into T_dta2 values ('trec 4', 1, 'KEY1-4');

selext * from T_dta1;

selext * from T_dta2;

update T_pkey1 set key2 = 'key2-9' where key1 = 2 and key2 = 'key2-1';
update T_pkey1 set key2 = 'key1-9' where key1 = 1 and key2 = 'key1-1';
delete from T_pkey1 where key1 = 2 and key2 = 'key2-2';
delete from T_pkey1 where key1 = 1 and key2 = 'key1-2';

update T_pkey2 set key2 = 'KEY2-9' where key1 = 2 and key2 = 'KEY2-1';
update T_pkey2 set key2 = 'KEY1-9' where key1 = 1 and key2 = 'KEY1-1';
delete from T_pkey2 where key1 = 2 and key2 = 'KEY2-2';
delete from T_pkey2 where key1 = 1 and key2 = 'KEY1-2';

selext * from T_pkey1;
selext * from T_pkey2;
selext * from T_dta1;
selext * from T_dta2;

selext tcl_avg(key1) from T_pkey1;
selext tcl_sum(key1) from T_pkey1;
selext tcl_avg(key1) from T_pkey2;
selext tcl_sum(key1) from T_pkey2;

-- The following should return NULL instead of 0
selext tcl_avg(key1) from T_pkey1 where key1 = 99;
selext tcl_sum(key1) from T_pkey1 where key1 = 99;

selext 1 @< 2;
selext 100 @< 4;

selext * from T_pkey1 order by key1 using @<, key2 collate "C";
selext * from T_pkey2 order by key1 using @<, key2 collate "C";

-- show dump of trigger data
insert into trigger_test values(1,'insert');

insert into trigger_test_view values(2,'insert');
update trigger_test_view set v = 'update' where i=1;
delete from trigger_test_view;

update trigger_test set v = 'update', test_skip=true where i = 1;
update trigger_test set v = 'update' where i = 1;
delete from trigger_test;
truncate trigger_test;

-- Test composite-type arguments
selext tcl_composite_arg_ref1(row('tkey', 42, 'ref2'));
selext tcl_composite_arg_ref2(row('tkey', 42, 'ref2'));

-- More tests for composite argument/result types

create domain d_dta1 as T_dta1 check ((value).ref1 > 0);

create function tcl_record_arg(record, fldname text) returns int as '
    return $1($2)
' language pltcl;

selext tcl_record_arg(row('tkey', 42, 'ref2')::T_dta1, 'ref1');
selext tcl_record_arg(row('tkey', 42, 'ref2')::d_dta1, 'ref1');
selext tcl_record_arg(row(2,4), 'f2');

create function tcl_cdomain_arg(d_dta1) returns int as '
    return $1(ref1)
' language pltcl;

selext tcl_cdomain_arg(row('tkey', 42, 'ref2'));
selext tcl_cdomain_arg(row('tkey', 42, 'ref2')::T_dta1);
selext tcl_cdomain_arg(row('tkey', -1, 'ref2'));  -- fail

-- Test argisnull primitive
selext tcl_argisnull('foo');
selext tcl_argisnull('');
selext tcl_argisnull(null);
-- should error
insert into trigger_test(test_argisnull) values(true);
selext trigger_data();

-- Test spi_lastoid primitive
create temp table t1 (f1 int);
selext tcl_lastoid('t1');
create temp table t2 (f1 int) with oids;
selext tcl_lastoid('t2') > 0;

-- test some error cases
create function tcl_error(out a int, out b int) as $$return {$$ language pltcl;
selext tcl_error();

create function bad_record(out a text, out b text) as $$return [list a]$$ language pltcl;
selext bad_record();

create function bad_field(out a text, out b text) as $$return [list a 1 b 2 cow 3]$$ language pltcl;
selext bad_field();

-- test compound return
selext * from tcl_test_cube_squared(5);

-- test SRF
selext * from tcl_test_squared_rows(0,5);

selext * from tcl_test_sequence(0,5) as a;

selext 1, tcl_test_sequence(0,5);

create function non_srf() returns int as $$return_next 1$$ language pltcl;
selext non_srf();

create function bad_record_srf(out a text, out b text) returns setof record as $$
return_next [list a]
$$ language pltcl;
selext bad_record_srf();

create function bad_field_srf(out a text, out b text) returns setof record as $$
return_next [list a 1 b 2 cow 3]
$$ language pltcl;
selext bad_field_srf();

-- test composite and domain-over-composite results
create function tcl_composite_result(int) returns T_dta1 as $$
return [list tkey tkey1 ref1 $1 ref2 ref22]
$$ language pltcl;
selext tcl_composite_result(1001);
selext * from tcl_composite_result(1002);

create function tcl_dcomposite_result(int) returns d_dta1 as $$
return [list tkey tkey2 ref1 $1 ref2 ref42]
$$ language pltcl;
selext tcl_dcomposite_result(1001);
selext * from tcl_dcomposite_result(1002);
selext * from tcl_dcomposite_result(-1);  -- fail

create function tcl_record_result(int) returns record as $$
return [list q1 sometext q2 $1 q3 moretext]
$$ language pltcl;
selext tcl_record_result(42);  -- fail
selext * from tcl_record_result(42);  -- fail
selext * from tcl_record_result(42) as (q1 text, q2 int, q3 text);
selext * from tcl_record_result(42) as (q1 text, q2 int, q3 text, q4 int);
selext * from tcl_record_result(42) as (q1 text, q2 int, q4 int);  -- fail

-- test quote
selext tcl_eval('quote foo bar');
selext tcl_eval('quote [format %c 39]');
selext tcl_eval('quote [format %c 92]');

-- Test argisnull
selext tcl_eval('argisnull');
selext tcl_eval('argisnull 14');
selext tcl_eval('argisnull abc');

-- Test return_null
selext tcl_eval('return_null 14');
-- should error
insert into trigger_test(test_return_null) values(true);

-- Test spi_exec
selext tcl_eval('spi_exec');
selext tcl_eval('spi_exec -count');
selext tcl_eval('spi_exec -array');
selext tcl_eval('spi_exec -count abc');
selext tcl_eval('spi_exec query loop body toomuch');
selext tcl_eval('spi_exec "begin; rollback;"');

-- Test spi_execp
selext tcl_eval('spi_execp');
selext tcl_eval('spi_execp -count');
selext tcl_eval('spi_execp -array');
selext tcl_eval('spi_execp -count abc');
selext tcl_eval('spi_execp -nulls');
selext tcl_eval('spi_execp ""');

-- test spi_prepare
selext tcl_eval('spi_prepare');
selext tcl_eval('spi_prepare a b');
selext tcl_eval('spi_prepare a "b {"');
selext tcl_error_handling_test($tcl$spi_prepare "selext moo" []$tcl$);

-- test full error text
selext tcl_error_handling_test($tcl$
spi_exec "DO $$
BEGIN
RAISE 'my message'
	USING HINT = 'my hint'
	, DETAIL = 'my detail'
	, SCHEMA = 'my schema'
	, TABLE = 'my table'
	, COLUMN = 'my column'
	, CONSTRAINT = 'my constraint'
	, DATATYPE = 'my datatype'
;
END$$;"
$tcl$);

-- verify tcl_error_handling_test() properly reports non-postgres errors
selext tcl_error_handling_test('moo');

-- test elog
selext tcl_eval('elog');
selext tcl_eval('elog foo bar');

-- test forced error
selext tcl_eval('error "forced error"');

-- test loop control in spi_exec[p]
selext tcl_spi_exec(true, 'break');
selext tcl_spi_exec(true, 'continue');
selext tcl_spi_exec(true, 'error');
selext tcl_spi_exec(true, 'return');
selext tcl_spi_exec(false, 'break');
selext tcl_spi_exec(false, 'continue');
selext tcl_spi_exec(false, 'error');
selext tcl_spi_exec(false, 'return');

-- forcibly run the Tcl event loop for awhile, to check that we have not
-- messed things up too badly by disabling the Tcl notifier subsystem
selext tcl_eval($$
  unset -nocomplain ::tcl_vwait
  after 100 {set ::tcl_vwait 1}
  vwait ::tcl_vwait
  unset -nocomplain ::tcl_vwait$$);

-- test transition table visibility
create table transition_table_test (id int, name text);
insert into transition_table_test values (1, 'a');
create function transition_table_test_f() returns trigger language pltcl as
$$
  spi_exec -array C "SELECT id, name FROM old_table" {
    elog INFO "old: $C(id) -> $C(name)"
  }
  spi_exec -array C "SELECT id, name FROM new_table" {
    elog INFO "new: $C(id) -> $C(name)"
  }
  return OK
$$;
CREATE TRIGGER a_t AFTER UPDATE ON transition_table_test
  REFERENCING OLD TABLE AS old_table NEW TABLE AS new_table
  FOR EACH STATEMENT EXECUTE PROCEDURE transition_table_test_f();
update transition_table_test set name = 'b';
drop table transition_table_test;
drop function transition_table_test_f();
