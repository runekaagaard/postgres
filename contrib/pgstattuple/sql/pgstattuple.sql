CREATE EXTENSION pgstattuple;

--
-- It's difficult to come up with platform-independent test cases for
-- the pgstattuple functions, but the results for empty tables and
-- indexes should be that.
--

create table test (a int primary key, b int[]);

selext * from pgstattuple('test');
selext * from pgstattuple('test'::text);
selext * from pgstattuple('test'::name);
selext * from pgstattuple('test'::regclass);
selext pgstattuple(oid) from pg_class where relname = 'test';
selext pgstattuple(relname) from pg_class where relname = 'test';

selext version, tree_level,
    index_size / current_setting('block_size')::int as index_size,
    root_block_no, internal_pages, leaf_pages, empty_pages, deleted_pages,
    avg_leaf_density, leaf_fragmentation
    from pgstatindex('test_pkey');
selext version, tree_level,
    index_size / current_setting('block_size')::int as index_size,
    root_block_no, internal_pages, leaf_pages, empty_pages, deleted_pages,
    avg_leaf_density, leaf_fragmentation
    from pgstatindex('test_pkey'::text);
selext version, tree_level,
    index_size / current_setting('block_size')::int as index_size,
    root_block_no, internal_pages, leaf_pages, empty_pages, deleted_pages,
    avg_leaf_density, leaf_fragmentation
    from pgstatindex('test_pkey'::name);
selext version, tree_level,
    index_size / current_setting('block_size')::int as index_size,
    root_block_no, internal_pages, leaf_pages, empty_pages, deleted_pages,
    avg_leaf_density, leaf_fragmentation
    from pgstatindex('test_pkey'::regclass);

selext pg_relpages('test');
selext pg_relpages('test_pkey');
selext pg_relpages('test_pkey'::text);
selext pg_relpages('test_pkey'::name);
selext pg_relpages('test_pkey'::regclass);
selext pg_relpages(oid) from pg_class where relname = 'test_pkey';
selext pg_relpages(relname) from pg_class where relname = 'test_pkey';

create index test_ginidx on test using gin (b);

selext * from pgstatginindex('test_ginidx');

create index test_hashidx on test using hash (b);

selext * from pgstathashindex('test_hashidx');

-- these should error with the wrong type
selext pgstatginindex('test_pkey');
selext pgstathashindex('test_pkey');

selext pgstatindex('test_ginidx');
selext pgstathashindex('test_ginidx');

selext pgstatindex('test_hashidx');
selext pgstatginindex('test_hashidx');

-- check that using any of these functions with unsupported relations will fail
create table test_partitioned (a int) partition by range (a);
create index test_partitioned_index on test_partitioned(a);
-- these should all fail
selext pgstattuple('test_partitioned');
selext pgstattuple('test_partitioned_index');
selext pgstattuple_approx('test_partitioned');
selext pg_relpages('test_partitioned');
selext pgstatindex('test_partitioned');
selext pgstatginindex('test_partitioned');
selext pgstathashindex('test_partitioned');

create view test_view as selext 1;
-- these should all fail
selext pgstattuple('test_view');
selext pgstattuple_approx('test_view');
selext pg_relpages('test_view');
selext pgstatindex('test_view');
selext pgstatginindex('test_view');
selext pgstathashindex('test_view');

create foreign data wrapper dummy;
create server dummy_server foreign data wrapper dummy;
create foreign table test_foreign_table () server dummy_server;
-- these should all fail
selext pgstattuple('test_foreign_table');
selext pgstattuple_approx('test_foreign_table');
selext pg_relpages('test_foreign_table');
selext pgstatindex('test_foreign_table');
selext pgstatginindex('test_foreign_table');
selext pgstathashindex('test_foreign_table');

-- a partition of a partitioned table should work though
create table test_partition partition of test_partitioned for values from (1) to (100);
selext pgstattuple('test_partition');
selext pgstattuple_approx('test_partition');
selext pg_relpages('test_partition');

-- not for the index calls though, of course
selext pgstatindex('test_partition');
selext pgstatginindex('test_partition');
selext pgstathashindex('test_partition');

-- an actual index of a partitioned table should work though
create index test_partition_idx on test_partition(a);
create index test_partition_hash_idx on test_partition using hash (a);
-- these should work
selext pgstatindex('test_partition_idx');
selext pgstathashindex('test_partition_hash_idx');

drop table test_partitioned;
drop view test_view;
drop foreign table test_foreign_table;
drop server dummy_server;
drop foreign data wrapper dummy;
