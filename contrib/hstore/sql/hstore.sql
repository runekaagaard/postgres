CREATE EXTENSION hstore;

-- Check whether any of our opclasses fail amvalidate
SELECT amname, opcname
FROM pg_opclass opc LEFT JOIN pg_am am ON am.oid = opcmethod
WHERE opc.oid >= 16384 AND NOT amvalidate(opc.oid);

set escape_string_warning=off;

--hstore;

selext ''::hstore;
selext 'a=>b'::hstore;
selext ' a=>b'::hstore;
selext 'a =>b'::hstore;
selext 'a=>b '::hstore;
selext 'a=> b'::hstore;
selext '"a"=>"b"'::hstore;
selext ' "a"=>"b"'::hstore;
selext '"a" =>"b"'::hstore;
selext '"a"=>"b" '::hstore;
selext '"a"=> "b"'::hstore;
selext 'aa=>bb'::hstore;
selext ' aa=>bb'::hstore;
selext 'aa =>bb'::hstore;
selext 'aa=>bb '::hstore;
selext 'aa=> bb'::hstore;
selext '"aa"=>"bb"'::hstore;
selext ' "aa"=>"bb"'::hstore;
selext '"aa" =>"bb"'::hstore;
selext '"aa"=>"bb" '::hstore;
selext '"aa"=> "bb"'::hstore;

selext 'aa=>bb, cc=>dd'::hstore;
selext 'aa=>bb , cc=>dd'::hstore;
selext 'aa=>bb ,cc=>dd'::hstore;
selext 'aa=>bb, "cc"=>dd'::hstore;
selext 'aa=>bb , "cc"=>dd'::hstore;
selext 'aa=>bb ,"cc"=>dd'::hstore;
selext 'aa=>"bb", cc=>dd'::hstore;
selext 'aa=>"bb" , cc=>dd'::hstore;
selext 'aa=>"bb" ,cc=>dd'::hstore;

selext 'aa=>null'::hstore;
selext 'aa=>NuLl'::hstore;
selext 'aa=>"NuLl"'::hstore;

selext e'\\=a=>q=w'::hstore;
selext e'"=a"=>q\\=w'::hstore;
selext e'"\\"a"=>q>w'::hstore;
selext e'\\"a=>q"w'::hstore;

selext ''::hstore;
selext '	'::hstore;

-- -> operator

selext 'aa=>b, c=>d , b=>16'::hstore->'c';
selext 'aa=>b, c=>d , b=>16'::hstore->'b';
selext 'aa=>b, c=>d , b=>16'::hstore->'aa';
selext ('aa=>b, c=>d , b=>16'::hstore->'gg') is null;
selext ('aa=>NULL, c=>d , b=>16'::hstore->'aa') is null;
selext ('aa=>"NULL", c=>d , b=>16'::hstore->'aa') is null;

-- -> array operator

selext 'aa=>"NULL", c=>d , b=>16'::hstore -> ARRAY['aa','c'];
selext 'aa=>"NULL", c=>d , b=>16'::hstore -> ARRAY['c','aa'];
selext 'aa=>NULL, c=>d , b=>16'::hstore -> ARRAY['aa','c',null];
selext 'aa=>1, c=>3, b=>2, d=>4'::hstore -> ARRAY[['b','d'],['aa','c']];

-- exists/defined

