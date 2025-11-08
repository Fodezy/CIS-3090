#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <pthread.h>

void* sillyThreadFunc(void* arg);
void ubWrite(char* str);

int main(void)
{
    pthread_t tid;
    pthread_attr_t attr;

    ubWrite("Starting the main thread\n");

    //Nap for 4 seconds
    sleep(2);

    //Initialize thread attributes. 
    //This allocated memory, so we must call pthread_attr_destroy later
    pthread_attr_init(&attr);

    //Make thread detached in the thread attributes
    pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_DETACHED);

    // create a second thread
    pthread_create(&tid, &attr, sillyThreadFunc, NULL);
    pthread_attr_destroy(&attr);

    // pretend to work for a bit, but instead nap for another 4 seconds
    sleep(4);
    
    ubWrite("Ending the main thread\n");

    //remember to clean up the allocated thread attribute
    
    
    return 0;
}

void* sillyThreadFunc(void* arg)
{
    ubWrite("Starting the Silly Function thread\n");

    ubWrite("Threads are awesome!!1!\n");
    // pretend to work for a bit - nap for 2 seconds
    sleep(2);

    ubWrite("Ending the Silly Function thread\n");
    
    return NULL;
}


void ubWrite(char* str){
    write(STDOUT_FILENO, str, strlen(str)+1);
}