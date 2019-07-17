#include "share_memory.h"

int main(){
    // init 
    int shmid = shmget(KEY_NUM, 1024, 0666|IPC_CREAT);
    if(shmid < -1){
        fprintf(stderr, "shmget Error %s\n", strerror(errno));
        exit(EXIT_FAILURE);	
    }

    char * shmptr = shmat(shmid, NULL, 0);

    full = sem_open("full_shm", O_CREAT, 0666, 0);
    mutex = sem_open("mutex_shm", O_CREAT, 0666, 1);
    empty = sem_open("empty_shm", O_CREAT, 0666, 1);

    // receive message
    char result[1024];

    sem_wait(full);	
    sem_wait(mutex);

    strcpy(result, shmptr);
    printf("[message receive] %s\n", result);
    strcpy(shmptr,"over");

    sem_post(mutex);
    sem_post(empty);

    sem_wait(full);

    //确认接收后，释放信号量
    sem_close(mutex);
    sem_unlink("mutex_shm");

    sem_close(full);
    sem_unlink("full_shm");

    sem_close(empty);
    sem_unlink("empty_shm");

    //释放共享内存
    shmctl(shmid, IPC_RMID, NULL);

    return 0;
}
