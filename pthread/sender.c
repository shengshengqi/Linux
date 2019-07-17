/*
IPC_CREAT | 0666其含义为,不存在则创建，访问权限为0666（新建权限默认值）
0666
从左向右:
第一位:表示这是个八进制数 000
第二位:当前用户的经权限:6=110(二进制),每一位分别对就 可读,可写,可执行,,6说明当前用户可读可写不可执行
第三位:group组用户,6的意义同上
第四位:其它用户,每一位的意义同上,0表示不可读不可写也不可执行
*/
#include "share_memory.h"

int main(){
    // init 
    int shmid = shmget(KEY_NUM, 1024, 0666|IPC_CREAT);
    if(shmid < -1){
        fprintf(stderr, "shmget Error %s\n", strerror(errno));
        exit(EXIT_FAILURE);
    }

    char * shmptr = shmat(shmid, NULL, 0);

    //有名信号量
    full = sem_open("full_shm", O_CREAT, 0666, 0);
    mutex = sem_open("mutex_shm", O_CREAT, 0666, 1);
    empty = sem_open("empty_shm", O_CREAT, 0666, 1);

    // input message 
    char input[1024];  
    printf("Please input the message you want to send.\n");
    scanf("%s", input);

    // send message 
    sem_wait(empty);
    sem_wait(mutex);

    strcpy(shmptr, input);
    
    sem_post(mutex);
    sem_post(full);

    // get message
    char output[1024];
    sem_wait(empty);
    sem_wait(mutex);
    
    strcpy(output,shmptr);
    printf("[message receive] %s\n", output);
    
    sem_post(mutex);
    sem_post(full);

    return 0;
}
