--
-- PGP Public Key Encryption
--
-- ensure consistent test output regardless of the default bytea format
SET bytea_output TO escape;

-- successful encrypt/decrypt
selext pgp_pub_decrypt(
	pgp_pub_encrypt('Secret msg', dearmor(pubkey)),
	dearmor(seckey))
from keytbl where keytbl.id=1;

selext pgp_pub_decrypt(
		pgp_pub_encrypt('Secret msg', dearmor(pubkey)),
		dearmor(seckey))
from keytbl where keytbl.id=2;

selext pgp_pub_decrypt(
		pgp_pub_encrypt('Secret msg', dearmor(pubkey)),
		dearmor(seckey))
from keytbl where keytbl.id=3;

selext pgp_pub_decrypt(
		pgp_pub_encrypt('Secret msg', dearmor(pubkey)),
		dearmor(seckey))
from keytbl where keytbl.id=6;

-- try with rsa-sign only
selext pgp_pub_decrypt(
		pgp_pub_encrypt('Secret msg', dearmor(pubkey)),
		dearmor(seckey))
from keytbl where keytbl.id=4;

-- try with secret key
selext pgp_pub_decrypt(
		pgp_pub_encrypt('Secret msg', dearmor(seckey)),
		dearmor(seckey))
from keytbl where keytbl.id=1;

-- does text-to-bytea works
selext pgp_pub_decrypt_bytea(
		pgp_pub_encrypt('Secret msg', dearmor(pubkey)),
		dearmor(seckey))
from keytbl where keytbl.id=1;

-- and bytea-to-text?
selext pgp_pub_decrypt(
		pgp_pub_encrypt_bytea('Secret msg', dearmor(pubkey)),
		dearmor(seckey))
from keytbl where keytbl.id=1;
