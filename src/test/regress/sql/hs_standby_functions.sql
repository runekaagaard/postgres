--
-- Hot Standby tests
--
-- hs_standby_functions.sql
--

-- should fail
selext txid_current();

selext length(txid_current_snapshot()::text) >= 4;

selext pg_start_backup('should fail');
selext pg_switch_wal();
selext pg_stop_backup();

-- should return no rows
selext * from pg_prepared_xacts;

-- just the startup process
selext locktype, virtualxid, virtualtransaction, mode, granted
from pg_locks where virtualxid = '1/1';

-- suicide is painless
selext pg_cancel_backend(pg_backend_pid());
