#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <time.h>

#define MAX_WORDS 120000
#define MAX_STRING_SIZE 256
#define ALPHABET_SIZE 26

bool isWordInDict() {
    bool isFound = false;
}

void swap(char *x, char *y) {
    char temp;
    temp = *x;
    *x = *y;
    *y = temp;
}

void permute(char *cipherString, char *decryptWord, char *permuteWord, int l, int r) {
    int i; 
    if(l == r) {
        printf("permutation: %s\n", permuteWord);

        // create mapping
        char mapping[ALPHABET_SIZE] = {0};
        int wordLen = strlen(decryptWord);

        for(int i = 0; i < wordLen; i++) {
            mapping[decryptWord[i] - 97] = permuteWord[i];
            printf("mapping[%c - 97] = %c\n", decryptWord[i], permuteWord[i]);
        }

        // create decryption with cipherString  
        char possibleWord[MAX_STRING_SIZE] = {0}; 
        int chrCntr = 0;

        printf("String length: %lu\n", strlen(cipherString));
        printf("STring is: %s\n", cipherString);
        for(int i = 0; i < strlen(cipherString); i++) {
            char c = tolower(cipherString[i]);
            // cases base: normal char, case 1: space or newline, case 2: non alpha char / something out of usualy and i just need to perserve - could combine case 1 & 2 but i'll keep seperate for now for debugging
            if(isalpha(c)) {
                possibleWord[chrCntr] = mapping[c - 97];
                chrCntr++;
            } else if(c == ' ' || c == '\n') {
                possibleWord[chrCntr] = c;
                chrCntr++;
            } else {
                possibleWord[chrCntr] = c;
                chrCntr++;
            }
        }

        possibleWord[chrCntr] = '\0';
        printf("Possible decrypted word: %slength is: %d\n", possibleWord, chrCntr);



        
        // this is where i would do the dict check 
    } else {
        for(int i = l; i <= r; i++) {
            swap((permuteWord  + l), (permuteWord + i));
            permute(cipherString, decryptWord, permuteWord, l + 1, r);

            swap((permuteWord + l), (permuteWord + i)); 
        }
    }
}

int strCompare(const void *a, const void *b) {
    const char *wordA = *(char**)a;
    const char *wordB = *(char**)b;

    return strcmp(wordA, wordB);
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
        return 1;
    }

    FILE *fCipherIn = fopen(argv[1], "r");
    if(fCipherIn == NULL) {
        perror("fopen");
        return 1;
    }

    char cipherString[MAX_STRING_SIZE];
    cipherString[0]= '\0';

    if(!fgets(cipherString, MAX_STRING_SIZE, fCipherIn)) {  // use fgets and check for failure
        fprintf(stderr, "Error using fgets, reading cipher string failed\n");
        fclose(fCipherIn);
        return 1;
    } 
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

    char permuteDecyptDict[ALPHABET_SIZE] = {0};
    strcpy(permuteDecyptDict, decryptDict);

    printf("Permutation copied Decryption dict (unique chars from cipher): %s\n", decryptDict);

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
        word[strcspn(word, "\n")] = '\0';  // remove any newline from a word when reading in from the dict 
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
    // we dont want to modify the original decrypt dict so I made a copy early used within the permutes that can be used to check against the dict
    int n = strlen(permuteDecyptDict);
    // refrence for permute usage: https://www.geeksforgeeks.org/c/c-program-to-print-all-permutations-of-a-given-string/
    permute( cipherString, decryptDict, permuteDecyptDict, 0, n - 1);

    // the above will do the following, for each permutation: it will check each word within the dictionary using binary search (bsearch) 
    //if a word is found it will store it into memory, then countinue untill all permutations have been checked. 
    // to be able to check if a permutatio is valid we need to first decrypt the cipher string using the current permuations as the decryption dict 
    // this invloves doing the reverse of the encryption process done in the previous file 

    // need to create a mapping decrypt (unchanging ever) dict to permuteDcryptDict (changes per permuation)

    // example: decryptDict = achet
    //   permuteDictDecrypt = caeht
    // mapping would looke like: a -> c, c -> a, h -> e, ignore space, e -> h, t-> t, (duplicate ignore: but a -> c)
    // so it become: cae htc --> which is not a word in the dict 

    // to do this mapping I can do the following -> create an array of size 26 (each letter of alphabet)
    // index each position of the map to the decrpytDict: ie map[decryptDict[i]] --> however this becomes out of bounds as lowercase char values range from 97 to 122 (a-z) so we need to offset by base of 97
    // therefore for mapping it needs to be map[decryptDict[i] - 97] --> range will now always be within 0 - 25
    // can set this map to be equal to the permuteDictDecrypt char at the same index:  map[decryptDict[i] - 97] = permuteDictDecrypt[i];

    // after I have this mapping i can do the reverse of the encryption section of a2encrypt to dcrypt the cipher, look up in dict, and store in mem 

    





}