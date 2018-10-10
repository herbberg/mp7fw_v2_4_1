/* AVR32_MMC
 * Version 1.2
 * See version.h for full release information.
 *
 * License: GPL (See http://www.gnu.org/licenses/gpl.txt).
 *
 * This file handles the I2C interface to the sensors that are only
 * present on the MP7 board.
 *
 */

#if (!defined(MINI_T5_REV))

#include "imperial_mmc/avr32_sensors.h"
#include "imperial_mmc/avr32_fru.h"
#include <math.h>

// Appropriate header for board  defined using build time includes
#include "board.sensors.h"


// I2C Bus set-up
static twi_options_t I2C_OPTS =
{
  .pba_hz = FOSCM,
  .speed = I2C_SPEED_400K,
  .chip = 0,
  .smbus = FALSE
};

#define NUM_SENSORS (sizeof(gSensors)/sizeof(struct LTC2990))

// The current bus selected on the I2C multiplexer
static U8 gCurBus = -1;
// Current sensor config (as some have two)
static Bool gCurConfig = FALSE;


void sensor_init()
{
  dprintf ( "Initialising Sensors...\n" );
  gCurBus = -1;

  if ( twi_master_init ( &SENS_TWIM_MODULE, &I2C_OPTS, FALSE ) )
  {
    dprintf ( "[SENS] WARNING: Failed to init i2c!\n" );
  }

  // Just clear the multiplexer by pulsing reset pin
  //gpio_clr_gpio_pin(TWI_SENS_MPLEX_RST);
  //cpu_delay_ms(5, FOSCM);
  gpio_set_gpio_pin ( TWI_SENS_MPLEX_RST );
  //cpu_delay_ms(5, FOSCM);
  //initialize current offset values
  gCurrOffsets[0] = 0x80;
  gCurrOffsets[1] = 0x80;
}

void sensor_bussel ( U8 pBus )
{
  // Select requested bus and humidity bus (0)
  U8 xSel = ( 1 << pBus ) | 0x1;

  // Only switch bus if needed
  if ( pBus == gCurBus )
  {
    return;
  }

  if ( twim_write ( &SENS_TWIM_MODULE, &xSel, 1, 0x70, FALSE ) )
  {
    dprintf ( "Failed to write sensor bus!\n" );
  }

  gCurBus = pBus;
}

U8 sensor_config ( Bool pAltConfig )
{
  int i;
  U8 xConfig[2];

  // We need to apply the new config to each sensor
  for ( i = 0; i < NUM_SENSORS; i++ )
  {
    sensor_bussel ( gSensors[i].bus );
    xConfig[0] = 0x01; // Write control register on LTC2990
    xConfig[1] = ( pAltConfig ? gSensors[i].config_b :
                   gSensors[i].config_a );

    if ( twim_write ( &SENS_TWIM_MODULE,
                      xConfig, 2,
                      gSensors[i].addr, FALSE ) )
    {
      dprintf ( "Failed to apply config to sensor %d!\n", i );
    }

    //dprintf("Conf %d: 0x%02X\n", i, xConfig[1]);
  }

  gCurConfig = pAltConfig;
  return 0;
}

// Trigger a sensor read
U8 sensor_trigger ( void )
{
  int i;
  U8 xConfig[2];

  for ( i = 0; i < NUM_SENSORS; i++ )
  {
    sensor_bussel ( gSensors[i].bus );
    xConfig[0] = 0x02; // Write trigger register on LTC2990
    xConfig[1] = 0xFF;

    if ( twim_write ( &SENS_TWIM_MODULE,
                      xConfig, 2,
                      gSensors[i].addr, FALSE ) )
    {
      dprintf ( "Failed to trigger sensor %d!\n", i );
    }
  }

  return 0;
}

