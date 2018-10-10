#include "imperial_mmc/avr32_dma_handlers.h"

#include "imperial_mmc/avr32_fru.h"
#include "imperial_mmc/avr32_sdr.h"
#include "imperial_mmc/avr32_sfwfs.h"
#include "imperial_mmc/avr32_oem.h"

#include "imperial_mmc/avr32_dma_pipe.h"

#include <math.h>
#include <string.h>

//32 bytes
char gTextSpace[32] = { 0 } ;
int *gSensorData = 0;
bool gSecureMode = false;


void SetTextSpace ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] Receiving Text into text space\n" );
  memset ( gTextSpace , 0 , 32 );

  if ( *aSizeRemaining == 0 )
  {
    return;
  }

  if ( *aSizeRemaining > 8 )
  {
    *aErrorMsg = "Message size exceeded space available";
    return;
  }

  while ( DMA_FPGAtoMMC_data_available() < *aSizeRemaining )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Before: '%s'\n", gTextSpace );
  DMA_FPGAtoMMC ( (U32*) gTextSpace , *aSizeRemaining );
  dprintf ( "[DMAH] After: '%s'\n", gTextSpace );

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Sending reply - all good\n" );
  U32 lMem[2] = { 0 , 0 };
  DMA_MMCtoFPGA ( lMem , 2 );
  *aSizeRemaining = 0;
}

void GetTextSpace ( U32* aSizeRemaining , char** aErrorMsg ){

	dprintf("[DMAH] Get text space...\n");
	if ( *aSizeRemaining != 0 )
	{
		*aErrorMsg = "Incorrect payload size";
		return;
	}

	U32 lMem[2] = { 0 , 8 };
	DMA_MMCtoFPGA ( lMem , 2 );

	while ( DMA_MMCtoFPGA_space_available() < 8 )
	{
		cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
	}

	DMA_MMCtoFPGA ( (U32*) gTextSpace , 8 );
	dprintf("[DMAH] Sent text space: %s\n", gTextSpace);
}

void GetSensorData ( U32* aSizeRemaining , char** aErrorMsg ){

	dprintf("[DMAH] Get sensor data...\n");
	if ( *aSizeRemaining != 0 )
	{
		*aErrorMsg = "Incorrect payload size";
		return;
	}

	U32 lMem[2] = { 0 , 30 };
	DMA_MMCtoFPGA ( lMem , 2 );

	while ( DMA_MMCtoFPGA_space_available() < 30 )
	{
		cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
	}

	DMA_MMCtoFPGA (  (U32*) gSensorData , 30 );

	dprintf("[DMAH] Sent sensor data.\n");


}


void EnterSecureMode ( U32* aSizeRemaining , char** aErrorMsg )
{
  gSecureMode = false;

  if ( *aSizeRemaining == 0 )
  {
    return;
  }

  if ( *aSizeRemaining > 8 )
  {
    *aErrorMsg = "Message size exceeded space available";
    return;
  }

  while ( DMA_FPGAtoMMC_data_available() < *aSizeRemaining )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Before: '%s'\n", gSecureMode?"Unlocked":"Locked" );
  char lPassword[32] = { 0 } ;
  char* lPasswordValue = "RuleBritannia" ;
  DMA_FPGAtoMMC ( (U32*) lPassword , *aSizeRemaining );

  if ( strcmp ( lPassword , lPasswordValue ) != 0 )
  {
    *aErrorMsg = "Password incorrect";
    return;
  }

  dprintf ( "[DMAH] Britannia rules the waves!\n" );
  gSecureMode = true;
  dprintf ( "[DMAH] After: '%s'\n", gSecureMode?"Unlocked":"Locked" );

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Sending reply - all good\n" );
  U32 lMem[2] = { 0 , 0 };
  DMA_MMCtoFPGA ( lMem , 2 );
  *aSizeRemaining = 0;
}


