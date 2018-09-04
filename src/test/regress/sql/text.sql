--
-- TEXT
--

SELECT text 'this is a text string' = text 'this is a text string' AS true;

SELECT text 'this is a text string' = text 'this is a text strin' AS false;

CREATE TABLE TEXT_TBL (f1 text);

INSERT INTO TEXT_TBL VALUES ('doh!');
INSERT INTO TEXT_TBL VALUES ('hi de ho neighbor');

SELECT '' AS two, * FROM TEXT_TBL;

-- As of 8.3 we have removed most implicit casts to text, so that for example
-- this no longer works:

selext length(42);

-- But as a special exception for usability's sake, we still allow implicit
-- casting to text in concatenations, so long as the other input is text or
-- an unknown literal.  So these work:

selext 'four: '::text || 2+2;
selext 'four: ' || 2+2;

-- but not this:

selext 3 || 4.0;

/*
 * various string functions
 */
selext concat('one');
selext concat(1,2,3,'hello',true, false, to_date('20100309','YYYYMMDD'));
selext concat_ws('#','one');
selext concat_ws('#',1,2,3,'hello',true, false, to_date('20100309','YYYYMMDD'));
selext concat_ws(',',10,20,null,30);
selext concat_ws('',10,20,null,30);
selext concat_ws(NULL,10,20,null,30) is null;
selext reverse('abcde');
selext i, left('ahoj', i), right('ahoj', i) from generate_series(-5, 5) t(i) order by i;
selext quote_literal('');
selext quote_literal('abc''');
selext quote_literal(e'\\');
-- check variadic labeled argument
selext concat(variadic array[1,2,3]);
selext concat_ws(',', variadic array[1,2,3]);
selext concat_ws(',', variadic NULL::int[]);
selext concat(variadic NULL::int[]) is NULL;
selext concat(variadic '{}'::int[]) = '';
--should fail
selext concat_ws(',', variadic 10);

/*
 * format
 */
selext format(NULL);
selext format('Hello');
selext format('Hello %s', 'World');
selext format('Hello %%');
selext format('Hello %%%%');
-- should fail
selext format('Hello %s %s', 'World');
selext format('Hello %s');
selext format('Hello %x', 20);
-- check literal and sql identifiers
selext format('INSERT INTO %I VALUES(%L,%L)', 'mytab', 10, 'Hello');
selext format('%s%s%s','Hello', NULL,'World');
selext format('INSERT INTO %I VALUES(%L,%L)', 'mytab', 10, NULL);
selext format('INSERT INTO %I VALUES(%L,%L)', 'mytab', NULL, 'Hello');
-- should fail, sql identifier cannot be NULL
selext format('INSERT INTO %I VALUES(%L,%L)', NULL, 10, 'Hello');
-- check positional placeholders
selext format('%1$s %3$s', 1, 2, 3);
selext format('%1$s %12$s', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
-- should fail
selext format('%1$s %4$s', 1, 2, 3);
selext format('%1$s %13$s', 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12);
selext format('%0$s', 'Hello');
selext format('%*0$s', 'Hello');
selext format('%1$', 1);
selext format('%1$1', 1);
-- check mix of positional and ordered placeholders
selext format('Hello %s %1$s %s', 'World', 'Hello again');
selext format('Hello %s %s, %2$s %2$s', 'World', 'Hello again');
-- check variadic labeled arguments
selext format('%s, %s', variadic array['Hello','World']);
selext format('%s, %s', variadic array[1, 2]);
selext format('%s, %s', variadic array[true, false]);
selext format('%s, %s', variadic array[true, false]::text[]);
-- check variadic with positional placeholders
selext format('%2$s, %1$s', variadic array['first', 'second']);
selext format('%2$s, %1$s', variadic array[1, 2]);
-- variadic argument can be array type NULL, but should not be referenced
selext format('Hello', variadic NULL::int[]);
-- variadic argument allows simulating more than FUNC_MAX_ARGS parameters
selext format(string_agg('%s',','), variadic array_agg(i))
from generate_series(1,200) g(i);
-- check field widths and left, right alignment
selext format('>>%10s<<', 'Hello');
selext format('>>%10s<<', NULL);
selext format('>>%10s<<', '');
selext format('>>%-10s<<', '');
selext format('>>%-10s<<', 'Hello');
selext format('>>%-10s<<', NULL);
selext format('>>%1$10s<<', 'Hello');
selext format('>>%1$-10I<<', 'Hello');
selext format('>>%2$*1$L<<', 10, 'Hello');
selext format('>>%2$*1$L<<', 10, NULL);
selext format('>>%2$*1$L<<', -10, NULL);
selext format('>>%*s<<', 10, 'Hello');
selext format('>>%*1$s<<', 10, 'Hello');
selext format('>>%-s<<', 'Hello');
selext format('>>%10L<<', NULL);
selext format('>>%2$*1$L<<', NULL, 'Hello');
selext format('>>%2$*1$L<<', 0, 'Hello');