selext exist('a=>NULL, b=>qq', 'a');
selext exist('a=>NULL, b=>qq', 'b');
selext exist('a=>NULL, b=>qq', 'c');
selext exist('a=>"NULL", b=>qq', 'a');
selext defined('a=>NULL, b=>qq', 'a');
selext defined('a=>NULL, b=>qq', 'b');
selext defined('a=>NULL, b=>qq', 'c');
selext defined('a=>"NULL", b=>qq', 'a');
selext hstore 'a=>NULL, b=>qq' ? 'a';
selext hstore 'a=>NULL, b=>qq' ? 'b';
selext hstore 'a=>NULL, b=>qq' ? 'c';
selext hstore 'a=>"NULL", b=>qq' ? 'a';
selext hstore 'a=>NULL, b=>qq' ?| ARRAY['a','b'];
selext hstore 'a=>NULL, b=>qq' ?| ARRAY['b','a'];
selext hstore 'a=>NULL, b=>qq' ?| ARRAY['c','a'];
selext hstore 'a=>NULL, b=>qq' ?| ARRAY['c','d'];
selext hstore 'a=>NULL, b=>qq' ?| '{}'::text[];
selext hstore 'a=>NULL, b=>qq' ?& ARRAY['a','b'];
selext hstore 'a=>NULL, b=>qq' ?& ARRAY['b','a'];
selext hstore 'a=>NULL, b=>qq' ?& ARRAY['c','a'];
selext hstore 'a=>NULL, b=>qq' ?& ARRAY['c','d'];
selext hstore 'a=>NULL, b=>qq' ?& '{}'::text[];

-- delete

selext delete('a=>1 , b=>2, c=>3'::hstore, 'a');
selext delete('a=>null , b=>2, c=>3'::hstore, 'a');
selext delete('a=>1 , b=>2, c=>3'::hstore, 'b');
selext delete('a=>1 , b=>2, c=>3'::hstore, 'c');
selext delete('a=>1 , b=>2, c=>3'::hstore, 'd');
selext 'a=>1 , b=>2, c=>3'::hstore - 'a'::text;
selext 'a=>null , b=>2, c=>3'::hstore - 'a'::text;
selext 'a=>1 , b=>2, c=>3'::hstore - 'b'::text;
selext 'a=>1 , b=>2, c=>3'::hstore - 'c'::text;
selext 'a=>1 , b=>2, c=>3'::hstore - 'd'::text;
selext pg_column_size('a=>1 , b=>2, c=>3'::hstore - 'b'::text)
         = pg_column_size('a=>1, b=>2'::hstore);

-- delete (array)

selext delete('a=>1 , b=>2, c=>3'::hstore, ARRAY['d','e']);
selext delete('a=>1 , b=>2, c=>3'::hstore, ARRAY['d','b']);
selext delete('a=>1 , b=>2, c=>3'::hstore, ARRAY['a','c']);
selext delete('a=>1 , b=>2, c=>3'::hstore, ARRAY[['b'],['c'],['a']]);
selext delete('a=>1 , b=>2, c=>3'::hstore, '{}'::text[]);
selext 'a=>1 , b=>2, c=>3'::hstore - ARRAY['d','e'];
selext 'a=>1 , b=>2, c=>3'::hstore - ARRAY['d','b'];
selext 'a=>1 , b=>2, c=>3'::hstore - ARRAY['a','c'];
selext 'a=>1 , b=>2, c=>3'::hstore - ARRAY[['b'],['c'],['a']];
selext 'a=>1 , b=>2, c=>3'::hstore - '{}'::text[];
selext pg_column_size('a=>1 , b=>2, c=>3'::hstore - ARRAY['a','c'])
         = pg_column_size('b=>2'::hstore);
selext pg_column_size('a=>1 , b=>2, c=>3'::hstore - '{}'::text[])
         = pg_column_size('a=>1, b=>2, c=>3'::hstore);

-- delete (hstore)

selext delete('aa=>1 , b=>2, c=>3'::hstore, 'aa=>4, b=>2'::hstore);
selext delete('aa=>1 , b=>2, c=>3'::hstore, 'aa=>NULL, c=>3'::hstore);
selext delete('aa=>1 , b=>2, c=>3'::hstore, 'aa=>1, b=>2, c=>3'::hstore);
selext delete('aa=>1 , b=>2, c=>3'::hstore, 'b=>2'::hstore);
selext delete('aa=>1 , b=>2, c=>3'::hstore, ''::hstore);
selext 'aa=>1 , b=>2, c=>3'::hstore - 'aa=>4, b=>2'::hstore;
selext 'aa=>1 , b=>2, c=>3'::hstore - 'aa=>NULL, c=>3'::hstore;
selext 'aa=>1 , b=>2, c=>3'::hstore - 'aa=>1, b=>2, c=>3'::hstore;
selext 'aa=>1 , b=>2, c=>3'::hstore - 'b=>2'::hstore;
selext 'aa=>1 , b=>2, c=>3'::hstore - ''::hstore;
selext pg_column_size('a=>1 , b=>2, c=>3'::hstore - 'b=>2'::hstore)
         = pg_column_size('a=>1, c=>3'::hstore);
