#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

void* sillyThreadFunc(void* arg);
void ubWrite(char* str);

int main(void)
{
    pthread_t tid;

    ubWrite("Starting the main thread\n");

    //Nap for 2 seconds
    sleep(2);

    // create a second thread
    pthread_create(&tid, NULL, sillyThreadFunc, NULL);

    // pretend to work for a bit, but instead nap for another 4 seconds
    sleep(4);

    //Wait for thread to join
    //Since threads are joinable by default, failing to do this will cause a memory leak
    pthread_join(tid, NULL);

    ubWrite("Ending the main thread\n");
    
    return 0;
}

void* sillyThreadFunc(void* arg)
{
    ubWrite("Starting the Silly Function thread\n");

    ubWrite("Threads are awesome!!1!\n");
    // pretend to work for a bit - nap for 2 seconds
    sleep(4);

    ubWrite("Ending the Silly Function thread\n");
    
    return NULL;
}


void ubWrite(char* str){
    write(STDOUT_FILENO, str, strlen(str)+1);
}