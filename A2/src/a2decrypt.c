// After make run with: mpiexec -n <number of processes> ./a2decrypt_serial <ciphertext file> <dictionary file>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <ctype.h>
#include <time.h>
#include <mpi.h>

#define MAX_WORDS 120000
#define MAX_STRING_SIZE 256
#define ALPHABET_SIZE 26
#define MAX_VALID_RESULTS 100

void swap(char *x, char *y) {
    char temp;
    temp = *x;
    *x = *y;
    *y = temp;
}

// binary search function to check if a word exists in the dictionary
// reference for binary search: https://www.geeksforgeeks.org/binary-search/
int binarySearch(char **dict, int left, int right, char *target) {
    while(left <= right) {
        int mid = left + (right - left) / 2;
        
        // remove newline from dict word for comparison
        char dictWord[MAX_STRING_SIZE];
        strcpy(dictWord, dict[mid]);
        dictWord[strcspn(dictWord, "\n")] = '\0';
        
        int cmp = strcmp(target, dictWord);
        
        if(cmp == 0) {
            return 1; // word found
        }
        if(cmp < 0) {
            right = mid - 1;
        } else {
            left = mid + 1;
        }
    }
    return 0; // word not found
}

// function to decrypt ciphertext using input dict and decryption dict
// this is where I decrypt the string using the two dictionaries
void decryptString(char *ciphertext, char *inputDict, char *decryptDict, char *result) {
    int resultIdx = 0;
    for(int i = 0; i < strlen(ciphertext); i++) {
        char c = tolower(ciphertext[i]);
        
        // keep spaces and newlines as is
        if(c == ' ' || c == '\n') {
            result[resultIdx] = c;
            resultIdx++;
            continue;
        }
        
        // if not alphabetic, skip
        if(!isalpha(c)) {
            continue;
        }
        
        // find position of char in input dict
        int index = -1;
        for(int j = 0; j < strlen(inputDict); j++) {
            if(inputDict[j] == c) {
                index = j;
                break;
            }
        }
        
        // use that position in decrypt dict to get decrypted char
        if(index != -1 && index < strlen(decryptDict)) {
            result[resultIdx] = decryptDict[index];
            resultIdx++;
        }
    }
    result[resultIdx] = '\0';
}

// function to validate if all words in decrypted string are in dictionary
// this is where I check if all words are valid english words
int validateDecryption(char *decryptedText, char **dict, int dictSize) {
    char textCopy[MAX_STRING_SIZE];
    strcpy(textCopy, decryptedText);
    
    // split by spaces and check each word
    char *token = strtok(textCopy, " \n");
    while(token != NULL) {
        // remove any trailing newline or whitespace
        char word[MAX_STRING_SIZE];
        strcpy(word, token);
        word[strcspn(word, "\n")] = '\0';
        
        // skip empty words
        if(strlen(word) == 0) {
            token = strtok(NULL, " \n");
            continue;
        }
        
        // check if word is in dictionary using binary search
        if(binarySearch(dict, 0, dictSize - 1, word) == 0) {
            return 0; // word not found in dictionary
        }
        
        token = strtok(NULL, " \n");
    }
    
    return 1; // all words found in dictionary
}

// function to permute and test decryption dictionaries
// this function tests all permutations starting with a fixed first letter
void permuteWithFirstLetter(char *decryptDict, int l, int r, char *ciphertext, char *inputDict, char **dictionary, int dictSize, int rank) {
    if(l == r) {
        // this is where I would do the dict check 
        char decryptedText[MAX_STRING_SIZE];
        decryptString(ciphertext, inputDict, decryptDict, decryptedText);
        
        // validate the decrypted text
        if(validateDecryption(decryptedText, dictionary, dictSize)) {
            // print valid result with rank
            printf("rank %d: %s\n", rank, decryptedText);
        }
    } else {
        for(int i = l; i <= r; i++) {
            swap((decryptDict + l), (decryptDict + i));
            permuteWithFirstLetter(decryptDict, l + 1, r, ciphertext, inputDict, dictionary, dictSize, rank);
            swap((decryptDict + l), (decryptDict + i)); // backtrack
        }
    }
}

int strCompare(const void *a, const void *b) {
    char *const *wordA = a;
    char *const *wordB = b;

    return strcmp(*wordA, *wordB);
}