float ltc2990_conv_temp ( U8 xMSB, U8 xLSB )
{

#if (!defined(MP7_REV) || MP7_REV>0)
  if ( ! ( xMSB & 0x80 ) )
  {
    dprintf ( "WARNING: Temp sensor not ready!\n" );
  }
  else
  {
    if ( xMSB & 0x40 )
    {
      dprintf ( "WARNING: Sensor shorted! (diode diff V < 0.14 V)\n" );
    }

    if ( xMSB & 0x20 )
    {
      dprintf ( "WARNING: Sensor open alarm (sensor diff V > 1V \n" );
    }
  }
#endif

  U16 temp = ( ( ( U16 ) ( xMSB & 0x1F ) << 8 ) | ( U16 ) ( xLSB ) );
  float xRes = temp;
  return  xRes / 16.0 ;
}

float ltc2990_conv_volt ( U8 xMSB, U8 xLSB, float scale )
{

  float result = 0.0;
  	U16 xRes = ((xMSB & 0x3F) << 8) + xLSB;
  	if(xMSB & 0x40){
  		xRes = ~xRes;
  		xRes = xRes & 0x3FFF;
  		xRes += 1;
  		result = xRes*(-1.0);
  	}else{
  		result = xRes;
  	}

  return result * 0.00030518 * scale;
}

float ltc2990_conv_curr ( U8 xMSB, U8 xLSB, float scale )
{

	float result = 0.0;
	U16 xRes = ((xMSB & 0x3F) << 8) + xLSB;
	if(xMSB & 0x40){
		xRes = ~xRes;
		xRes = xRes & 0x3FFF;
		xRes += 1;
		result = xRes*(-1.0);
	}else{
		result = xRes;
	}
	return ( ( result * 0.01942 ) /  0.1 ) * scale ; //return 100mA units

}

inline float ltc2990_scale ( float pRaw, float pExp )
{
  return pRaw / 0.1;
}

