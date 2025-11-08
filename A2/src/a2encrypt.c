#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <time.h>

#define MAX_STRING_SIZE 256
#define ALPHABET_SIZE 26

void swap (char *a, char *b)
{
    char temp = *a;
    *a = *b;
    *b = temp;
}

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

    if(strSize + 1 > MAX_STRING_SIZE) {
        fprintf(stderr, "Error: Input string is too, long, max size is 256 chars\n");
        return 0;            
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
    char inputDict[ALPHABET_SIZE] = {0}; // can only ever have 26 unique chars in the dict 
    for(int i = 0; i < strlen(inputString); i++) {
        char c = tolower(inputString[i]); 

        // steps for 3
        // ignore spaces, newlines, and non alpha chars --> therefore when found skip current iter (using: continue)
        if(c == ' ' || c == '\n' || isalpha(c) == 0) {
            // printf("hit\n");
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
    step 1: random and is left up to us, I will search online for a good decrpytion method output must go to --> ciphertext.txt
    

    will be using fisher-yates shuffle algo to generate a random encryption dict from the input dict 
    found implementation for this on: https://www.geeksforgeeks.org/dsa/shuffle-a-given-array-using-fisher-yates-shuffle-algorithm/
    */

    char encryptionDict[ALPHABET_SIZE];
    strcpy(encryptionDict, inputDict); // copy input dict to encryption dict to be shuffled

    int n = strlen(encryptionDict); // might be able to use dictCntr here instead 

    srand(time(NULL));
    for(int i = n-1; i > 0; i--) {
        int j = rand() % (i+1);
        
        swap(&encryptionDict[i], &encryptionDict[j]);
    }

    printf("Encryption dict (shuffled input dict): %s\n", encryptionDict);


    // Now I need to encrpyt the string using mapping 
    char cipherString[MAX_STRING_SIZE] = {0};
    int cipherCntr = 0;

    for(int i = 0; i < strlen(inputString); i++) {
        char c = tolower(inputString[i]);
        // used to keep if the char is a space or non alpha char 
        if(isalpha(c) == 0) {
            cipherString[cipherCntr] = c;
            cipherCntr++;
            continue;
        }

        int index = -1;
        for(int j = 0; j < strlen(inputDict); j++) {
            if(inputDict[j] == c) {
                index = j;
                break;
            }
        }

        if(index != -1) {
            cipherString[cipherCntr] = encryptionDict[index];
            cipherCntr++;
        }
    }

    cipherString[cipherCntr] = '\0'; 

    printf("Ciphertext: %s\n", cipherString);

    // need to print output to a file now 

    FILE *fout = fopen("ciphertext.txt", "w"); 
    if(fout == NULL) {
        perror("fopen");
        return 1;
    }

    fprintf(fout, "%s\n", cipherString);
    fclose(fout);
    

    return 0; 
}