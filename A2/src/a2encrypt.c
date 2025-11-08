#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>

#define MAX_STRING_SIZE 256
#define ALPHABET_SIZE 26

int main(int argc, char** argv) {
    /* input dict steps:
    step 1: read in the string from cmd line arg 
    step 2: convert to lower case 
    step 3: remove / ignore spaces and duplicate chars 
    step 4: store into input dict 
    */

    if(argc < 2) {
        fprintf(stderr, "Error with input args, please use the following format: ./a2encrypt <string to encrypt>\n");
        return 0;
    }

    // reading string from cmd line args help refrenced from: https://stackoverflow.com/questions/5046035/how-to-read-string-from-command-line-argument-in-c
    // step 1
    int strSize = 0;
    for(int i = 1; i < argc; i++) {
        strSize += strlen(argv[i]);
        if(argc > i+1) {
            strSize += 1;  // used to include spaces between args in cmd 
        }
    }

    char inputString[MAX_STRING_SIZE];
    inputString[0] = '\0'; // initialize to empty string

    for(int i = 1; i<argc; i++) {
        strcat(inputString, argv[i]);
        if(argc > i+1) {
            strcat(inputString, " "); // add space between args
        }
    }

    // step 2: convert to lower case
    for(int i = 0; inputString[i]; i++) {
        inputString[i] = tolower(inputString[i]);
    }

    // step 3: remove / ignore spaces and duplicate chars
    // loop over string and store firsrt occurence of char into new string and ignore spaces 






    /* encyption dict steps:
    step 1: random and is left up to us, I will search online for a good decrpytion method 
    
    
    */

    return 0; 
}