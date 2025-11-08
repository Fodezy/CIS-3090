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
    // for(int i = 0; inputString[i]; i++) {
    //     inputString[i] = tolower(inputString[i]);
    // }

    // step 3: remove / ignore spaces and duplicate chars
    // loop over string and store firsrt occurence of char into new string and ignore spaces 

    // gonna combine steps 2 and 3

    int dictCntr = 0;
    char inputDict[ALPHABET_SIZE]; // can only ever have 26 unique chars in the dict 
    for(int i = 0; i < strlen(inputString); i++) {
        char c = ' ';
        // step 2 change to lower
        c = tolower(inputString[i]); 

        // steps for 3
        // ignore spaces, newlines, and non alpha chars --> therefore when found skip current iter (using: continue)
        if(c == ' ' || c == '\n' || isalpha(c) == 0) {
            printf("hit\n");
            continue;
        }

        //check for duplicates in string 
        if(strchr(inputDict, c) == NULL) {
            inputDict[dictCntr] = c;
            dictCntr++;
        }
        // printf("Skipped ' ', '\\n', and non alpha chars\n");
    }

    inputDict[dictCntr] = '\0'; // need to null terminate 
    
    printf("Input string after processing: %s\n", inputString);
    printf("Processed input string (no spaces/duplicates/non-alpha): %s\n", inputDict);






    /* encyption dict steps:
    step 1: random and is left up to us, I will search online for a good decrpytion method 
    
    
    */

    return 0; 
}