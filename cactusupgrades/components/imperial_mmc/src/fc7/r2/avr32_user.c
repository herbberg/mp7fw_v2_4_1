/* AVR32_MMC
 * Version 1.2
 * See version.h for full release information.
 *
 * License: GPL (See http://www.gnu.org/licenses/gpl.txt).
 *
 * Generic source file for implementing user specific functionality
 * using the AVR32 Imperial MMC,  e.g. ipmi oem user commands
 *
 */


#include "imperial_mmc/avr32_arch.h"

#include "imperial_mmc/avr32_oem.h"
#include "imperial_mmc/avr32_ipmi.h"

#include "board.user.h"


int gLedToggle = 0;


U8 oem_cmd_user ( U8* pDataIn, U8 pDataInLen,
                  U8* pDataOut, U8* pDataOutLen )
{
  dprintf ( "[OEM] User Command\n" );
  
  if ( gLedToggle == 1 )
  {
    gpio_set_gpio_pin ( LED_TRI_BLUE );
	gLedToggle = 0;
  }
  else if ( gLedToggle == 0 )
  {
    gpio_clr_gpio_pin ( LED_TRI_BLUE );
	gLedToggle = 1;	
  }
  
  *pDataOutLen = 0x00;
  return IPMI_CC_OK;
}