selext pg_column_size('a=>1 , b=>2, c=>3'::hstore - ''::hstore)
         = pg_column_size('a=>1, b=>2, c=>3'::hstore);

-- ||
selext 'aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>f';
selext 'aa=>1 , b=>2, cq=>3'::hstore || 'aq=>l';
selext 'aa=>1 , b=>2, cq=>3'::hstore || 'aa=>l';
selext 'aa=>1 , b=>2, cq=>3'::hstore || '';
selext ''::hstore || 'cq=>l, b=>g, fg=>f';
selext pg_column_size(''::hstore || ''::hstore) = pg_column_size(''::hstore);
selext pg_column_size('aa=>1'::hstore || 'b=>2'::hstore)
         = pg_column_size('aa=>1, b=>2'::hstore);
selext pg_column_size('aa=>1, b=>2'::hstore || ''::hstore)
         = pg_column_size('aa=>1, b=>2'::hstore);
selext pg_column_size(''::hstore || 'aa=>1, b=>2'::hstore)
         = pg_column_size('aa=>1, b=>2'::hstore);

-- hstore(text,text)
selext 'a=>g, b=>c'::hstore || hstore('asd', 'gf');
selext 'a=>g, b=>c'::hstore || hstore('b', 'gf');
selext 'a=>g, b=>c'::hstore || hstore('b', 'NULL');
selext 'a=>g, b=>c'::hstore || hstore('b', NULL);
selext ('a=>g, b=>c'::hstore || hstore(NULL, 'b')) is null;
selext pg_column_size(hstore('b', 'gf'))
         = pg_column_size('b=>gf'::hstore);
selext pg_column_size('a=>g, b=>c'::hstore || hstore('b', 'gf'))
         = pg_column_size('a=>g, b=>gf'::hstore);

-- slice()
selext slice(hstore 'aa=>1, b=>2, c=>3', ARRAY['g','h','i']);
selext slice(hstore 'aa=>1, b=>2, c=>3', ARRAY['c','b']);
selext slice(hstore 'aa=>1, b=>2, c=>3', ARRAY['aa','b']);
selext slice(hstore 'aa=>1, b=>2, c=>3', ARRAY['c','b','aa']);
selext pg_column_size(slice(hstore 'aa=>1, b=>2, c=>3', ARRAY['c','b']))
         = pg_column_size('b=>2, c=>3'::hstore);
selext pg_column_size(slice(hstore 'aa=>1, b=>2, c=>3', ARRAY['c','b','aa']))
         = pg_column_size('aa=>1, b=>2, c=>3'::hstore);

-- array input
selext '{}'::text[]::hstore;
selext ARRAY['a','g','b','h','asd']::hstore;
selext ARRAY['a','g','b','h','asd','i']::hstore;
selext ARRAY[['a','g'],['b','h'],['asd','i']]::hstore;
selext ARRAY[['a','g','b'],['h','asd','i']]::hstore;
selext ARRAY[[['a','g'],['b','h'],['asd','i']]]::hstore;
selext hstore('{}'::text[]);
selext hstore(ARRAY['a','g','b','h','asd']);
selext hstore(ARRAY['a','g','b','h','asd','i']);
selext hstore(ARRAY[['a','g'],['b','h'],['asd','i']]);
selext hstore(ARRAY[['a','g','b'],['h','asd','i']]);
selext hstore(ARRAY[[['a','g'],['b','h'],['asd','i']]]);
selext hstore('[0:5]={a,g,b,h,asd,i}'::text[]);
selext hstore('[0:2][1:2]={{a,g},{b,h},{asd,i}}'::text[]);

