#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/time.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#define SERV_PORT 6000
#define BUF_SIZE 128

int main(int argc, char *argv[]){
    if(argc < 2){
        fprintf(stderr, "usage: %s <MSG>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    int sockfd;
    if((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0){
        perror("create_sockfd error");
        exit(EXIT_FAILURE);
    }

    struct sockaddr_in servaddr;
    struct timeval tv;
    tv.tv_sec = 0;
    tv.tv_usec = 1000;
    memset(&servaddr, 0, sizeof(servaddr));
    servaddr.sin_family = AF_INET;
    if(inet_pton(AF_INET, "127.0.0.1", &servaddr.sin_addr) <= 0){
        perror("convert_servaddr error");
        exit(EXIT_FAILURE);
    }
    servaddr.sin_port = htons(SERV_PORT);

    char buf[BUF_SIZE];
    int nbuf = strlen(argv[1]);
    sendto(sockfd, argv[1], nbuf, 0, (struct sockaddr *)&servaddr, sizeof(servaddr));
    if (setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO,&tv,sizeof(tv)) < 0) {
      perror("time out setting failed");
      return -1;
    }
    nbuf = recvfrom(sockfd, buf, BUF_SIZE, 0, NULL, NULL);
    buf[nbuf] = 0;
    printf("%s", buf);

    close(sockfd);
    return 0;
}