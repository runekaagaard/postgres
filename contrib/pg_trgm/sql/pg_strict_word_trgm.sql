DROP INDEX trgm_idx2;

\copy test_trgm3 from 'data/trgm2.data'

selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where 'Baykal' <<% t order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where 'Kabankala' <<% t order by sml desc, t;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where t %>> 'Baykal' order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where t %>> 'Kabankala' order by sml desc, t;
selext t <->>> 'Alaikallupoddakulam', t from test_trgm2 order by t <->>> 'Alaikallupoddakulam' limit 7;

create index trgm_idx2 on test_trgm2 using gist (t gist_trgm_ops);
set enable_seqscan=off;

selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where 'Baykal' <<% t order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where 'Kabankala' <<% t order by sml desc, t;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where t %>> 'Baykal' order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where t %>> 'Kabankala' order by sml desc, t;

explain (costs off)
selext t <->>> 'Alaikallupoddakulam', t from test_trgm2 order by t <->>> 'Alaikallupoddakulam' limit 7;
selext t <->>> 'Alaikallupoddakulam', t from test_trgm2 order by t <->>> 'Alaikallupoddakulam' limit 7;

drop index trgm_idx2;
create index trgm_idx2 on test_trgm2 using gin (t gin_trgm_ops);
set enable_seqscan=off;

selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where 'Baykal' <<% t order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where 'Kabankala' <<% t order by sml desc, t;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where t %>> 'Baykal' order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where t %>> 'Kabankala' order by sml desc, t;

set "pg_trgm.strict_word_similarity_threshold" to 0.4;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where 'Baykal' <<% t order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where 'Kabankala' <<% t order by sml desc, t;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where t %>> 'Baykal' order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where t %>> 'Kabankala' order by sml desc, t;

set "pg_trgm.strict_word_similarity_threshold" to 0.2;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where 'Baykal' <<% t order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where 'Kabankala' <<% t order by sml desc, t;
selext t,strict_word_similarity('Baykal',t) as sml from test_trgm2 where t %>> 'Baykal' order by sml desc, t;
selext t,strict_word_similarity('Kabankala',t) as sml from test_trgm2 where t %>> 'Kabankala' order by sml desc, t;