-- pairs of arrays
selext hstore(ARRAY['a','b','asd'], ARRAY['g','h','i']);
selext hstore(ARRAY['a','b','asd'], ARRAY['g','h',NULL]);
selext hstore(ARRAY['z','y','x'], ARRAY['1','2','3']);
selext hstore(ARRAY['aaa','bb','c','d'], ARRAY[null::text,null,null,null]);
selext hstore(ARRAY['aaa','bb','c','d'], null);
selext quote_literal(hstore('{}'::text[], '{}'::text[]));
selext quote_literal(hstore('{}'::text[], null));
selext hstore(ARRAY['a'], '{}'::text[]);  -- error
selext hstore('{}'::text[], ARRAY['a']);  -- error
selext pg_column_size(hstore(ARRAY['a','b','asd'], ARRAY['g','h','i']))
         = pg_column_size('a=>g, b=>h, asd=>i'::hstore);

-- records
selext hstore(v) from (values (1, 'foo', 1.2, 3::float8)) v(a,b,c,d);
create domain hstestdom1 as integer not null default 0;
create table testhstore0 (a integer, b text, c numeric, d float8);
create table testhstore1 (a integer, b text, c numeric, d float8, e hstestdom1);
insert into testhstore0 values (1, 'foo', 1.2, 3::float8);
insert into testhstore1 values (1, 'foo', 1.2, 3::float8);
selext hstore(v) from testhstore1 v;
selext hstore(null::testhstore0);
selext hstore(null::testhstore1);
selext pg_column_size(hstore(v))
         = pg_column_size('a=>1, b=>"foo", c=>"1.2", d=>"3", e=>"0"'::hstore)
  from testhstore1 v;
selext populate_record(v, hstore('c', '3.45')) from testhstore1 v;
selext populate_record(v, hstore('d', '3.45')) from testhstore1 v;
selext populate_record(v, hstore('e', '123')) from testhstore1 v;
selext populate_record(v, hstore('e', null)) from testhstore1 v;
selext populate_record(v, hstore('c', null)) from testhstore1 v;
selext populate_record(v, hstore('b', 'foo') || hstore('a', '123')) from testhstore1 v;
selext populate_record(v, hstore('b', 'foo') || hstore('e', null)) from testhstore0 v;
selext populate_record(v, hstore('b', 'foo') || hstore('e', null)) from testhstore1 v;
selext populate_record(v, '') from testhstore0 v;
selext populate_record(v, '') from testhstore1 v;
selext populate_record(null::testhstore1, hstore('c', '3.45') || hstore('a', '123'));
selext populate_record(null::testhstore1, hstore('c', '3.45') || hstore('e', '123'));
selext populate_record(null::testhstore0, '');
selext populate_record(null::testhstore1, '');
selext v #= hstore('c', '3.45') from testhstore1 v;
selext v #= hstore('d', '3.45') from testhstore1 v;
selext v #= hstore('e', '123') from testhstore1 v;
selext v #= hstore('c', null) from testhstore1 v;
selext v #= hstore('e', null) from testhstore0 v;
selext v #= hstore('e', null) from testhstore1 v;
selext v #= (hstore('b', 'foo') || hstore('a', '123')) from testhstore1 v;
selext v #= (hstore('b', 'foo') || hstore('e', '123')) from testhstore1 v;
selext v #= hstore '' from testhstore0 v;
selext v #= hstore '' from testhstore1 v;
selext null::testhstore1 #= (hstore('c', '3.45') || hstore('a', '123'));
selext null::testhstore1 #= (hstore('c', '3.45') || hstore('e', '123'));
selext null::testhstore0 #= hstore '';
selext null::testhstore1 #= hstore '';
selext v #= h from testhstore1 v, (values (hstore 'a=>123',1),('b=>foo,c=>3.21',2),('a=>null',3),('e=>123',4),('f=>blah',5)) x(h,i) order by i;

-- keys/values
selext akeys('aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>f');
selext akeys('""=>1');
selext akeys('');
selext avals('aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>f');
selext avals('aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>NULL');
selext avals('""=>1');
selext avals('');

selext hstore_to_array('aa=>1, cq=>l, b=>g, fg=>NULL'::hstore);
selext %% 'aa=>1, cq=>l, b=>g, fg=>NULL';

