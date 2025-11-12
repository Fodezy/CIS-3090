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

void permute(char *cipherString, char *decryptWord, char *permuteWord, int l, int r, char *dict[MAX_WORDS], int wrdCntr, int rank) {
    if(l == r) {
        // create mapping
        char mapping[ALPHABET_SIZE] = {0};
        int wordLen = strlen(decryptWord);

        for(int i = 0; i < wordLen; i++) {
            mapping[decryptWord[i] - 97] = permuteWord[i];
        }

        // create decryption with cipherString  
        char possibleWord[MAX_STRING_SIZE] = {0}; 
        int chrCntr = 0;

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

        // need to now use binary search to check for each word within the dict 

        char tempString[MAX_STRING_SIZE] = {0};
        strcpy(tempString, possibleWord);

        // if string is multi words, need to split and check each word on its own 
        char *wordToken = strtok(tempString, " ");      

        int wordsPossible = 0;
        int foundWords = 0;
        while(wordToken != NULL) {
            wordToken[strcspn(wordToken, "\n\r")] = '\0'; // remove newline & carriage return if present
            if(strlen(wordToken) > 0) {
                wordsPossible++;
            
            
                char *key = wordToken;
                char **item = (char**) bsearch(&key, dict, wrdCntr, sizeof(char *), strCompare);
                if (item != NULL) {
                    foundWords++;
                }
            }

            // need to do bsearch here 
            // need to create a flag, such that each word checked must be found for it to be a valid decryption 
            wordToken = strtok(NULL, " ");
        }

        if(wordsPossible > 0 && wordsPossible == foundWords) {
            printf("rank %d: %s\n", rank, possibleWord);
        }
        
        // this is where i would do the dict check 
    } else {
        for(int i = l; i <= r; i++) {
            swap((permuteWord  + l), (permuteWord + i));
            permute(cipherString, decryptWord, permuteWord, l + 1, r, dict, wrdCntr, rank);

            swap((permuteWord + l), (permuteWord + i)); 
        }
    }
}

int strCompare(const void *a, const void *b) {
    const char *const *wordA = (const char *const*)a;
    const char *const *wordB = (const char *const*)b;

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

    // Only rank 0 reads the ciphertext file, then broadcasts it to all processes
    char cipherString[MAX_STRING_SIZE];
    cipherString[0] = '\0';
    int cipherLen = 0;

    if(rank == 0) {
        FILE *fCipherIn = fopen(argv[1], "r");
        if(fCipherIn == NULL) {
            perror("fopen");
            MPI_Finalize();
            return 1;
        }

        if(fgets(cipherString, MAX_STRING_SIZE, fCipherIn) == NULL) {
            fprintf(stderr, "Error: Failed to read ciphertext\n");
            fclose(fCipherIn);
            MPI_Finalize();
            return 1;
        }
        fclose(fCipherIn);

        // remove newline from ciphertext if present
        cipherString[strcspn(cipherString, "\n")] = '\0';
        cipherLen = strlen(cipherString) + 1; // +1 for null terminator
    }

    // Broadcast ciphertext length and content to all processes
    MPI_Bcast(&cipherLen, 1, MPI_INT, 0, MPI_COMM_WORLD);
    MPI_Bcast(cipherString, cipherLen, MPI_CHAR, 0, MPI_COMM_WORLD);

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

    // Only rank 0 reads the dictionary, then broadcasts it to all processes
    char *dict[MAX_WORDS];
    int wrdCntr = 0;

    if(rank == 0) {
        // Rank 0 reads the dictionary file
        FILE *fDictIn = fopen(argv[2], "r");
        if(fDictIn == NULL) {
            perror("fopen");
            MPI_Finalize();
            return 1;
        }

        char word[MAX_STRING_SIZE];
        while(fgets(word, MAX_STRING_SIZE, fDictIn) && wrdCntr < MAX_WORDS) {
            word[strcspn(word, "\n\r")] = '\0';

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
    }

    // Broadcast dictionary size to all processes
    MPI_Bcast(&wrdCntr, 1, MPI_INT, 0, MPI_COMM_WORLD);

    // Allocate memory for dictionary on all processes
    // Rank 0 already has memory allocated via strdup, but we need consistent allocation
    // For simplicity, we'll allocate MAX_STRING_SIZE for each word on all processes
    for(int i = 0; i < wrdCntr; i++) {
        if(rank == 0) {
            // Rank 0: reallocate to ensure consistent size (or keep existing if already correct)
            // Actually, we can keep the strdup'd memory, just ensure it's at least MAX_STRING_SIZE
            // For now, let's reallocate to be safe
            char *oldWord = dict[i];
            dict[i] = (char *)malloc(MAX_STRING_SIZE * sizeof(char));
            strncpy(dict[i], oldWord, MAX_STRING_SIZE - 1);
            dict[i][MAX_STRING_SIZE - 1] = '\0';
            free(oldWord);
        } else {
            // Other ranks: allocate new memory
            dict[i] = (char *)malloc(MAX_STRING_SIZE * sizeof(char));
        }
    }

    // Broadcast each word to all processes
    // Since all words are now allocated to MAX_STRING_SIZE, we can broadcast directly
    for(int i = 0; i < wrdCntr; i++) {
        MPI_Bcast(dict[i], MAX_STRING_SIZE, MPI_CHAR, 0, MPI_COMM_WORLD);
    } 

    // create decryption dict copy to permute
    char permuteDecyptDict[ALPHABET_SIZE] = {0};
    strcpy(permuteDecyptDict, inputDict);

    int n = inputDictLen;

    // When we have fewer processes than unique letters, each process must handle multiple starting letters
    // Process with rank 'r' handles starting letters at positions: r, r+size, r+2*size, ...
    for(int startLetterIdx = rank; startLetterIdx < inputDictLen; startLetterIdx += size) {
        // Reset permuteDecyptDict to original inputDict for each starting letter
        strcpy(permuteDecyptDict, inputDict);
        
        // swap the first letter with the letter at position 'startLetterIdx'
        // this ensures we test permutations starting with this letter
        swap(&permuteDecyptDict[0], &permuteDecyptDict[startLetterIdx]);

        // need to do the permuations now then the compare 
        //use binary search when doing checks to speed up look up time
        if(n > 1) {
            permute(cipherString, inputDict, permuteDecyptDict, 1, n - 1, dict, wrdCntr, rank);
        } else {
            // only one letter, just test it directly
            permute(cipherString, inputDict, permuteDecyptDict, 0, n - 1, dict, wrdCntr, rank);
        }
    }

    // free allocated memory
    for(int i = 0; i < wrdCntr; i++) {
        free(dict[i]);
    }

    MPI_Finalize();
    return 0;
}