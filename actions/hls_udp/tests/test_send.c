#include <arpa/inet.h> 
#include <netinet/in.h> 
#include <string.h>



#define PORT	 8080 
#define MAXLINE 1024 
#define EXIT_FAILURE -1

// Driver code 
int main() { 
	int sockfd;
 	char buffer[MAXLINE];
 	char *hello = "Hello  client cve";
 	struct sockaddr_in	 servaddr;

 	// Creating socket file descriptor
 	if ( (sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0 ) {
 			perror("socket creation failed");
			exit(EXIT_FAILURE);
		}

	memset(&servaddr, 0, sizeof(servaddr));

	// Filling server information
	servaddr.sin_family = AF_INET;
	servaddr.sin_port = htons(PORT);
	servaddr.sin_addr.s_addr = INADDR_ANY;

	int n, len;
	sendto(sockfd, (const char *)hello, strlen(hello),
	MSG_CONFIRM, (const struct sockaddr *) &servaddr, sizeof(servaddr));
	printf("Hello message sent.\n");

	n = recvfrom(sockfd, (char *)buffer, MAXLINE, MSG_WAITALL, (struct sockaddr *) &servaddr, &len);
																				buffer[n] = '\0';
	printf("Server : %s\n", buffer);
	close(sockfd);
	return 0;
}