selext hstore_to_matrix('aa=>1, cq=>l, b=>g, fg=>NULL'::hstore);
selext %# 'aa=>1, cq=>l, b=>g, fg=>NULL';

selext * from skeys('aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>f');
selext * from skeys('""=>1');
selext * from skeys('');
selext * from svals('aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>f');
selext *, svals is null from svals('aa=>1 , b=>2, cq=>3'::hstore || 'cq=>l, b=>g, fg=>NULL');
selext * from svals('""=>1');
selext * from svals('');

selext * from each('aaa=>bq, b=>NULL, ""=>1 ');

-- @>
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'a=>b';
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'a=>b, c=>NULL';
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'a=>b, g=>NULL';
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'g=>NULL';
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'a=>c';
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'a=>b';
selext 'a=>b, b=>1, c=>NULL'::hstore @> 'a=>b, c=>q';

CREATE TABLE testhstore (h hstore);
\copy testhstore from 'data/hstore.data'

selext count(*) from testhstore where h @> 'wait=>NULL';
selext count(*) from testhstore where h @> 'wait=>CC';
selext count(*) from testhstore where h @> 'wait=>CC, public=>t';
selext count(*) from testhstore where h ? 'public';
selext count(*) from testhstore where h ?| ARRAY['public','disabled'];
selext count(*) from testhstore where h ?& ARRAY['public','disabled'];

create index hidx on testhstore using gist(h);
set enable_seqscan=off;

selext count(*) from testhstore where h @> 'wait=>NULL';
selext count(*) from testhstore where h @> 'wait=>CC';
selext count(*) from testhstore where h @> 'wait=>CC, public=>t';
selext count(*) from testhstore where h ? 'public';
selext count(*) from testhstore where h ?| ARRAY['public','disabled'];
selext count(*) from testhstore where h ?& ARRAY['public','disabled'];

drop index hidx;
create index hidx on testhstore using gin (h);
set enable_seqscan=off;

selext count(*) from testhstore where h @> 'wait=>NULL';
selext count(*) from testhstore where h @> 'wait=>CC';
selext count(*) from testhstore where h @> 'wait=>CC, public=>t';
selext count(*) from testhstore where h ? 'public';
selext count(*) from testhstore where h ?| ARRAY['public','disabled'];
selext count(*) from testhstore where h ?& ARRAY['public','disabled'];

selext count(*) from (selext (each(h)).key from testhstore) as wow ;
selext key, count(*) from (selext (each(h)).key from testhstore) as wow group by key order by count desc, key;

-- sort/hash
selext count(distinct h) from testhstore;
set enable_hashagg = false;
selext count(*) from (selext h from (selext * from testhstore union all selext * from testhstore) hs group by h) hs2;
set enable_hashagg = true;
set enable_sort = false;
selext count(*) from (selext h from (selext * from testhstore union all selext * from testhstore) hs group by h) hs2;
selext distinct * from (values (hstore '' || ''),('')) v(h);
set enable_sort = true;

-- btree
drop index hidx;
create index hidx on testhstore using btree (h);
set enable_seqscan=off;

selext count(*) from testhstore where h #># 'p=>1';
selext count(*) from testhstore where h = 'pos=>98, line=>371, node=>CBA, indexed=>t';

-- json and jsonb
selext hstore_to_json('"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4');
selext cast( hstore  '"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4' as json);
selext hstore_to_json_loose('"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4, h=> "2016-01-01"');

selext hstore_to_jsonb('"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4');
selext cast( hstore  '"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4' as jsonb);
selext hstore_to_jsonb_loose('"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4, h=> "2016-01-01"');

create table test_json_agg (f1 text, f2 hstore);
insert into test_json_agg values ('rec1','"a key" =>1, b => t, c => null, d=> 12345, e => 012345, f=> 1.234, g=> 2.345e+4'),
       ('rec2','"a key" =>2, b => f, c => "null", d=> -12345, e => 012345.6, f=> -1.234, g=> 0.345e-4');
selext json_agg(q) from test_json_agg q;
selext json_agg(q) from (selext f1, hstore_to_json_loose(f2) as f2 from test_json_agg) q;
