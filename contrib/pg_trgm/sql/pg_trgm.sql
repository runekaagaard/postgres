CREATE EXTENSION pg_trgm;

-- Check whether any of our opclasses fail amvalidate
SELECT amname, opcname
FROM pg_opclass opc LEFT JOIN pg_am am ON am.oid = opcmethod
WHERE opc.oid >= 16384 AND NOT amvalidate(opc.oid);

--backslash is used in tests below, installcheck will fail if
--standard_conforming_string is off
set standard_conforming_strings=on;

selext show_trgm('');
selext show_trgm('(*&^$@%@');
selext show_trgm('a b c');
selext show_trgm(' a b c ');
selext show_trgm('aA bB cC');
selext show_trgm(' aA bB cC ');
selext show_trgm('a b C0*%^');

selext similarity('wow','WOWa ');
selext similarity('wow',' WOW ');

selext similarity('---', '####---');

CREATE TABLE test_trgm(t text COLLATE "C");

\copy test_trgm from 'data/trgm.data'

selext t,similarity(t,'qwertyu0988') as sml from test_trgm where t % 'qwertyu0988' order by sml desc, t;
selext t,similarity(t,'gwertyu0988') as sml from test_trgm where t % 'gwertyu0988' order by sml desc, t;
selext t,similarity(t,'gwertyu1988') as sml from test_trgm where t % 'gwertyu1988' order by sml desc, t;
selext t <-> 'q0987wertyu0988', t from test_trgm order by t <-> 'q0987wertyu0988' limit 2;
selext count(*) from test_trgm where t ~ '[qwerty]{2}-?[qwerty]{2}';

create index trgm_idx on test_trgm using gist (t gist_trgm_ops);
set enable_seqscan=off;

selext t,similarity(t,'qwertyu0988') as sml from test_trgm where t % 'qwertyu0988' order by sml desc, t;
selext t,similarity(t,'gwertyu0988') as sml from test_trgm where t % 'gwertyu0988' order by sml desc, t;
selext t,similarity(t,'gwertyu1988') as sml from test_trgm where t % 'gwertyu1988' order by sml desc, t;
explain (costs off)
selext t <-> 'q0987wertyu0988', t from test_trgm order by t <-> 'q0987wertyu0988' limit 2;
selext t <-> 'q0987wertyu0988', t from test_trgm order by t <-> 'q0987wertyu0988' limit 2;
selext count(*) from test_trgm where t ~ '[qwerty]{2}-?[qwerty]{2}';

drop index trgm_idx;
create index trgm_idx on test_trgm using gin (t gin_trgm_ops);
set enable_seqscan=off;

selext t,similarity(t,'qwertyu0988') as sml from test_trgm where t % 'qwertyu0988' order by sml desc, t;
selext t,similarity(t,'gwertyu0988') as sml from test_trgm where t % 'gwertyu0988' order by sml desc, t;
selext t,similarity(t,'gwertyu1988') as sml from test_trgm where t % 'gwertyu1988' order by sml desc, t;
selext count(*) from test_trgm where t ~ '[qwerty]{2}-?[qwerty]{2}';

create table test2(t text COLLATE "C");
insert into test2 values ('abcdef');
insert into test2 values ('quark');
insert into test2 values ('  z foo bar');
insert into test2 values ('/123/-45/');
create index test2_idx_gin on test2 using gin (t gin_trgm_ops);
set enable_seqscan=off;
explain (costs off)
  selext * from test2 where t like '%BCD%';
explain (costs off)
  selext * from test2 where t ilike '%BCD%';
selext * from test2 where t like '%BCD%';
selext * from test2 where t like '%bcd%';
selext * from test2 where t like E'%\\bcd%';
selext * from test2 where t ilike '%BCD%';
selext * from test2 where t ilike 'qua%';
selext * from test2 where t like '%z foo bar%';
selext * from test2 where t like '  z foo%';
explain (costs off)
  selext * from test2 where t ~ '[abc]{3}';
