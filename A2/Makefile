all: a2encrypt a2decrypt_serial

a2encrypt: src/a2encrypt.c
	gcc src/a2encrypt.c -o a2encrypt.exe

a2decrypt_serial: src/a2decrypt_serial.c
	gcc src/a2decrypt_serial.c -o a2decrypt_serial.exe

clean: 
	del a2encrypt.exe a2decrypt_serial.exe a2encrypt a2decrypt_serial