 
#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <stdint.h>
#include <termios.h>
#include <string.h>


unsigned char lenData[] = { 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04, 0x00 } ;

unsigned char blockData[] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";
unsigned char blockData2[] = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA";

unsigned char blockDataCmd[512];
unsigned char lenDataCmd[8];

unsigned char retData[128];

unsigned long long lenCmdStr;


int main( int argCnt, char * argLst[] ) 

	{
	int fd ;
	ssize_t ret;
	int i ;
	int fUser;

	fd = open( "/dev/ttyS3", O_RDWR | O_NOCTTY | O_NDELAY | O_DIRECT | O_SYNC);
	if( fd == -1 )
		{
		printf( "Error opening Serial device\n" ) ;
		return 1 ;
		}

	//******************************************************************************************
	// no input params, so just try the static, default User data
	//******************************************************************************************
	if( argCnt == 1 )
		{
		ret = write(fd, lenData, 8 );
		if( ret != 8 )
					{
					printf( "Error sending count\n" ) ;
					return 1 ;
					}
		ret = write(fd, blockData, 64 );
		if( ret != 64 )
				{
				printf( "Error sending First Block\n" ) ;
				return 1 ;
				}
		ret = write(fd, blockData2, 64 );
		if( ret != 64 )
				{
				printf( "Error sending Second Block\n" ) ;
				return 1 ;
				}
		}

	//******************************************************************************************
	// read a file and use that. 2 params: directory file
	//******************************************************************************************		
	else if( argCnt == 3 )
		{
		FILE *fU;
		char fullFN[128];
		long long fLen ;
		int ret ;
		char buff[128];
		long long i;
		long long bitsLeft;
		int x;
		
		if( ( strlen( &argLst[1][0] ) + strlen( &argLst[2][0] ) ) >= 128 )
				{
				printf( "Dir FileName length error\n" ) ;
				return 1 ;
				}
		memset( fullFN, 0, sizeof( fullFN ) ) ;
		strcpy( fullFN, &argLst[1][0] );
		strcat( fullFN, &argLst[2][0] );
		
		printf( "File: %s\n", fullFN ) ;
		
		fUser = open( fullFN, O_RDONLY | O_BINARY );
		if( fUser == -1 )
			{
			printf( "Error opening input file\n" ) ;
			return 1 ;
			}	
		fLen = lseek( fUser, 0, SEEK_END);
		printf( "File Size: %d\n", fLen ) ;
		close(fUser);
		fU = fopen( fullFN, "rb" );
		if( !fU )
			{
			printf( "Error re-opening input file\n" ) ;
			return 1 ;
			}

		// build and send the Bit Length Packet
		lenCmdStr = (long long)fLen ;
		lenCmdStr *= 8;
		
//		printf( "File Bit Length: %d\n", lenCmdStr );
		
		lenDataCmd[7] = (unsigned char)(lenCmdStr >> (8*0) );
		lenDataCmd[6] = (unsigned char)(lenCmdStr >> (8*1) );
		lenDataCmd[5] = (unsigned char)(lenCmdStr >> (8*2) );
		lenDataCmd[4] = (unsigned char)(lenCmdStr >> (8*3) );
		lenDataCmd[3] = (unsigned char)(lenCmdStr >> (8*4) );
		lenDataCmd[2] = (unsigned char)(lenCmdStr >> (8*5) );
		lenDataCmd[1] = (unsigned char)(lenCmdStr >> (8*6) );
		lenDataCmd[0] = (unsigned char)(lenCmdStr >> (8*7) );
		
//		printf( "lenDataCmd[]: 0x%02x%02x%02x%02x%02x%02x%02x%02x\n", lenDataCmd[0], lenDataCmd[1], lenDataCmd[2], lenDataCmd[3], lenDataCmd[4], lenDataCmd[5], lenDataCmd[6],lenDataCmd[7] ) ;
		
		ret = write(fd, lenDataCmd, 8 );
		if( ret != 8 )
				{
				printf( "Error sending count\n" ) ;
				return 1 ;
				}

		// send the file data
		printf( "Starting Bit count: %lld\n", lenCmdStr ) ;
		for( i = 0, bitsLeft = lenCmdStr ; i < lenCmdStr ; i += 512, bitsLeft -= ( bitsLeft >= 512 ? 512 : bitsLeft ) )
			{
			ret = fread(buff, 1,     ( bitsLeft >= 512 ? 64 : bitsLeft/8 ), fU ) ;
			if( ret != 64 && ret != bitsLeft/8 )
					{
					printf( "Error reading byte: %llu ret: %d  want: %d  bitsLeft: %d\n", i, ret, ( bitsLeft >= 512 ? 512 : bitsLeft/8 ), bitsLeft ) ;
					return 1 ;
					}
			ret = write(fd, buff, ( bitsLeft >= 512 ? 64 : bitsLeft/8 ) );
			if( ret != 64 && ret != bitsLeft/8 )
					{
					printf( "Error sending byte: 0x%llx (%llu) %d\n", i, i, ret ) ;
					return 1 ;
					}
					
			if( ( i % 1000 ) == 0 )
				{
				printf( "." ) ;
				fflush(stdout); 
				}
			}
			
		printf( "file delivered\n" );
		fclose(fU);
		}
		
	//******************************************************************************************
	// take an input string as the User Data
	//******************************************************************************************
	else
		{
		long long i;
		long long bitsLeft;
		
		// build and send the Bit Length Packet
		lenCmdStr = (long long)strlen( argLst[1] ) ;
		lenCmdStr *= 8;
		
		printf( "String Length: %d\n", strlen( argLst[1] ) );
		printf( "String       : %s\n", &argLst[1][0] );
		
		
		lenDataCmd[7] = (unsigned char)(lenCmdStr >> (8*0) );
		lenDataCmd[6] = (unsigned char)(lenCmdStr >> (8*1) );
		lenDataCmd[5] = (unsigned char)(lenCmdStr >> (8*2) );
		lenDataCmd[4] = (unsigned char)(lenCmdStr >> (8*3) );
		lenDataCmd[3] = (unsigned char)(lenCmdStr >> (8*4) );
		lenDataCmd[2] = (unsigned char)(lenCmdStr >> (8*5) );
		lenDataCmd[1] = (unsigned char)(lenCmdStr >> (8*6) );
		lenDataCmd[0] = (unsigned char)(lenCmdStr >> (8*7) );
		
		printf( "lenDataCmd[]: 0x%02x%02x%02x\n", lenDataCmd[5], lenDataCmd[6],lenDataCmd[7] ) ;
		
		ret = write(fd, lenDataCmd, 8 );
		if( ret != 8 )
				{
				printf( "Error sending count\n" ) ;
				return 1 ;
				}
printf( "Sent Length\n" ) ;
		// send the string
		for( i = 0, bitsLeft = lenCmdStr ; i < lenCmdStr ; i += 64, bitsLeft -= 64 )
			{
				ret = write(fd, &argLst[ 1 ][ i ], ( bitsLeft >= 64 ? 64 : bitsLeft/8 ) );
				if( ret != 64 && ret != bitsLeft/8 )
						{
						printf( "Error sending byte: 0x%llx (%llu)\n", i, i ) ;
//						return 1 ;
						}
			}
			
		}
printf( "Sent\n" ) ;
	//******************************************************************************************
	// get the result from the device and print them
	//******************************************************************************************
	for( i = 0 ; i < 64 ; i++ )
		{
        write(fd, lenData, 1 );
		do
			{
	        	ret = read(fd, &retData[i], 1 ) ;
			}
		while( ret != 1 ) ;
		printf( "%c", retData[i] ) ;
		}
	close( fd );

	// done
	printf( "\nDone\n" ) ;

	return( 0 ) ;
	}

