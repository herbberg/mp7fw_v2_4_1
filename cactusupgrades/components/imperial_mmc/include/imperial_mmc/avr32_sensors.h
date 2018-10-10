/* AVR32_MMC
 * Version 1.2
 * See version.h for full release information.
 *
 * License: GPL (See http://www.gnu.org/licenses/gpl.txt).
 *
 */

#ifndef AVR32_SENSORS_H_
#define AVR32_SENSORS_H_

#include "avr32_arch.h"

#define I2C_SPEED_100K 100000
#define I2C_SPEED_400K 400000

void sensor_init();
void sensor_bussel ( U8 pBus );
U8 sensor_config ( Bool pAltConfig );
U8 sensor_trigger ( void );
U8 ltc2990_read ( U8 pSensor, S8* pTemp,
                  S8* pRes1, S8* pRes2 );
U8 sensor_sht21_run ( void );
U8 sensor_sht21_get ( S8* pHumid );


struct LTC2990
{
	U8 bus; // I2C bus (after the multiplexer)
	U8 addr;
	U8 config_a;
	U8 config_b;
	float exp1; // Expected value for config_a channel 1
	float exp2; // Expected value for config_a channel 2
	float vscale1; // Voltage scale due to potential divider for channel 1
	float vscale2; // Voltage scale due to potential divider for channel 2
	float iscale1; // Current scale due to potential divider/r_sense for channel 1
	float iscale2; // Current scale due to potential divider/r_sense for channel 2
};


#endif /* AVR32_SENSORS_H_ */