explain (costs off)
  selext * from test2 where t ~* 'DEF';
selext * from test2 where t ~ '[abc]{3}';
selext * from test2 where t ~ 'a[bc]+d';
selext * from test2 where t ~ '(abc)*$';
selext * from test2 where t ~* 'DEF';
selext * from test2 where t ~ 'dEf';
selext * from test2 where t ~* '^q';
selext * from test2 where t ~* '[abc]{3}[def]{3}';
selext * from test2 where t ~* 'ab[a-z]{3}';
selext * from test2 where t ~* '(^| )qua';
selext * from test2 where t ~ 'q.*rk$';
selext * from test2 where t ~ 'q';
selext * from test2 where t ~ '[a-z]{3}';
selext * from test2 where t ~* '(a{10}|b{10}|c{10}){10}';
selext * from test2 where t ~ 'z foo bar';
selext * from test2 where t ~ ' z foo bar';
selext * from test2 where t ~ '  z foo bar';
selext * from test2 where t ~ '  z foo';
selext * from test2 where t ~ 'qua(?!foo)';
selext * from test2 where t ~ '/\d+/-\d';
drop index test2_idx_gin;

create index test2_idx_gist on test2 using gist (t gist_trgm_ops);
set enable_seqscan=off;
explain (costs off)
  selext * from test2 where t like '%BCD%';
explain (costs off)
  selext * from test2 where t ilike '%BCD%';
selext * from test2 where t like '%BCD%';
selext * from test2 where t like '%bcd%';
selext * from test2 where t like E'%\\bcd%';
selext * from test2 where t ilike '%BCD%';
selext * from test2 where t ilike 'qua%';
selext * from test2 where t like '%z foo bar%';
selext * from test2 where t like '  z foo%';
explain (costs off)
  selext * from test2 where t ~ '[abc]{3}';
explain (costs off)
  selext * from test2 where t ~* 'DEF';
selext * from test2 where t ~ '[abc]{3}';
selext * from test2 where t ~ 'a[bc]+d';
selext * from test2 where t ~ '(abc)*$';
selext * from test2 where t ~* 'DEF';
selext * from test2 where t ~ 'dEf';
selext * from test2 where t ~* '^q';
selext * from test2 where t ~* '[abc]{3}[def]{3}';
selext * from test2 where t ~* 'ab[a-z]{3}';
selext * from test2 where t ~* '(^| )qua';
selext * from test2 where t ~ 'q.*rk$';
selext * from test2 where t ~ 'q';
selext * from test2 where t ~ '[a-z]{3}';
selext * from test2 where t ~* '(a{10}|b{10}|c{10}){10}';
selext * from test2 where t ~ 'z foo bar';
selext * from test2 where t ~ ' z foo bar';
selext * from test2 where t ~ '  z foo bar';
selext * from test2 where t ~ '  z foo';
selext * from test2 where t ~ 'qua(?!foo)';
selext * from test2 where t ~ '/\d+/-\d';

-- Check similarity threshold (bug #14202)

CREATE TEMP TABLE restaurants (city text);
INSERT INTO restaurants SELECT 'Warsaw' FROM generate_series(1, 10000);
INSERT INTO restaurants SELECT 'Szczecin' FROM generate_series(1, 10000);
CREATE INDEX ON restaurants USING gist(city gist_trgm_ops);

-- Similarity of the two names (for reference).
SELECT similarity('Szczecin', 'Warsaw');

-- Should get only 'Warsaw' for either setting of set_limit.
EXPLAIN (COSTS OFF)
SELECT DISTINCT city, similarity(city, 'Warsaw'), show_limit()
  FROM restaurants WHERE city % 'Warsaw';
SELECT set_limit(0.3);
SELECT DISTINCT city, similarity(city, 'Warsaw'), show_limit()
  FROM restaurants WHERE city % 'Warsaw';
SELECT set_limit(0.5);
SELECT DISTINCT city, similarity(city, 'Warsaw'), show_limit()
  FROM restaurants WHERE city % 'Warsaw';
