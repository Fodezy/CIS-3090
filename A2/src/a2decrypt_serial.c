#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <time.h>

#define MAX_WORDS 120000
#define MAX_STRING_SIZE 256
#define ALPHABET_SIZE 26

void swap(char *x, char *y) {
    char temp;
    temp = *x;
    *x = *y;
    *y = temp;
}

void permute(char *word, int l, int r) {
    int i; 
    if(l == r) {
        printf("permutation: %s\n", word);
        // this is where i would do the dict check 
    } else {
        for(int i = l; i <= r; i++) {
            swap((word  + l), (word + i));
            permute(word, l + 1, r);

            swap((word + l), (word + i)); 
        }
    }
}

int strCompare(const void *a, const void *b) {
    char *const *wordA = a;
    char *const *wordB = b;

    return strcmp(*wordA, *wordB);
}


int main(int argc, char** argv) {
    // reads in the cipher from the ciphertext.txt file 
    // read and store the list of chars from the string 
    // create a decryption dict (ie unique chars from string - like encryption worked)
    // use this decryption list to build and test every permutation possible  
    // --> test each permuation against the american english txt file provided as an array would become way to lare 
    // --> store each valid decryption found into an array 

    if(argc != 3) {
        fprintf(stderr, "Error with input args, please use the following format: ./a2decrypt_serial <ciphertext file> <dictionary file>\n");
        return 0;
    }

    FILE *fCipherIn = fopen(argv[1], "r");
    if(fCipherIn == NULL) {
        perror("fopen");
        return 1;
    }

    char cipherString[MAX_STRING_SIZE];
    cipherString[0]= '\0';

    fgets(cipherString, MAX_STRING_SIZE, fCipherIn); 
    fclose(fCipherIn);

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

    // need to load the word list now - should move this up higher though before this loop 
    FILE *fDictIn = fopen(argv[2], "r");
    if(fDictIn == NULL) {
        perror("fopen");
        return 1;
    }

    char *dict[MAX_WORDS];
    int wrdCntr = 0;

    char word[MAX_STRING_SIZE];
    while(fgets(word, MAX_STRING_SIZE, fDictIn)) {
        // word[strcspn(word, "\n")] = '\0';

        dict[wrdCntr] = strdup(word);
        wrdCntr++;
    }

    fclose(fDictIn);

    printf("Dictionary loaded with %d words\n", wrdCntr);

    // make all words in dict lower case 
    for(int i = 0; i < wrdCntr; i++) {
        for(int j = 0; dict[i][j]; j++) {
            dict[i][j] = tolower(dict[i][j]);
        }
    }
    
    // use q sort to sort the dict  
    // refrence for qsort usage: https://stackoverflow.com/questions/23189630/how-to-use-qsort-for-an-array-of-strings
    qsort(dict, wrdCntr, sizeof(char *), strCompare); 

    // need to do the permuations now then the compare 

    //use binary search when doing checks to speed up look up time 

    int n = strlen(decryptDict);
    // refrence for permute usage: https://www.geeksforgeeks.org/c/c-program-to-print-all-permutations-of-a-given-string/
    permute(decryptDict, 0, n - 1);
    





}