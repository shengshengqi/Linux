// int pipeSize(){//计算管道长度，原理是写满然后读出来
//   int ret,count=0,filedes[2];  
//   pipe(filedes);//filedes[2]是一个输出参数，它返回2个文件描述符，其中filedes[0]用于读管道、filedes[1]用于写管道。
//     fcntl(filedes[1],F_SETFL,O_NONBLOCK); //系统调用，将管道设置为非阻塞方式
//                                             //F_SETFL设置给arg描述符状态标志,可以更改的几个标志是：O_APPEND， O_NONBLOCK，O_SYNC和O_ASYNC。
//     while(1)  
//     {  
//         ret=write(filedes[1],"fff",1);//write  
//         if(ret==-1)  break;   //full
//         count++;  
//     }  
//     printf("pipe size is:%dB\n\n",count);
//     close(filedes[0]);
//     close(filedes[1]);
//     return count;
// }

// /*如果发生错误，则返回错误*/
// #define check_error(err)                                        \
//     if(err < 0){                                                \
//         fprintf(stderr, "Error : %s \n",strerror(errno) );      \
//         exit(EXIT_FAILURE);                                     \
//     }   

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <semaphore.h>
#include <sys/ipc.h>
#include <sys/msg.h>
#include <fcntl.h>
#define MAXSIZE 100

#define check_error(err)                                        \
    if(err < 0){                                                \
        exit(0);                                                 \
    }       

sem_t mutex;

int pipeSize(){//计算管道长度，原理是写满然后读出来
  int ret,count=0,filedes[2];
  pipe(filedes);//filedes[2]是一个输出参数，它返回2个文件描述符，其中filedes[0]用于读管道、filedes[1]用于写管道。
    fcntl(filedes[1],F_SETFL,O_NONBLOCK); //系统调用，将管道设置为非阻塞方式
                                            //F_SETFL设置给arg描述符状态标志,可以更改的几个标志是：O_APPEND， O_NONBLOCK，O_SYNC和O_ASYNC。
    while(1)
    {
        ret=write(filedes[1],"fff",1);
        if(ret==-1)  break;   //写满了
        count++;
    }
    printf("pipe size is:%dB\n\n",count);
    close(filedes[0]);
    close(filedes[1]);
    return count;
}
int main()
{
    int err;
    int fd[2];
    pid_t pid[3]; //子进程pid
    pipeSize(); //测试管道长度

    sem_init(&mutex, 0, 1);

    err = pipe(fd);
    check_error(err);

    pid_t temp;
    pid[0] = fork();
    check_error(pid[0]);
    if (pid[0] == 0)
    {
        sem_wait(&mutex);
        close(fd[0]); //关闭读，只写        
        char m[MAXSIZE] = "I am the message send by child1.\n";
        printf("this is child1 now\n");
        write(fd[1], m, sizeof(m));
        sem_post(&mutex);

        exit(0); //退出子进程
    }

    pid[1] = fork();
    check_error(pid[1]);
    if (pid[1] == 0)
    {
        sem_wait(&mutex);
        close(fd[0]);
        char m[MAXSIZE] = "I am the message send by child2.\n";
        printf("this is child2 now\n");
        write(fd[1], m, sizeof(m));
        sem_post(&mutex);

        exit(0);
    }
 pid[2] = fork();
    check_error(pid[2]);
    if (pid[2] == 0)
    {
        sem_wait(&mutex);
        close(fd[0]);
        char m[MAXSIZE] = "I am the message send by child3.\n";
        printf("this is child3 now\n");
        write(fd[1], m, sizeof(m));
        sem_post(&mutex);

        exit(0);
    }

    waitpid(pid[0],NULL,WUNTRACED);
    waitpid(pid[1],NULL,WUNTRACED);
    waitpid(pid[2],NULL,WUNTRACED);

    close(fd[1]); //关闭写，只读

    char buf[MAXSIZE];

    while(1){
        int status = read(fd[0], buf, sizeof(buf));
        if(status<=0)
            break;
        else
            printf("%s", buf);
    }
    return 0;
}