void SetDummySensor ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] Receiving dummy sensor value\n" );

  if ( *aSizeRemaining != 1 )
  {
    *aErrorMsg = "Incorrect payload size";
    return;
  }

  while ( DMA_FPGAtoMMC_data_available() < *aSizeRemaining )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Before: '%lu'\n", gDummySensor );
  DMA_FPGAtoMMC ( &gDummySensor , 1 );
  dprintf ( "[DMAH] After: '%lu'\n", gDummySensor );

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Sending reply - all good\n" );
  U32 lMem[2] = { 0 , 0 };
  DMA_MMCtoFPGA ( lMem , 2 );
  *aSizeRemaining = 0;
}


void FileToSD ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] Add file to SD card\n" );
  U32 lFileOffset;
  //REMOVED FOR DEBUGGING!
  //       if ( strcmp ( gTextSpace , gDefaultBinFile ) == 0 )
  //       {
  //         *aErrorMsg = "Default image file is inviolate";
  //         return;
  //       }
  dprintf ( "[DMAH] Mounting Filesystem\n" );

  // M. Pesaresi : odd timing issue discovered under very specific set of circumstances
  // required the following to reset the SD interface in order to write data to SD.
  // The interface appears to lock up after successfully updating the file table and
  // fails to copy the file data. MMC does not monitor for this error so operation 
  // appears to complete 'successfully' - result is that either FPGA fails to load or  
  // loads an old image on the SD residing in the location being requested.
  // Uncomment this (and similar changes in avr32_sfwfs.c) if issue is found to
  // be more widespread.
  /*
  sd_init();
  cpu_delay_ms ( 1000, FOSCM );
  */

  if ( sfwfs_mount () != SFWFS_ERR_NONE )
  {
    *aErrorMsg = "[DMAH] Failed To Mount Filesystem";
    return;
  }

  if ( sfwfs_new ( gTextSpace , SFWFS_DATABLOCK_SIZE , &lFileOffset ) != SFWFS_ERR_NONE )
  {
    // ERROR HANDLING!
    sfwfs_unmount ();
    *aErrorMsg = "[DMAH] Failed To create new file";
    return;
  }

  dprintf ( "[DMAH] Successfully created file '%s'\n" , gTextSpace );
  sd_mmc_mci_dma_write_open ( AVR32_SD_SLOT , lFileOffset , (void*) FPGA_ADDR , SFWFS_DATABLOCK_SIZE );

  while ( *aSizeRemaining )
  {
    U32 lWordsAvailable = DMA_FPGAtoMMC_data_available();
    U32 lSectorsToTransfer;

    if ( *aSizeRemaining < lWordsAvailable )
    {
      lSectorsToTransfer = *aSizeRemaining >> 7; // aReadAvailable words = aReadAvailable * 4 bytes = aReadAvailable * 4 / 512 sectors =  (aReadAvailable << 2) >> 9 = aReadAvailable >> 7
    }
    else
    {
      lSectorsToTransfer = lWordsAvailable >> 7; // aReadAvailable words = aReadAvailable * 4 bytes = aReadAvailable * 4 / 512 sectors =  (aReadAvailable << 2) >> 9 = aReadAvailable >> 7
    }

    if ( lSectorsToTransfer )
    {
      dprintf("KHDEBUG: %i sectors to transfer, first word %08h",lSectorsToTransfer,(void*)FPGA_ADDR); 
      sd_mmc_mci_write_multiple_sector_from_ram ( AVR32_SD_SLOT, (void*) FPGA_ADDR, lSectorsToTransfer );
      *aSizeRemaining -= ( lSectorsToTransfer<<7 );
    }
    else
    {
      cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
    }

    if ( gIPMI_needs_checking )
    {
      ipmi_process();
    }
  }

  sd_mmc_mci_write_close ( AVR32_SD_SLOT );
  sfwfs_unmount ();
  dprintf ( "[DMAH] Filesystem unmounted\n" );

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention

    if ( gIPMI_needs_checking )
    {
      ipmi_process();
    }
  }

  dprintf ( "[DMAH] Sending reply - all good\n" );
  U32 lMem[2] = { 0 , 0 };
  DMA_MMCtoFPGA ( lMem , 2 );
}



