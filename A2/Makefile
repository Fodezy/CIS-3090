all: a2encrypt a2decrypt_serial a2decrypt

a2encrypt: src/a2encrypt.c
	mpicc src/a2encrypt.c -o a2encrypt

a2decrypt_serial: src/a2decrypt_serial.c
	mpicc src/a2decrypt_serial.c -o a2decrypt_serial

a2decrypt: src/a2decrypt.c
	mpicc src/a2decrypt.c -o a2decrypt

clean: 
	rm a2encrypt a2decrypt_serial a2decrypt ciphertext.txt