U8 ltc2990_read ( U8 pSensor, S8* pTemp,
                  S8* pRes1, S8* pRes2 )
{

  //Retrieve current offset factors for 12v & 3v3
  fru_get_curr_offset (gCurrOffsets);

  float xV1 = gSensors[pSensor].exp1;
  float xV2 = gSensors[pSensor].exp2;
  U8 xAddr = 0x04; // Start of value registers
  U8 xRegs[12] = {};
  float xIntTemp;
  float xReading1;
  float xReading2;
  sensor_bussel ( gSensors[pSensor].bus );

  if ( twim_write ( &SENS_TWIM_MODULE, &xAddr, 1, gSensors[pSensor].addr, FALSE ) )
  {
    dprintf ( "Sensor write error (%d)\n", pSensor );
  }

  if ( twim_read ( &SENS_TWIM_MODULE, xRegs, 12, gSensors[pSensor].addr, FALSE ) )
  {
    dprintf ( "Sensor read error (%d)\n", pSensor );
  }

  //dprintf("Got: 0x%02X 0x%02X\n", xRegs[0], xRegs[1]);
  //dprintf("     0x%02X 0x%02X\n", xRegs[2], xRegs[3]);
  //dprintf("     0x%02X 0x%02X\n", xRegs[4], xRegs[5]);
  //dprintf("     0x%02X 0x%02X\n", xRegs[6], xRegs[7]);
  //dprintf("     0x%02X 0x%02X\n", xRegs[8], xRegs[9]);
  //dprintf("     0x%02X 0x%02X\n", xRegs[10], xRegs[11]);
  
  // Now convert the readings into real values
  xIntTemp = ltc2990_conv_temp ( xRegs[0], xRegs[1] );

  switch ( 0x7 & ( gCurConfig ? gSensors[pSensor].config_b :
                   gSensors[pSensor].config_a ) )
  {
    case 0: // V1, T2
      xReading1 = ltc2990_conv_volt ( xRegs[2], xRegs[3], gSensors[pSensor].vscale1 ) - xV1;
      xReading2 = ltc2990_conv_temp ( xRegs[6], xRegs[7] );
      xReading1 = ltc2990_scale ( xReading1, xV1 );
      break;
    case 1: // I1, T2
      xReading1 = ltc2990_conv_curr ( xRegs[2], xRegs[3], gSensors[pSensor].iscale1 );
      xReading2 = ltc2990_conv_temp ( xRegs[6], xRegs[7] );
      break;
    case 2: // I1, V2
      xReading1 = ltc2990_conv_curr ( xRegs[2], xRegs[3], gSensors[pSensor].iscale1 );
      xReading2 = ltc2990_conv_volt ( xRegs[6], xRegs[7], gSensors[pSensor].vscale2 ) - xV2;
      xReading2 = ltc2990_scale ( xReading2, xV2 );
      break;
    case 3: // T1, V2
      xReading1 = ltc2990_conv_temp ( xRegs[2], xRegs[3] );
      xReading2 = ltc2990_conv_volt ( xRegs[6], xRegs[7], gSensors[pSensor].vscale2 )- xV2;
      xReading2 = ltc2990_scale ( xReading2, xV2 );
      break;
    case 4: // T1, I2
      xReading1 = ltc2990_conv_temp ( xRegs[2], xRegs[3] );
      xReading2 = ltc2990_conv_curr ( xRegs[6], xRegs[7], gSensors[pSensor].iscale2 );
      break;
    case 5: // T1, T2
      xReading1 = ltc2990_conv_temp ( xRegs[2], xRegs[3] );
      xReading2 = ltc2990_conv_temp ( xRegs[6], xRegs[7] );
      break;
    case 6: // I1, I2
      xReading1 = ltc2990_conv_curr ( xRegs[2], xRegs[3], gSensors[pSensor].iscale1 );
      xReading2 = ltc2990_conv_curr ( xRegs[6], xRegs[7], gSensors[pSensor].iscale2 );
      if(pSensor==2 && gCurrOffsets[1] != 0x80 ) xReading2 += ( gCurrOffsets[1] & 0x80 ) ? 16.2 - ((double) gCurrOffsets[1] - 256) : 16.2 - (double) gCurrOffsets[1];
      if(pSensor==3 && gCurrOffsets[0] != 0x80 ) xReading1 += ( gCurrOffsets[0] & 0x80 ) ? 34.1 - ((double) gCurrOffsets[0] - 256) : 34.1 - (double) gCurrOffsets[0];
      break;
    case 7: // V1, V2
    default:
      xReading1 = ltc2990_conv_volt ( xRegs[2], xRegs[3], gSensors[pSensor].vscale1 )- xV1;
      xReading2 = ltc2990_conv_volt ( xRegs[6], xRegs[7], gSensors[pSensor].vscale2 )- xV2;
      xReading1 = ltc2990_scale ( xReading1, xV1 );
      xReading2 = ltc2990_scale ( xReading2, xV2 );
  }
  if(xIntTemp <1 && xIntTemp >-1) xIntTemp=xIntTemp/fabs(xIntTemp);    //if close to nominal value, set to plus/minus
  if(xReading1<1 && xReading1>-1) xReading1=xReading1/fabs(xReading1); // 1 to prevent ipmitool registering disabled
  if(xReading2<1 && xReading2>-1) xReading2=xReading2/fabs(xReading2); // sensor (temporary fix until we have our own system manager)
  *pTemp = xIntTemp;
  *pRes1 = xReading1;
  *pRes2 = xReading2;
  return 0;
}

float sht21_conv_humi ( U8 xMSB, U8 xLSB )
{
  float xRes = xLSB & 0xFC;
  xRes += ( xMSB << 8 );
  xRes /= 0x10000;
  xRes *= 125.0;
  return xRes - 6;
}

U8 sensor_sht21_run ( void )
{
  // Ask the sensor to read the humidity
  U8 xCmd = 0xF5; // Read Humidity with no hold

  if ( twim_write ( &SENS_TWIM_MODULE, &xCmd, 1, 0x40, FALSE ) )
  {
    dprintf ( "SHT21 sensor write error!\n" );
    return -1;
  }

  return 0;
}

U8 sensor_sht21_get ( S8* pHumid )
{
  U8 xRes[3];

  if ( twim_read ( &SENS_TWIM_MODULE, xRes, 3, 0x40, FALSE ) )
  {
    dprintf ( "SHT21 sensor read error!\n" );
  }

  //dprintf("Hum: 0x%02X 0x%02X 0x%02X\n", xRes[0], xRes[1], xRes[2]);
  // TODO: Check humidity checksum here?
  *pHumid = sht21_conv_humi ( xRes[0], xRes[1] );
  return 0;
}

#endif
