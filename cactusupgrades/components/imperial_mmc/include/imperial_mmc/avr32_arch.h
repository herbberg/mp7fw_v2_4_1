/* AVR32_MMC
 * Version 1.2
 * See version.h for full release information.
 *
 * License: GPL (See http://www.gnu.org/licenses/gpl.txt).
 *
 */

#ifndef AVR32_ARCH_H_
#define AVR32_ARCH_H_

// Some defines are required before the includes
// We need these for the sd_mmc library to compile even if it's not used
#define SD_SLOT_4BITS 1
#define SD_SLOT_4BITS_CLK_PIN             AVR32_MCI_CLK_0_PIN
#define SD_SLOT_4BITS_CLK_FUNCTION        AVR32_MCI_CLK_0_FUNCTION
#define SD_SLOT_4BITS_CMD_PIN             AVR32_MCI_CMD_0_PIN
#define SD_SLOT_4BITS_CMD_FUNCTION        AVR32_MCI_CMD_0_FUNCTION
#define SD_SLOT_4BITS_DATA0_PIN           AVR32_MCI_DATA_0_PIN
#define SD_SLOT_4BITS_DATA0_FUNCTION      AVR32_MCI_DATA_0_FUNCTION
#define SD_SLOT_4BITS_DATA1_PIN           AVR32_MCI_DATA_1_PIN
#define SD_SLOT_4BITS_DATA1_FUNCTION      AVR32_MCI_DATA_1_FUNCTION
#define SD_SLOT_4BITS_DATA2_PIN           AVR32_MCI_DATA_2_PIN
#define SD_SLOT_4BITS_DATA2_FUNCTION      AVR32_MCI_DATA_2_FUNCTION
#define SD_SLOT_4BITS_DATA3_PIN           AVR32_MCI_DATA_3_PIN
#define SD_SLOT_4BITS_DATA3_FUNCTION      AVR32_MCI_DATA_3_FUNCTION
#define SD_SLOT_4BITS_CARD_DETECT         AVR32_PIN_PA24
#define SD_SLOT_4BITS_CARD_DETECT_VALUE   0
#define SD_SLOT_4BITS_WRITE_PROTECT       AVR32_PIN_PA24
#define SD_SLOT_4BITS_WRITE_PROTECT_VALUE 1
#define SD_SLOT_8BITS                     0
#define SD_SLOT_8BITS_CLK_PIN             AVR32_MCI_CLK_0_PIN
#define SD_SLOT_8BITS_CLK_FUNCTION	  AVR32_MCI_CLK_0_FUNCTION
#define SD_SLOT_8BITS_CMD_PIN             AVR32_MCI_CMD_0_PIN
#define SD_SLOT_8BITS_CMD_FUNCTION        AVR32_MCI_CMD_0_FUNCTION
#define SD_SLOT_8BITS_DATA0_PIN           AVR32_MCI_DATA_0_PIN
#define SD_SLOT_8BITS_DATA0_FUNCTION      AVR32_MCI_DATA_0_FUNCTION
#define SD_SLOT_8BITS_DATA1_PIN           AVR32_MCI_DATA_1_PIN
#define SD_SLOT_8BITS_DATA1_FUNCTION      AVR32_MCI_DATA_1_FUNCTION
#define SD_SLOT_8BITS_DATA2_PIN           AVR32_MCI_DATA_2_PIN
#define SD_SLOT_8BITS_DATA2_FUNCTION      AVR32_MCI_DATA_2_FUNCTION
#define SD_SLOT_8BITS_DATA3_PIN           AVR32_MCI_DATA_3_PIN
#define SD_SLOT_8BITS_DATA3_FUNCTION      AVR32_MCI_DATA_3_FUNCTION
#define SD_SLOT_8BITS_DATA4_PIN           0
#define SD_SLOT_8BITS_DATA4_FUNCTION      0
#define SD_SLOT_8BITS_DATA5_PIN           0
#define SD_SLOT_8BITS_DATA5_FUNCTION      0
#define SD_SLOT_8BITS_DATA6_PIN           0
#define SD_SLOT_8BITS_DATA6_FUNCTION      0
#define SD_SLOT_8BITS_DATA7_PIN           0
#define SD_SLOT_8BITS_DATA7_FUNCTION      0
#define SD_SLOT_8BITS_CARD_DETECT         AVR32_PIN_PA24
#define SD_SLOT_8BITS_CARD_DETECT_VALUE   0
#define SD_SLOT_8BITS_WRITE_PROTECT       AVR32_PIN_PA24
#define SD_SLOT_8BITS_WRITE_PROTECT_VALUE 1

