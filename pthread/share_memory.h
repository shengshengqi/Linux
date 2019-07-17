#ifndef   __SHARE_MEMORY_H
#define   __SHARE_MEMORY_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <semaphore.h>
#include <sys/types.h>
#include <unistd.h>
#include <sys/shm.h>
#include <errno.h>

//通过相同的KEY_NUM实现共享内存，此处1024可修改非固定。
#define KEY_NUM 1024

sem_t * full;
sem_t * empty;
sem_t * mutex;
#endif