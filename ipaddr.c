#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <net/if.h>

#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>

int main(int argc, char **argv) {
    int sock = socket(PF_INET, SOCK_DGRAM, 0);
    struct ifreq req;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <interfacename>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    if (sock < 0) {
        perror("socket");
        exit(EXIT_FAILURE);
    }

    memset(&req, 0, sizeof(req));
    strncpy(req.ifr_name, argv[1], IF_NAMESIZE - 1);

    if (ioctl(sock, SIOCGIFADDR, &req) < 0) {
        perror("ioctl");
        exit(EXIT_FAILURE);
    }

    printf("%s\n", inet_ntoa(((struct sockaddr_in *)&req.ifr_addr)->sin_addr));


    close(sock);

    exit(EXIT_SUCCESS);
    return 0;
}