int main(int argc, char** argv) {
    // initialize MPI
    int rank, size;
    MPI_Init(&argc, &argv);
    MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    MPI_Comm_size(MPI_COMM_WORLD, &size);

    // reads in the cipher from the ciphertext.txt file 
    // read and store the list of chars from the string 
    // create a decryption dict (ie unique chars from string - like encryption worked)
    // use this decryption list to build and test every permutation possible  
    // --> test each permuation against the american english txt file provided as an array would become way to lare 
    // --> store each valid decryption found into an array 

    if(argc != 3) {
        if(rank == 0) {
            fprintf(stderr, "Error with input args, please use the following format: ./a2decrypt <ciphertext file> <dictionary file>\n");
        }
        MPI_Finalize();
        return 1;
    }

    // all processes read the ciphertext file
    FILE *fCipherIn = fopen(argv[1], "r");
    if(fCipherIn == NULL) {
        if(rank == 0) {
            perror("fopen");
        }
        MPI_Finalize();
        return 1;
    }

    char cipherString[MAX_STRING_SIZE];
    cipherString[0]= '\0';

    fgets(cipherString, MAX_STRING_SIZE, fCipherIn); 
    fclose(fCipherIn);

    // remove newline from ciphertext if present
    cipherString[strcspn(cipherString, "\n")] = '\0';

    // create input dictionary
    int dictCntr = 0; 
    char inputDict[ALPHABET_SIZE] = {0}; // capped at 26 unique chars; length of alphabet
    for(int i = 0; i < strlen(cipherString);i++) {
        char c = tolower(cipherString[i]);
        if(c == ' ' || c == '\n' || isalpha(c) == 0) {
            continue;
        }

        if(strchr(inputDict, c) == NULL) {
            inputDict[dictCntr] = c; 
            dictCntr++;
        }
    }

    inputDict[dictCntr] = '\0'; 

    int inputDictLen = strlen(inputDict);

    // each process only works if its rank is less than the number of unique letters; else the process has nothing to do
    if(rank >= inputDictLen) {
        MPI_Finalize();
        return 0;
    }

    // need to load the word list now - should move this up higher though before this loop  
    FILE *fDictIn = fopen(argv[2], "r");
    if(fDictIn == NULL) {
        if(rank == 0) {
            perror("fopen");
        }
        MPI_Finalize();
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

    // make all words in dict lower case 
    for(int i = 0; i < wrdCntr; i++) {
        for(int j = 0; dict[i][j]; j++) {
            dict[i][j] = tolower(dict[i][j]);
        }
    }
    
    // use q sort to sort the dict
    // refrence for qsort usage: https://stackoverflow.com/questions/23189630/how-to-use-qsort-for-an-array-of-strings
    qsort(dict, wrdCntr, sizeof(char *), strCompare); 

    // create decryption dict copy to permute
    char decryptDict[ALPHABET_SIZE];
    int n = inputDictLen;

    // When we have fewer processes than unique letters, each process must handle multiple starting letters
    // Process with rank 'r' handles starting letters at positions: r, r+size, r+2*size, ...
    for(int startLetterIdx = rank; startLetterIdx < inputDictLen; startLetterIdx += size) {
        // Reset decryptDict to original inputDict for each starting letter
        strcpy(decryptDict, inputDict);
        
        // swap the first letter with the letter at position 'startLetterIdx'
        // this ensures we test permutations starting with this letter
        swap(&decryptDict[0], &decryptDict[startLetterIdx]);

        // need to do the permuations now then the compare 
        //use binary search when doing checks to speed up look up time
        if(n > 1) {
            permuteWithFirstLetter(decryptDict, 1, n - 1, cipherString, inputDict, dict, wrdCntr, rank);
        } else {
            // only one letter, just test it directly
            char decryptedText[MAX_STRING_SIZE];
            decryptString(cipherString, inputDict, decryptDict, decryptedText);
            if(validateDecryption(decryptedText, dict, wrdCntr)) {
                printf("rank %d: %s\n", rank, decryptedText);
            }
        }
    }

    // free allocated memory
    for(int i = 0; i < wrdCntr; i++) {
        free(dict[i]);
    }

    MPI_Finalize();
    return 0;
}

