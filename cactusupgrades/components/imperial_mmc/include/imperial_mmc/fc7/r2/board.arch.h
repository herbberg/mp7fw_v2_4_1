/* AVR32_MMC
 * Version 1.2
 * See version.h for full release information.
 *
 * License: GPL (See http://www.gnu.org/licenses/gpl.txt).
 *
 */



// LED GPIO Pins
#define NUM_LEDS 4
// LED0 is BLUE LED
#define LED0_GPIO AVR32_PIN_PA18
// LED1-3 are optional.
#define LED1_GPIO AVR32_PIN_PA16
#define LED2_GPIO AVR32_PIN_PA07
#define LED3_GPIO AVR32_PIN_PA19
// Tricolour LEDs
#define LED_TRI_RED   AVR32_PIN_PX47
#define LED_TRI_GREEN AVR32_PIN_PX48
#define LED_TRI_BLUE  AVR32_PIN_PX49


// GPIO
#define GA0_GPIO AVR32_PIN_PA04
#define GA1_GPIO AVR32_PIN_PA05
#define GA2_GPIO AVR32_PIN_PA06
#define GADRIVER_GPIO AVR32_PIN_PA03


// I2C/TWI Pins
#define TWI_GPIO_CLK AVR32_TWIMS1_TWCK_0_PIN
#define TWI_GPIO_CLK_FN AVR32_TWIMS1_TWCK_0_FUNCTION
#define TWI_GPIO_DATA AVR32_TWIMS1_TWD_0_PIN
#define TWI_GPIO_DATA_FN AVR32_TWIMS1_TWD_0_FUNCTION
#define CRATE_TWIM_MODULE (AVR32_TWIM1)
#define CRATE_TWIS_MODULE (AVR32_TWIS1)
#define TWI_SENS_CLK AVR32_TWIMS0_TWCK_0_0_PIN
#define TWI_SENS_CLK_FN AVR32_TWIMS0_TWCK_0_0_FUNCTION
#define TWI_SENS_DATA AVR32_TWIMS0_TWD_0_0_PIN
#define TWI_SENS_DATA_FN AVR32_TWIMS0_TWD_0_0_FUNCTION
#define TWI_SENS_MPLEX_RST AVR32_PIN_PX44
#define SENS_TWIM_MODULE (AVR32_TWIM0)


// Power lines
#define PWR_GPIO_12V      AVR32_ADC_AD_1_PIN
#define PWR_GPIO_12V_FN   AVR32_ADC_AD_1_FUNCTION
#define PWR_GPIO_12V_CHAN 1 // ADC Chan for 12V power
#define PWR_GPIO_3_3V     AVR32_PIN_PB08
#define PWR_GPIO_2_5V     AVR32_PIN_PB09
#define PWR_GPIO_1_8V     AVR32_PIN_PA11
#define PWR_GPIO_1_5V     AVR32_PIN_PB10
#define PWR_GPIO_1_0V     AVR32_PIN_PB04
#define PWR_GPIO_ENABLE   AVR32_PIN_PB07
// TODO: PGOOD_AT lines


// Before FPGA boot:
#define FPGA_GPIO_RESET   AVR32_PIN_PB11
#define FPGA_PROG_B       AVR32_PIN_PX53
#define FPGA_INIT_B       AVR32_PIN_PX54
#define FPGA_DONE         AVR32_PIN_PX55

// After FPGA boot:
#define FPGA_IPBUS_DONE   AVR32_PIN_PB11
#define FPGA_IPBUS_NEW    AVR32_PIN_PX56

// FPGA<->MMC IPBUS registers
#define FPGAtoMMC_COUNTER_ADDRESS 0x00000400
#define MMCtoFPGA_COUNTER_ADDRESS 0x00000401


// The maximum size file we can store
#define SFWFS_DATABLOCK_SIZE 40000