// Currently we only target 1 CPU so all includes are relevant
#include <avr32/uc3a3256.h>
#include <string.h>

#include "pm.h" // Include power management
#include "intc.h" // Interrupt controller
#include "gpio.h" // Include GPIO control
#include "tc.h" // Timer/counter driver
#include "twim.h" // TWI master driver
#include "twis.h" // TWI slave driver
#include "flashc.h" // Flash programming driver
#include "wdt.h" // Watch-dog timer
#include "spi.h" // SPI driver
#include "cycle_counter.h" // Handy delay routines
#include "adc.h" // ADC for power supply checking
#include "sd_mmc_mci.h"

// Appropriate header for board  defined using build time includes
#include "board.arch.h"

#include "avr32_debug.h"



#define GPIO_DRIVE_LOW 0
#define GPIO_DRIVE_HIGH 1
#define GPIO_FLOAT 2

#define ENTER_CRTICAL_SECTION Disable_global_interrupt
#define EXIT_CRITICAL_SECTION Enable_global_interrupt

// See comments above for descriptions of definitions
#define FOSC_STARTUP 32768
#define FOSC_MAIN 12000000

// Clocks & Oscillators
// Frequency of start-up oscillator (Hz)
#define FOSCST 32768
#define FOSCSST_STARTUP AVR32_PM_OSCCTRL0_STARTUP_2048_RCOSC
// Frequency of CPU core
#define FOSCM 66000000
// Frequency of PBA/PBB busses
#define FOSCM_PB (FOSCM/3)
#define FOSCM_STARTUP AVR32_PM_OSCCTRL1_STARTUP_2048_RCOSC
// Frequency of OSC0
#define FOSC0 12000000
#define FOSC0_STARTUP AVR32_PM_OSCCTRL1_STARTUP_2048_RCOSC

// The timer channel to use for the 1ms heartbeat
#define COUNTER_CHAN 0
#define COUNTER_INTERRUPT AVR32_TC0_IRQ0

// Input/Output GPIO Pins
// GPIO line connected to hot-swap handle sensor
#define HOTSWAP_GPIO AVR32_PIN_PA20
// Following not actually used on boards >Mini-T5R1
#define ENABLESIG_GPIO AVR32_PIN_PA21

// Time until a watchdog timeout (us) (in this case 3 seconds...)
#define IPMI_WDT_TIMEOUT 3000000

// SPI Pins
#define SPI0_GPIO_SCK      AVR32_SPI0_SCK_0_1_PIN
#define SPI0_GPIO_SCK_FN   AVR32_SPI0_SCK_0_1_FUNCTION
#define SPI0_GPIO_MISO     AVR32_SPI0_MISO_0_1_PIN
#define SPI0_GPIO_MISO_FN  AVR32_SPI0_MISO_0_1_FUNCTION
#define SPI0_GPIO_MOSI     AVR32_SPI0_MOSI_0_1_PIN
#define SPI0_GPIO_MOSI_FN  AVR32_SPI0_MOSI_0_1_FUNCTION
#define SPI0_GPIO_CS0      AVR32_SPI0_NPCS_0_1_PIN
#define SPI0_GPIO_CS0_FN   AVR32_SPI0_NPCS_0_1_FUNCTION

#define SPI0_MEM_SEL 0

#define USB_GPIO_ID        AVR32_USBB_USB_ID_0_0_PIN
#define USB_GPIO_ID_FN     AVR32_USBB_USB_ID_0_0_FUNCTION
#define USB_GPIO_VOBF      AVR32_USBB_USB_VBOF_0_0_PIN
#define USB_GPIO_VOBF_FN   AVR32_USBB_USB_VBOF_0_0_FUNCTION

// Size of the SPI memory
// (Used to calculate if upper or lower handshake flag should be set!)
#define SPI_MEM_SIZE 0x0FFF


// A simple function to initialise the architecture
void arch_init ( void );
void gpio_enable_12V_up( void );
void gpio_reset_12V_up( void );
U8 arch_read_pin ( U8 pPin );
void arch_set_pin ( U8 pPin, U8 pState );
U8 arch_get_addr ( void );
U8 arch_get_slot ( void );

#endif /* AVR32_ARCH_H_ */
