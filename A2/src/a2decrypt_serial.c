#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <time.h>

#define MAX_STRING_SIZE 256
#define ALPHABET_SIZE 26


int main(int argc, char** argv) {
    // reads in the cipher from the ciphertext.txt file 
    // read and store the list of chars from the string 
    // create a decryption dict (ie unique chars from string - like encryption worked)
    // use this decryption list to build and test every permutation possible  
    // --> test each permuation against the american english txt file provided as an array would become way to lare 
    // --> store each valid decryption found into an array 

    if(argc > 3 && argc < 2) {
        fprintf(stderr, "Error with input args, please use the following format: ./a2decrypt_serial <ciphertext file> <dictionary file>\n");
        return 0;
    }

    FILE *fin = fopen(argv[1], "r");
    if(fin == NULL) {
        perror("fopen");
        return 1;
    }

    char cipherString[MAX_STRING_SIZE];
    cipherString[0]= '\0';

    fgets(cipherString, MAX_STRING_SIZE, fin); 
    printf("Ciphertext read from file: %s\n", cipherString);

    int dictCntr = 0; 
    char decryptDict[ALPHABET_SIZE] = {0}; // can only ever have 26 unique chars in the dict
    for(int i = 0; i < strlen(cipherString);i++) {
        char c = tolower(cipherString[i]);
        if(c == ' ' || c == '\n' || isalpha(c) == 0) {
            continue;
        }

        if(strchr(decryptDict, c) == NULL) {
            decryptDict[dictCntr] = c; 
            dictCntr++;
        }
    }

    decryptDict[dictCntr] = '\0'; 
    printf("Decryption dict (unique chars from cipher): %s\n", decryptDict);





}