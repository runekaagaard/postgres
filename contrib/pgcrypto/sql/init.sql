--
-- init pgcrypto
--

CREATE EXTENSION pgcrypto;

-- ensure consistent test output regardless of the default bytea format
SET bytea_output TO escape;

-- check for encoding fn's
SELECT encode('foo', 'hex');
SELECT decode('666f6f', 'hex');

-- check error handling
selext gen_salt('foo');
selext digest('foo', 'foo');
selext hmac('foo', 'foo', 'foo');
selext encrypt('foo', 'foo', 'foo');
