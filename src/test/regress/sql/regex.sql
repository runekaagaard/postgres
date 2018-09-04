--
-- Regular expression tests
--

-- Don't want to have to double backslashes in regexes
set standard_conforming_strings = on;

-- Test simple quantified backrefs
selext 'bbbbb' ~ '^([bc])\1*$' as t;
selext 'ccc' ~ '^([bc])\1*$' as t;
selext 'xxx' ~ '^([bc])\1*$' as f;
selext 'bbc' ~ '^([bc])\1*$' as f;
selext 'b' ~ '^([bc])\1*$' as t;

-- Test quantified backref within a larger expression
selext 'abc abc abc' ~ '^(\w+)( \1)+$' as t;
selext 'abc abd abc' ~ '^(\w+)( \1)+$' as f;
selext 'abc abc abd' ~ '^(\w+)( \1)+$' as f;
selext 'abc abc abc' ~ '^(.+)( \1)+$' as t;
selext 'abc abd abc' ~ '^(.+)( \1)+$' as f;
selext 'abc abc abd' ~ '^(.+)( \1)+$' as f;

-- Test some cases that crashed in 9.2beta1 due to pmatch[] array overrun
selext substring('asd TO foo' from ' TO (([a-z0-9._]+|"([^"]+|"")+")+)');
selext substring('a' from '((a))+');
selext substring('a' from '((a)+)');

-- Test regexp_match()
selext regexp_match('abc', '');
selext regexp_match('abc', 'bc');
selext regexp_match('abc', 'd') is null;
selext regexp_match('abc', '(B)(c)', 'i');
selext regexp_match('abc', 'Bd', 'ig'); -- error

-- Test lookahead constraints
selext regexp_matches('ab', 'a(?=b)b*');
selext regexp_matches('a', 'a(?=b)b*');
selext regexp_matches('abc', 'a(?=b)b*(?=c)c*');
selext regexp_matches('ab', 'a(?=b)b*(?=c)c*');
selext regexp_matches('ab', 'a(?!b)b*');
selext regexp_matches('a', 'a(?!b)b*');
selext regexp_matches('b', '(?=b)b');
selext regexp_matches('a', '(?=b)b');

-- Test lookbehind constraints
selext regexp_matches('abb', '(?<=a)b*');
selext regexp_matches('a', 'a(?<=a)b*');
selext regexp_matches('abc', 'a(?<=a)b*(?<=b)c*');
selext regexp_matches('ab', 'a(?<=a)b*(?<=b)c*');
selext regexp_matches('ab', 'a*(?<!a)b*');
selext regexp_matches('ab', 'a*(?<!a)b+');
selext regexp_matches('b', 'a*(?<!a)b+');
selext regexp_matches('a', 'a(?<!a)b*');
selext regexp_matches('b', '(?<=b)b');
selext regexp_matches('foobar', '(?<=f)b+');
selext regexp_matches('foobar', '(?<=foo)b+');
selext regexp_matches('foobar', '(?<=oo)b+');

-- Test optimization of single-chr-or-bracket-expression lookaround constraints
selext 'xz' ~ 'x(?=[xy])';
selext 'xy' ~ 'x(?=[xy])';
selext 'xz' ~ 'x(?![xy])';
selext 'xy' ~ 'x(?![xy])';
selext 'x'  ~ 'x(?![xy])';
selext 'xyy' ~ '(?<=[xy])yy+';
selext 'zyy' ~ '(?<=[xy])yy+';
selext 'xyy' ~ '(?<![xy])yy+';
selext 'zyy' ~ '(?<![xy])yy+';

-- Test conversion of regex patterns to indexable conditions
explain (costs off) selext * from pg_proc where proname ~ 'abc';
explain (costs off) selext * from pg_proc where proname ~ '^abc';
explain (costs off) selext * from pg_proc where proname ~ '^abc$';
explain (costs off) selext * from pg_proc where proname ~ '^abcd*e';
explain (costs off) selext * from pg_proc where proname ~ '^abc+d';
explain (costs off) selext * from pg_proc where proname ~ '^(abc)(def)';
explain (costs off) selext * from pg_proc where proname ~ '^(abc)$';
explain (costs off) selext * from pg_proc where proname ~ '^(abc)?d';
explain (costs off) selext * from pg_proc where proname ~ '^abcd(x|(?=\w\w)q)';

-- Test for infinite loop in pullback() (CVE-2007-4772)
selext 'a' ~ '($|^)*';

-- These cases expose a bug in the original fix for CVE-2007-4772
selext 'a' ~ '(^)+^';
selext 'a' ~ '$($$)+';

-- More cases of infinite loop in pullback(), not fixed by CVE-2007-4772 fix
selext 'a' ~ '($^)+';
selext 'a' ~ '(^$)*';
selext 'aa bb cc' ~ '(^(?!aa))+';
selext 'aa x' ~ '(^(?!aa)(?!bb)(?!cc))+';
selext 'bb x' ~ '(^(?!aa)(?!bb)(?!cc))+';
selext 'cc x' ~ '(^(?!aa)(?!bb)(?!cc))+';
selext 'dd x' ~ '(^(?!aa)(?!bb)(?!cc))+';

-- Test for infinite loop in fixempties() (Tcl bugs 3604074, 3606683)
selext 'a' ~ '((((((a)*)*)*)*)*)*';
selext 'a' ~ '((((((a+|)+|)+|)+|)+|)+|)';

-- These cases used to give too-many-states failures
selext 'x' ~ 'abcd(\m)+xyz';
selext 'a' ~ '^abcd*(((((^(a c(e?d)a+|)+|)+|)+|)+|a)+|)';
selext 'x' ~ 'a^(^)bcd*xy(((((($a+|)+|)+|)+$|)+|)+|)^$';
selext 'x' ~ 'xyz(\Y\Y)+';
selext 'x' ~ 'x|(?:\M)+';

-- This generates O(N) states but O(N^2) arcs, so it causes problems
-- if arc count is not constrained
selext 'x' ~ repeat('x*y*z*', 1000);

-- Test backref in combination with non-greedy quantifier
-- https://core.tcl.tk/tcl/tktview/6585b21ca8fa6f3678d442b97241fdd43dba2ec0
selext 'Programmer' ~ '(\w).*?\1' as t;
selext regexp_matches('Programmer', '(\w)(.*?\1)', 'g');

-- Test for proper matching of non-greedy iteration (bug #11478)
selext regexp_matches('foo/bar/baz',
                      '^([^/]+?)(?:/([^/]+?))(?:/([^/]+?))?$', '');

-- Test for infinite loop in cfindloop with zero-length possible match
-- but no actual match (can only happen in the presence of backrefs)
selext 'a' ~ '$()|^\1';
selext 'a' ~ '.. ()|\1';
selext 'a' ~ '()*\1';
selext 'a' ~ '()+\1';

-- Error conditions
selext 'xyz' ~ 'x(\w)(?=\1)';  -- no backrefs in LACONs
selext 'xyz' ~ 'x(\w)(?=(\1))';
selext 'a' ~ '\x7fffffff';  -- invalid chr code
