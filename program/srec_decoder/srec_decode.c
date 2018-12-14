#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void subString(char* inputLine, int start, size_t n, char* dest) {
	char* src = &inputLine[start];
	strncpy(dest, src, n);
	dest[n] = '\0';
	//printf("%s\n", dest);
}

int main(int argc, char * argv[]){
	const int maxSize = 47;
	FILE* fp = fopen(argv[1], "r");
	FILE* progFile = fopen("program.hex", "w");
	FILE* dataFile = fopen("data.hex", "w");
	char* inputLine = (char*)malloc(maxSize*sizeof(char));
	char* recordType = (char*)malloc(3*sizeof(char));
	char* byteCount = (char*)malloc(5*sizeof(char));
	char* addr_str = (char*)malloc(9*sizeof(char));
	char* instr_hex;

	if (fp==NULL) {
		perror("Couldn't open file for reading.");
		exit(1);
	}
	if (progFile==NULL) {
		perror("Couldn't open file for reading.");
		exit(1);
	}
	if (dataFile==NULL) {
		perror("Couldn't open file for reading.");
		exit(1);
	}

	int i;

	for(i=0; i<1024; i++){
		fprintf(dataFile, "%s", "00000000\n");
	}

	while(fgets(inputLine, maxSize, fp)!=NULL){
		//printf("%s", inputLine);

		size_t addr_size;
		long byteCount_long;
		char* end = NULL;

		subString(inputLine, 0, 2, recordType);
		subString(inputLine, 2, 2, byteCount);
		switch(recordType[1]){
			case '0':
			case '1':
			case '5':
			case '9':
				addr_size = 16 >> 2; //16 bits = 4 bytes (hex digits)
				break;

			case '2':
			case '6':
			case '8':
				addr_size = 24 >> 2;
				break;

			case '3':
			case '7':
				addr_size = 32 >> 2;
				break;

			case '4':
			default:
				break;
		}
		subString(inputLine, 4, addr_size, addr_str);
		byteCount_long = strtol(byteCount, &end, 16) - 3; //2 bytes addr and 1 byte checksum

		instr_hex = (char*)malloc((2*byteCount_long + 1)*sizeof(char));
		subString(inputLine, 4+addr_size, 2*byteCount_long, instr_hex);

		int i;
		//int j;
		char instruction[9];
		char stringCharData[9] = "000000000";

		if(recordType[1] == '1') {
			if(addr_str[0] == '0' && addr_str[1] == '4') {
				for(i=0; i<2*byteCount_long; i+=2){
					stringCharData[6] = instr_hex[i];
					stringCharData[7] = instr_hex[i+1];
					stringCharData[8] = '\0';
					printf(".string: %s\n", stringCharData);
					fprintf(dataFile, "%s\n", stringCharData);
				}
				/*for(i=0; i<2*byteCount_long; i+=8){
					for(j=7; j>0; j-=2) {
						stringCharData[0] = instr_hex[i+j-1];
						stringCharData[1] = instr_hex[i+j];
						stringCharData[2] = '\0';
						printf(".string: %s\n", stringCharData);
						//char_left-=2;
					}
				}*/
			}
			else {
				for(i=0; i<2*byteCount_long; i+=8){ //print out every 32 bits
					instruction[0] = instr_hex[i+6];
					instruction[1] = instr_hex[i+7];
					instruction[2] = instr_hex[i+4];
					instruction[3] = instr_hex[i+5];
					instruction[4] = instr_hex[i+2];
					instruction[5] = instr_hex[i+3];
					instruction[6] = instr_hex[i];
					instruction[7] = instr_hex[i+1];
					instruction[8] = '\0';
					printf("%s\n", instruction);
					fprintf(progFile, "%s\n", instruction);
				}
			}
		}

		//printf("instr hex: %s\n", instr_hex);
		//printf("\n%ld\n", byteCount_long);
		//printf("\n%ld\n\n", addr_size);
		free(instr_hex);
	}
	fclose(fp);
	fclose(dataFile);
	fclose(progFile);

	free(inputLine);
	free(recordType);
	free(byteCount);
	free(addr_str);
}
