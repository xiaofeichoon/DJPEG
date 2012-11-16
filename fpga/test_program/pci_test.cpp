#include "stdafx.h"
#include <windows.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "pcifunc.h"
#include "pci_test.h"

#define CR 0x0d
#define LF 0x0a

#define DMA_LMEM_SIZE 1024

typedef unsigned short WORD;
typedef unsigned long DWORD;
typedef long LONG;
/*
typedef struct tagBITMAPINFOHEADER{
  DWORD  biSize;
  LONG   biWidth;
  LONG   biHeight;
  WORD   biPlanes;
  WORD   biBitCount;
  DWORD  biCompression;
  DWORD  biSizeImage;
  LONG   biXPelsPerMeter;
  LONG   biYPelsPerMeter;
  DWORD  biClrUsed;
  DWORD  biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;
*/
unsigned long VenderID = 0x1234;
unsigned long DeviceID = 0x5678;
unsigned long PCI_Dev_Adrs;
unsigned long PCI_Base0;

unsigned int PCI_Bus_Num;
unsigned int PCI_Dev_Num;
unsigned int PCI_Func_Num;

int init_pci( void ){

  // check DLL
  DLLSTATUS CheckDLL;
  CheckDLL = getdllstatus();
  if(CheckDLL == DLLSTATUS_DRIVERNOTLOADED){
    printf("can't open pcidebug.dll\n" );
    return FALSE;
  }
  
  // check card number
  //int i;
  //for(i=0;i<6;i++){
  //	PCI_Dev_Adrs = _pciFindPciDevice(VecderID,DeviceID,i);
  //	PCI_Dev_Adrs = PCI_Dev_Adrs >> 16;
  //	if(PCI_Dev_Adrs==0x00000000){
  //		break;
  //	}
  //}
  
  /////////////////////////////////////////////////////////////////
  // get PCI-BUS information
  /////////////////////////////////////////////////////////////////
  // get device address
  PCI_Dev_Adrs = _pciFindPciDevice(VenderID, DeviceID, 0);	
  PCI_Dev_Adrs = PCI_Dev_Adrs >> 16;
  if(PCI_Dev_Adrs == 0x00000000){
    printf( "don't check a board.\n" );
    return FALSE;
  }else{
    printf( "check board.\n" );
  }
  PCI_Bus_Num  = pciGetBus(PCI_Dev_Adrs);
  PCI_Dev_Num  = pciGetDev(PCI_Dev_Adrs);
  PCI_Func_Num = pciGetFunc(PCI_Dev_Adrs);
  PCI_Base0    = _pciConfigReadLong(PCI_Dev_Adrs,0x0010);
  if( PCI_Base0 == 0 ) {
    printf( "not a configuration.\n" );
    return FALSE;
  }
  
  PCI_Base0    = PCI_Base0 & 0xfffffff0;
  
  _pciConfigWriteLong(PCI_Dev_Adrs,0x04,0x0000FFFF);
  
  return  TRUE;
}

unsigned long pci_inl( long adr ){
  return _MemReadLong(PCI_Base0+adr);
}

void pci_outl(long adr, unsigned long data){
  _MemWriteLong( PCI_Base0+adr, data );
}

void pci_setl( long adr, unsigned long data ){
  unsigned long tmpdata;
  tmpdata = pci_inl( adr );
  pci_outl( adr, tmpdata | data );
}

/*
  program Loader
*/
void jpeg_load(){
  FILE          *fp;

  unsigned long data;
  char file_name[256];
  
  printf("JPEG Filename(default:test.jpg)=");
  fflush(stdin);
  gets( file_name );
  if( !strcmp( file_name, "" ) )
    strcpy( file_name, "test.jpg" );
  if((fp = fopen(file_name, "rb")) == NULL){
    printf("can't open file\n");
    return;
  }
  
  pci_outl( 0x0004001C, 0x00000000 );
  printf("JPEG Reset\n");
  pci_outl( 0x0004001C, 0x00000001 );
  printf("JPEG Reset Clear\n");
  
  if((pci_inl( 0x00040008 ) & 0x00000008) != 0x00000008) return;
  printf("JPEG Load Start\n");
  
  // Load of JPEG Data
  while(!feof(fp)){
    while((pci_inl( 0x00040008 ) & 0x00000004) == 0x00000004) printf("wait\n");
    fread(&data, 1, 4, fp);
    pci_outl( 0x0004000C, data );
  }
  fclose(fp);
  
  printf("JPEG Load End[please etner]\n");
}