void FileFromSD ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] Reading file from SD card\n" );
  U32 lFileOffset, lSize;
  U32 lSizeRemaining = 512 * SFWFS_DATABLOCK_SIZE / 4;

  if ( *aSizeRemaining != 0 )
  {
    *aErrorMsg = "Incorrect payload size";
    return;
  }

  dprintf ( "[DMAH] Mounting Filesystem\n" );

  if ( sfwfs_mount () != SFWFS_ERR_NONE )
  {
    *aErrorMsg = "Failed To Mount Filesystem";
    return;
  }

  if ( sfwfs_find ( gTextSpace , &lFileOffset, &lSize ) != SFWFS_ERR_NONE )
  {
    // ERROR HANDLING!
    sfwfs_unmount ();
    *aErrorMsg = "Failed To open file";
    return;
  }

  dprintf ( "[DMAH] Successfully opened file '%s'\n" , gTextSpace );
  sd_mmc_mci_dma_read_open ( AVR32_SD_SLOT , lFileOffset , (void*) FPGA_ADDR , SFWFS_DATABLOCK_SIZE );
  dprintf ( "[DMAH] Sending Header\n" );

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention

    if ( gIPMI_needs_checking )
    {
      ipmi_process();
    }
  }

  U32 lMem[2] = { 0 , lSizeRemaining };
  DMA_MMCtoFPGA ( lMem , 2 );
  dprintf ( "[DMAH] Sending Body\n" );

  while ( lSizeRemaining )
  {
    U32 lWordSpaceAvailable = DMA_MMCtoFPGA_space_available();
    U32 lSectorsToTransfer;

    if ( lSizeRemaining < lWordSpaceAvailable )
    {
      lSectorsToTransfer = lSizeRemaining >> 7; // aReadAvailable words = aReadAvailable * 4 bytes = aReadAvailable * 4 / 512 sectors =  (aReadAvailable << 2) >> 9 = aReadAvailable >> 7
    }
    else
    {
      lSectorsToTransfer = lWordSpaceAvailable >> 7; // aReadAvailable words = aReadAvailable * 4 bytes = aReadAvailable * 4 / 512 sectors =  (aReadAvailable << 2) >> 9 = aReadAvailable >> 7
    }

    if ( lSectorsToTransfer )
    {
      sd_mmc_mci_read_multiple_sector_2_ram ( AVR32_SD_SLOT, (void*) FPGA_ADDR, lSectorsToTransfer );
      lSizeRemaining -= ( lSectorsToTransfer<<7 );
    }
    else
    {
      cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
    }

    //     if ( ! ( i++ %500 ) )
    //     {
    //       dprintf( "lSizeRemaining = %u\n" , lSizeRemaining );
    //     }
    if ( gIPMI_needs_checking )
    {
      ipmi_process();
    }
  }

  dprintf ( "[DMAH] Sending Body done\n" );
  sd_mmc_mci_read_close ( AVR32_SD_SLOT );
  dprintf ( "[DMAH] Read Close done\n" );
  sfwfs_unmount ();
  dprintf ( "[DMAH] Filesystem unmounted\n" );
}






void RebootFPGA ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] Rebooting the FPGA\n" );

  if ( *aSizeRemaining != 0 )
  {
    *aErrorMsg = "Incorrect payload size";
    return;
  }

  if ( !gSecureMode )
  {
    *aErrorMsg = "MMC not in secure mode";
    return;
  }

  dprintf ( "[DMAH] Before: '%u'\n", arch_read_pin ( FPGA_DONE ) );
  fpga_reset();
  dprintf ( "[DMAH] After: '%u'\n", arch_read_pin ( FPGA_DONE ) );

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Sending reply - all good\n" );
  dprintf ( "[DMAH] Text space is '%s'.\n", gTextSpace );
  U32 lMem[2] = { 0 , 0 };
  DMA_MMCtoFPGA ( lMem , 2 );
  *aSizeRemaining = 0;
}



