#include <pthread.h>
#include <semaphore.h>
#include <sys/types.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/ipc.h>
#include <sys/msg.h>

//message buffer struct,experiment instruction book
typedef struct msgbuf
{
    long mtype; //unsigned long type,>0
    char mtext[128]; //128,message content
}msgbuf;

//sem_t:actually long int
sem_t full;
sem_t empty;
sem_t mutex;

//messageid
int msgid;

msgbuf buf;//buffer

void *receive(void *a)
{
    //init msg
    int flag=0;
    while(1)
    {
        //sem_wait = wait
        //may cause deadlock if changing these two wait
        if(flag==2){
            sem_destroy(&full);
            sem_destroy(&empty);
            sem_destroy(&mutex);
            break;
        }
        
        sem_wait(&full);//wait for sender
        sem_wait(&mutex);//mutex for message queue
        
        //receive from message queue
        msgrcv(msgid,&buf,sizeof(buf.mtext),1,0);
        //print message
        printf("Receiver thread: %s\n\n",buf.mtext);
        //if received "end"
        if(strcmp(buf.mtext,"end1") == 0)
        {
            flag=flag+1;
            buf.mtype=2;
            strcpy(buf.mtext,"over1");//send the response
            msgsnd(msgid,&buf,sizeof(buf.mtext),0);
        }else if(strcmp(buf.mtext,"end2") == 0)
        {
            flag=flag+1;
            buf.mtype=2;
            strcpy(buf.mtext,"over2");
            msgsnd(msgid,&buf,sizeof(buf.mtext),0);
        }else {
            sem_post(&empty);
        }
        //sem_post = signal
        sem_post(&mutex);

    }
   msgctl(msgid,IPC_RMID,NULL);
   pthread_exit(NULL);
}

void *sender(void *a)
{
    char s[100];
    char end[10];
    char send[20];
    sprintf(end,"end%d",*(int *)a);
    sprintf(send," (sender %d)",*(int *)a);

    buf.mtype = 1;
    int flag=0;
    while(1)
    {
        sem_wait(&empty);//wait for receive*(int *)
        sem_wait(&mutex);//mutex for message queue

        printf("Input the message to sender %d\n",*(int *)a);
        scanf("%s",s);
        if(strcmp(s,"exit") == 0)//if user input "exit" to quit
        {
            strcpy(s,end);
            strcpy(buf.mtext,s);
            msgsnd(msgid,&buf,sizeof(buf.mtext),0);
            printf("Sender process: %s\n",buf.mtext );
            sem_post(&full);
            sem_post(&mutex);
            break;
        }
        else {
            strcat(s,send);        
            strcpy(buf.mtext,s);
            msgsnd(msgid,&buf,sizeof(buf.mtext),0);
            printf("Sender process: %s\n",buf.mtext );
            sem_post(&full);
            sem_post(&mutex);
        }
    }
    while (1)
    {
        ssize_t st = msgrcv(msgid,&buf,sizeof(buf.mtext),2,IPC_NOWAIT);
        if(st!=-1){
            printf("Response content: ");
            printf("%s\n",buf.mtext );//print the response
            printf("Thanks for use sender%d!\n",*(int *)a);
            buf.mtype=1;
            break;
        }
    }
    sem_post(&empty);
    pthread_exit(NULL);
}

int main()
{
    //pthread_t:thread description symbol
    pthread_t senderID1;
    pthread_t senderID2;
    pthread_t receiveID;
    key_t key = 0;//key=0 means create a new message queue

    int symbol1=1,symbol2=2;
    sem_init(&full,0,0);
    sem_init(&empty,0,1);
    sem_init(&mutex,0,1);

    //S_IRUSR|S_IWUSR:allow user to read and write
    if((msgid = msgget(key, S_IRUSR|S_IWUSR)) == -1) {
        printf("Create Message Queue Error\n");
        exit(0);
    }
    pthread_create(&senderID1,NULL,sender,&symbol1);
    pthread_create(&senderID2,NULL,sender,&symbol2);
    pthread_create(&receiveID,NULL,receive,NULL);
    /*
        pthread_join()
        waiting for the thread end
    */
    pthread_join(senderID1,NULL);
    pthread_join(senderID2,NULL);
    pthread_join(receiveID,NULL);

    return 0;
}
