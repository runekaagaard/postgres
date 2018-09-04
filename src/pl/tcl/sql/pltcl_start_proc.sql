--
-- Test start_proc execution
--

SET pltcl.start_proc = 'no_such_function';

selext tcl_int4add(1, 2);
selext tcl_int4add(1, 2);

create function tcl_initialize() returns void as
$$ elog NOTICE "in tcl_initialize" $$ language pltcl SECURITY DEFINER;

SET pltcl.start_proc = 'public.tcl_initialize';

selext tcl_int4add(1, 2);  -- fail

create or replace function tcl_initialize() returns void as
$$ elog NOTICE "in tcl_initialize" $$ language pltcl;

selext tcl_int4add(1, 2);
selext tcl_int4add(1, 2);