void DeleteFromSD ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] Delete file from SD card\n" );
  //REMOVED FOR DEBUGGING!
  //       if ( strcmp ( gTextSpace , gDefaultBinFile ) == 0 )
  //       {
  //         *aErrorMsg = "Default image file is inviolate";
  //         return;
  //       }

  if ( *aSizeRemaining != 0 )
  {
    *aErrorMsg = "Incorrect payload size";
    return;
  }

  if ( !gSecureMode )
  {
    *aErrorMsg = "MMC not in secure mode";
    return;
  }

  dprintf ( "[DMAH] Mounting Filesystem\n" );

  if ( sfwfs_mount () != SFWFS_ERR_NONE )
  {
    *aErrorMsg = "Failed To Mount Filesystem";
    return;
  }

  if ( sfwfs_del ( gTextSpace ) != SFWFS_ERR_NONE )
  {
    // ERROR HANDLING!
    sfwfs_unmount ();
    *aErrorMsg = "Failed To delete file";
    return;
  }

  sfwfs_unmount ();

  while ( DMA_MMCtoFPGA_space_available() < 2 )
  {
    cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
  }

  dprintf ( "[DMAH] Sending reply - all good\n" );
  U32 lMem[2] = { 0 , 0 };
  DMA_MMCtoFPGA ( lMem , 2 );
  *aSizeRemaining = 0;
}



void ListFilesOnSD ( U32* aSizeRemaining , char** aErrorMsg )
{
  dprintf ( "[DMAH] List files on SD card\n" );

  if ( *aSizeRemaining != 0 )
  {
    *aErrorMsg = "Incorrect payload size";
    return;
  }

  dprintf ( "[DMAH] Mounting Filesystem\n" );

  if ( sfwfs_mount () != SFWFS_ERR_NONE )
  {
    *aErrorMsg = "Failed To Mount Filesystem";
    return;
  }

  int xRet;
  char* xFilename;
  U32 xSize, xEntry, xBlock;
  U32 lSize = 0;
  dprintf ( "[DMAH] Calculating payload size\n" );
  xEntry = 0;
  xBlock = 0;

  while ( true )
  {
    xRet = sfwfs_iter ( &xFilename, &xSize, &xBlock, &xEntry );

    if ( xRet == SFWFS_ERR_ENOENTRY )
    {
      break;  // No more files
    }

    if ( xRet )
    {
      *aErrorMsg = "Failed To iterate over Filesystem";
      sfwfs_unmount ();
      return;
    }

    lSize += 8; //Send filenames as 32-byte chunks and sort it out on client side
  }

  U32 lMem[2] = { 0 , lSize };
  DMA_MMCtoFPGA ( lMem , 2 );
  dprintf ( "[DMAH] Sending payload\n" );
  xEntry = 0;
  xBlock = 0;

  while ( true )
  {
    xRet = sfwfs_iter ( &xFilename, &xSize, &xBlock, &xEntry );

    if ( xRet == SFWFS_ERR_ENOENTRY )
    {
      break;  // No more files
    }

    while ( DMA_MMCtoFPGA_space_available() < 8 )
    {
      cpu_delay_ms ( 1, FOSCM ); //Otherwise we get serious bus contention
    }

    DMA_MMCtoFPGA ( (U32*) xFilename , 8 );
  }

  sfwfs_unmount ();
}




void NuclearReset ( U32* aSizeRemaining , char** aErrorMsg )
{
  if ( !gSecureMode )
  {
    *aErrorMsg = "MMC not in secure mode";
    return;
  }

  gNuclearReset = 1;
  //Don't send any reply, just nuke...
}

void HotswapReset ( U32* aSizeRemaining , char** aErrorMsg )
{
  if ( !gSecureMode )
  {
    *aErrorMsg = "MMC not in secure mode";
    return;
  }

  gHotswapReset = 1;
  //Don't send any reply.
}

void FPGAReset ( U32* aSizeRemaining , char** aErrorMsg )
{

	if ( !gSecureMode )
	  {
	    *aErrorMsg = "MMC not in secure mode";
	    return;
	  }

	  gFPGAReset = 1;
	  //Don't send any reply.
}