void make_bitmap(){
  unsigned long data;
  unsigned char str;
  unsigned int x, y;
  FILE *wfp;

  unsigned long width;
  unsigned long height;
  unsigned char tbuff[4];
  BITMAPINFOHEADER lpBi;

  unsigned char *image;
  unsigned int i;

  if((wfp = fopen("test.bmp","wb")) == NULL){
    perror(0);
    exit(0);
  }

  width	= 256;
  height	= 256;

  image = (unsigned char *)malloc(height*width*3);

  // File Header
  tbuff[0] = 'B';
  tbuff[1] = 'M';
  fwrite(tbuff,2,1,wfp);
  tbuff[3] = (unsigned char)(((14 +40 +width * height * 3) >> 24) & 0xff);
  tbuff[2] = (unsigned char)(((14 +40 +width * height * 3) >> 16) & 0xff);
  tbuff[1] = (unsigned char)(((14 +40 +width * height * 3) >>  8) & 0xff);
  tbuff[0] = (unsigned char)(((14 +40 +width * height * 3) >>  0) & 0xff);
  fwrite(tbuff,4,1,wfp);
  tbuff[1] = 0;
  tbuff[0] = 0;
  fwrite(tbuff,2,1,wfp);
  fwrite(tbuff,2,1,wfp);
  tbuff[3] = 0;
  tbuff[2] = 0;
  tbuff[1] = 0;
  tbuff[0] = 54;
  fwrite(tbuff,4,1,wfp);

  // Information
  lpBi.biSize            = 40;
  lpBi.biWidth           = width;
  lpBi.biHeight          = height;
  lpBi.biPlanes          = 1;
  lpBi.biBitCount        = 3*8;
  lpBi.biCompression     = 0;
  lpBi.biSizeImage       = width*height*3;
  lpBi.biXPelsPerMeter   = 300;
  lpBi.biYPelsPerMeter   = 300;
  lpBi.biClrUsed         = 0;
  lpBi.biClrImportant    = 0;
  fwrite(&lpBi,1,40,wfp);

  i = 0;
  for(y=0;y<256;y++){
    for(x=0;x<256;x++){
      data = pci_inl( (255-y)*256*4+x*4 );
      str = (unsigned char)data & 0x000000FF;
      fwrite(&str, 1, 1, wfp);
      str = (unsigned char)((data & 0x0000FF00) >> 8);
      fwrite(&str, 1, 1, wfp);
      str = (unsigned char)((data & 0x00FF0000) >> 16);
      fwrite(&str, 1, 1, wfp);
    }
  }
  fclose(wfp);
}

void command_help(){
  printf("==============================================\n");
  printf(" Command Help\n");
  printf("==============================================\n");
  printf("w ADDRESS DATA\n");
  printf("r ADDRESS\n");
  printf("\n");
  printf("ld Load JPEG File\n" );
  printf("mb Make Bitmap File\n" );
  printf("\n");
  printf("==============================================\n");
}

void test_ui(void){
  char cmd[256];
  unsigned int wrad,wrdt,rdad,rddt;

  printf("\n");
  printf("<< JPEG Test Console V3.0 >>\n");
  printf("Help Command ... please, type h\n\n");

  while(1) {
    printf("JPEG_TEST> ");
    scanf("%s",cmd);

    if(!strcmp(cmd,"h")){
      command_help();
    }else if(!strcmp(cmd,"w")){
      // Write Command
      scanf("%x %x",&wrad,&wrdt);
      printf("%s %s\n","ADR     ","WR_DATA");
      pci_outl(wrad,wrdt);
      printf("%8x %8x\n",wrad,wrdt);
      continue;
    }else if(!strcmp(cmd,"r")){
      // Read Command
      scanf("%x",&rdad);
      printf("%8s %8s\n","ADR     ","RD_DATA");
      rddt = pci_inl( rdad );
      printf("%8x %8x\n",rdad,rddt);
      continue;
    }else if(!strcmp(cmd,"ld")){
      // Load JPEG File
      jpeg_load();
    }else if(!strcmp(cmd,"mb")){
      // Make Bitmap
      make_bitmap();
    }else if(!strcmp(cmd,"q") | !strcmp(cmd,"quit") | !strcmp(cmd,"exit")){
      // Program End
      return;
    }

    gets(cmd); // buffer get from stdio
  }
}

int _tmain(int argc, _TCHAR* argv[]){
  if(!init_pci()) return 0;
  command_help();
  test_ui();
  return 0;
}

