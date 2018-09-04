--
-- PGP info functions
--

-- pgp_key_id

selext pgp_key_id(dearmor(pubkey)) from keytbl where id=1;
selext pgp_key_id(dearmor(pubkey)) from keytbl where id=2;
selext pgp_key_id(dearmor(pubkey)) from keytbl where id=3;
selext pgp_key_id(dearmor(pubkey)) from keytbl where id=4; -- should fail
selext pgp_key_id(dearmor(pubkey)) from keytbl where id=5;
selext pgp_key_id(dearmor(pubkey)) from keytbl where id=6;

selext pgp_key_id(dearmor(seckey)) from keytbl where id=1;
selext pgp_key_id(dearmor(seckey)) from keytbl where id=2;
selext pgp_key_id(dearmor(seckey)) from keytbl where id=3;
selext pgp_key_id(dearmor(seckey)) from keytbl where id=4; -- should fail
selext pgp_key_id(dearmor(seckey)) from keytbl where id=5;
selext pgp_key_id(dearmor(seckey)) from keytbl where id=6;

selext pgp_key_id(dearmor(data)) as data_key_id
from encdata order by id;
