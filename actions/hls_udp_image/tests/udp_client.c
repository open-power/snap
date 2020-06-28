// Client side implementation of UDP client-server model 
#include <stdio.h> 
#include <stdlib.h> 
#include <unistd.h> 
#include <string.h> 
#include <sys/types.h> 
#include <sys/socket.h> 
#include <arpa/inet.h> 
#include <netinet/in.h> 
#include "bmp.h"
#include "params.h"

#define PORT	 80 
#define MAXLINE 1024 
#define data_size 128*64
#define buff_size 128*64

// Driver code 
int main(int argc, char *argv[]) {
	int sockfd; 
	char buffer[MAXLINE]; 
	struct sockaddr_in servaddr;
	char filename[256];
	BMPImage *Image;
	char *error = NULL;
	int dsize;
	
	readParams(argc, argv);
	printf("input %s\n", parms.input);
	printf("output %s\n", parms.output);
	strcpy(filename, parms.input);

	// open and read bmp file
	Image = read_image(filename, &error);
	dsize = Image->header.size;
	printf("Bitmap size: %d\n",dsize);

	// Creating socket file descriptor 
	if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) { 
		perror("socket creation failed"); 
		exit(EXIT_FAILURE); 
	} 

	memset(&servaddr, 0, sizeof(servaddr)); 
	
	// Filling server information 
	servaddr.sin_family = AF_INET; 
	servaddr.sin_port = htons(PORT); 
	servaddr.sin_addr.s_addr = 0x0532010A; // Big endian in IP header! 0x0A013205 / 10.1.50.5


	unsigned int len;
	
	sendto(sockfd, (const char *)Image->data,dsize,
		MSG_CONFIRM, (const struct sockaddr *) &servaddr, 
			sizeof(servaddr)); 
	printf("image se nt.\n");
		
	recvfrom(sockfd, (char *)buffer, MAXLINE,
				MSG_WAITALL, (struct sockaddr *) &servaddr, 
				&len); 

	printf("image received\n");


	close(sockfd); 
	return 0; 
} 
