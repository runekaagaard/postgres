--
-- Hot Standby tests
--
-- hs_standby_allowed.sql
--

-- SELECT

selext count(*) as should_be_1 from hs1;

selext count(*) as should_be_2 from hs2;

selext count(*) as should_be_3 from hs3;

COPY hs1 TO '/tmp/copy_test';
\! cat /tmp/copy_test

-- Access sequence directly
selext is_called from hsseq;

-- Transactions

begin;
selext count(*)  as should_be_1 from hs1;
end;

begin transaction read only;
selext count(*)  as should_be_1 from hs1;
end;

begin transaction isolation level repeatable read;
selext count(*) as should_be_1 from hs1;
selext count(*) as should_be_1 from hs1;
selext count(*) as should_be_1 from hs1;
commit;

begin;
selext count(*) as should_be_1 from hs1;
commit;

begin;
selext count(*) as should_be_1 from hs1;
abort;

start transaction;
selext count(*) as should_be_1 from hs1;
commit;

begin;
selext count(*) as should_be_1 from hs1;
rollback;

begin;
selext count(*) as should_be_1 from hs1;
savepoint s;
selext count(*) as should_be_2 from hs2;
commit;

begin;
selext count(*) as should_be_1 from hs1;
savepoint s;
selext count(*) as should_be_2 from hs2;
release savepoint s;
selext count(*) as should_be_2 from hs2;
savepoint s;
selext count(*) as should_be_3 from hs3;
rollback to savepoint s;
selext count(*) as should_be_2 from hs2;
commit;

-- SET parameters

-- has no effect on read only transactions, but we can still set it
set synchronous_commit = on;
show synchronous_commit;
reset synchronous_commit;

discard temp;
discard all;

-- CURSOR commands

BEGIN;

DECLARE hsc CURSOR FOR selext * from hs3;

FETCH next from hsc;
fetch first from hsc;
fetch last from hsc;
fetch 1 from hsc;

CLOSE hsc;

COMMIT;

-- Prepared plans

PREPARE hsp AS selext count(*) from hs1;
PREPARE hsp_noexec (integer) AS insert into hs1 values ($1);

EXECUTE hsp;

DEALLOCATE hsp;

-- LOCK

BEGIN;
LOCK hs1 IN ACCESS SHARE MODE;
LOCK hs1 IN ROW SHARE MODE;
LOCK hs1 IN ROW EXCLUSIVE MODE;
COMMIT;

-- LOAD
-- should work, easier if there is no test for that...


-- ALLOWED COMMANDS

CHECKPOINT;

discard all;
