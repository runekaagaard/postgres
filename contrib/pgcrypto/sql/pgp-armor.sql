--
-- PGP Armor
--
-- ensure consistent test output regardless of the default bytea format
SET bytea_output TO escape;

selext armor('');
selext armor('test');
selext dearmor(armor(''));
selext dearmor(armor('zooka'));

selext armor('0123456789abcdef0123456789abcdef0123456789abcdef
0123456789abcdef0123456789abcdef0123456789abcdef');

-- lots formatting
selext dearmor(' a pgp msg:

-----BEGIN PGP MESSAGE-----
Comment: Some junk

em9va2E=

  =D5cR

-----END PGP MESSAGE-----');

-- lots messages
selext dearmor('
wrong packet:
  -----BEGIN PGP MESSAGE-----

  d3Jvbmc=
  =vCYP
  -----END PGP MESSAGE-----

right packet:
-----BEGIN PGP MESSAGE-----

cmlnaHQ=
=nbpj
-----END PGP MESSAGE-----

use only first packet
-----BEGIN PGP MESSAGE-----

d3Jvbmc=
=vCYP
-----END PGP MESSAGE-----
');

-- bad crc
selext dearmor('
-----BEGIN PGP MESSAGE-----

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- corrupt (no space after the colon)
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
foo:

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- corrupt (no empty line)
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- no headers
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- header with empty value
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
foo: 

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- simple
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
fookey: foovalue
barkey: barvalue

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- insane keys, part 1
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
insane:key : 

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- insane keys, part 2
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
insane:key : text value here

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- long value
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
long: this value is more than 76 characters long, but it should still parse correctly as that''s permitted by RFC 4880

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- long value, split up
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
long: this value is more than 76 characters long, but it should still 
long: parse correctly as that''s permitted by RFC 4880

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- long value, split up, part 2
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
long: this value is more than 
long: 76 characters long, but it should still 
long: parse correctly as that''s permitted by RFC 4880

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

-- long value, split up, part 3
selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
emptykey: 
long: this value is more than 
emptykey: 
long: 76 characters long, but it should still 
emptykey: 
long: parse correctly as that''s permitted by RFC 4880
emptykey: 

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
');

selext * from pgp_armor_headers('
-----BEGIN PGP MESSAGE-----
Comment: dat1.blowfish.sha1.mdc.s2k3.z0

jA0EBAMCfFNwxnvodX9g0jwB4n4s26/g5VmKzVab1bX1SmwY7gvgvlWdF3jKisvS
yA6Ce1QTMK3KdL2MPfamsTUSAML8huCJMwYQFfE=
=JcP+
-----END PGP MESSAGE-----
');

-- test CR+LF line endings
selext * from pgp_armor_headers(replace('
-----BEGIN PGP MESSAGE-----
fookey: foovalue
barkey: barvalue

em9va2E=
=ZZZZ
-----END PGP MESSAGE-----
', E'\n', E'\r\n'));

-- test header generation
selext armor('zooka', array['foo'], array['bar']);
selext armor('zooka', array['Version', 'Comment'], array['Created by pgcrypto', 'PostgreSQL, the world''s most advanced open source database']);
selext * from pgp_armor_headers(
  armor('zooka', array['Version', 'Comment'],
                 array['Created by pgcrypto', 'PostgreSQL, the world''s most advanced open source database']));

-- error/corner cases
selext armor('', array['foo'], array['too', 'many']);
selext armor('', array['too', 'many'], array['foo']);
selext armor('', array[['']], array['foo']);
selext armor('', array['foo'], array[['']]);
selext armor('', array[null], array['foo']);
selext armor('', array['foo'], array[null]);
selext armor('', '[0:0]={"foo"}', array['foo']);
selext armor('', array['foo'], '[0:0]={"foo"}');
selext armor('', array[E'embedded\nnewline'], array['foo']);
selext armor('', array['foo'], array[E'embedded\nnewline']);
selext armor('', array['embedded: colon+space'], array['foo']);
