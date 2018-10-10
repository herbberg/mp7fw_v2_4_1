/* AVR32_MMC
 * Version 1.2
 * See version.h for full release information.
 *
 * License: GPL (See http://www.gnu.org/licenses/gpl.txt).
 *
 * This file provides the main entry point for the AVR32 MMC code.
 */

#include "imperial_mmc/avr32_arch.h"
#include "imperial_mmc/avr32_debug.h"
#include "imperial_mmc/avr32_timer.h"
#include "imperial_mmc/avr32_led.h"
#include "imperial_mmc/avr32_i2c.h"
#include "imperial_mmc/avr32_ipmi.h"
#include "imperial_mmc/avr32_fru.h"
#include "imperial_mmc/avr32_sdr.h"
#include "imperial_mmc/avr32_spi.h"
#include "imperial_mmc/avr32_pwr.h"
#include "imperial_mmc/avr32_usb.h"
#include "imperial_mmc/avr32_prng.h"
#include "imperial_mmc/avr32_oem.h"

#include "imperial_mmc/avr32_ipbus.h"
#include "imperial_mmc/avr32_dma_pipe.h"
#include "imperial_mmc/avr32_dma_handlers.h"

#include "imperial_mmc/avr32_sensors.h"
#include "imperial_mmc/avr32_sd.h"
#include "imperial_mmc/avr32_sfwfs.h"
#include "imperial_mmc/avr32_fpga.h"
#include <math.h>

// The heartbeat function is called every 1ms
void heartbeat ( void )
{
  led_heartbeat ( TRUE );
  //   ipmi_process();
  gIPMI_needs_checking = true;
}

// Called when data in the FPGA SPI memory changes
void spi_data_cb ( U8 pFlags )
{
  dprintf ( "SPI Mem Flag Changed (%d)!\n", pFlags );
}

int main()
{
  //dprintf("power good = %i, init_b = %i\n", pwr_get_good ( PWR_GPIO_3_3V), arch_read_pin ( FPGA_INIT_B ) );
  wdt_disable();
  dprintf ( "-----------------------------------------------------------------------------------------------------\n" );
  int xCounter = 1; // Start the counter at 1
  // This will give the temp sensor time to settle
  // Otherwise at power on temp will be 0, triggering a notification
  // Which in turn causes contention on the I2C bus...
  int xReset = 0;
  U8 xBusAddr = 0;
  gDummySensor = 0x00000080;
  bool powerGood3v3 = false;
  bool powerGood12v = false;
  int i,j;

#if (!defined(MINI_T5_REV))
  Bool xAltSensors = FALSE; // Keeps track of the sensors to read next
  S8 xSensReading[3] = {};
  S8 xHumid = 0;
  gSensorData = malloc(SDR_RECORDS*sizeof(int));
  for(i=0;i<SDR_RECORDS-1;++i) gSensorData[i]=0.;
#endif
#if (!defined(MINI_T5_REV))
  dprintf ( "AVR32_MMC Startup (MP7/FC7 Version)!\n" );
#else
  dprintf ( "AVR32_MMC Startup (MINI-T5 Version)!\n" );
#endif
  arch_init();
  pwr_init();
  timer_init();
  led_init();
  fru_init();
  prng_seed ( 0xCAFEBABE );
  //spi_mem_register(&spi_data_cb);
  // Wait for the #ENABLE input to go low!
#if (defined(MINI_T5_REV)) && (MINI_T5_REV < 2)
  dprintf ( "Waiting for ENABLE signal.\n" );

  while ( arch_read_pin ( ENABLESIG_GPIO ) );

#else
  dprintf ( "Skipping ENABLE check on MINI-T5R2 or MP7 board...\n" );
#endif
  // Register timer now, after enable signal.
  timer_register ( &heartbeat );
  // Detect our address
  xBusAddr = arch_get_addr();
  //save network (test)
  //fru_save_network();
  // Now we know which slot we're plugged into
  // We can prepare to set-up the network on the FPGA
  fru_load_network();
  // Now we have our address, we can enable i2c/twi
  i2c_init ( xBusAddr );
  // Link the i2c module to the ipmi module...
  ipmi_init ( xBusAddr );
  sdr_init ( xBusAddr );
  i2c_register ( &ipmi_data_rx );
  // MP7 specific enables
#if (!defined(MINI_T5_REV))
  //#endif
  // Enable IPBus on all boards
  ipbus_init();
#endif
  // TODO: Re-enable watchdog
  //   wdt_enable ( IPMI_WDT_TIMEOUT );
  // Run the main MMC loop
  dprintf ( "Starting MMC main loop...\n" );

  dma_pipe_reset ();

  bool previousPowerGood3v3 = false;

  while ( 1 )
  {
    //if ( ! ( xCounter % 1000 ) ) //1000
    //{
      //    sfwfs_test();
      // dma_pipe_test();
      ////		ipbus_test();
    //}

    // check for presence of payload power. if payload power just came on,
    // reinitialize the SD card system.
	//check 12v is stable

	if( !powerGood12v || (pwr_get_12v_value() < 10.4 ) ){
		powerGood12v=true;
		for(i=0;i<250;++i)
		{
			pwr_heartbeat();
			powerGood12v = powerGood12v && (pwr_get_12v_value() > 10.4);
			//dprintf("%d   12v adc = %f, powerGood12v = %d\n", i, pwr_get_12v_value(), powerGood12v);
		}
	}
	i=0;
    powerGood3v3 = pwr_get_good ( PWR_GPIO_3_3V );
    //powerGood12v = pwr_get_good ( PWR_GPIO_12V );
    //dprintf("3v3 = %d, 12v = %d, 12v adc = %f\n", powerGood3v3, powerGood12v, pwr_get_12v_value());

    if (powerGood3v3 && !previousPowerGood3v3) {
		dprintf("[MAIN] payload power just came on\n");
		cpu_delay_ms(1000, FOSCM);
		sensor_init();
		gpio_local_init();
		gpio_enable_12V_up();
		spi_master_init();
		sd_init();
		usb_init();
		fpga_reset();

#if (!defined(MINI_T5_REV))
 		sensor_init();
#endif
		xCounter = 1;
    } else if (previousPowerGood3v3 && !powerGood3v3) {
    	dprintf("[MAIN] payload power just went down\n");
    }
    previousPowerGood3v3=powerGood3v3;

    if (powerGood3v3) dma_pipe_transactor();

    // Read the sensors every ~second
    if ( ! ( xCounter % 1000 ) ) //1000
    {
      pwr_heartbeat();
#if (defined(MINI_T5_REV))
      float xTemp;
      spi_temp_read ( &xTemp );
      //dprintf("Board temp: %f.\n", xTemp);
      sdr_set_temp_reading ( 0, xTemp );
#endif
    }


#if (!defined(MINI_T5_REV))

    // MP7 has a lot of sensors,
    // Read 50% of them every ~4 seconds
    //  2 = Humidity
    //  3 - 10 = Temperatures
    // 11 - 18 = Reading 1, Config 1
    // 19 - 26 = Reading 2, Config 1
    // 27 - 34 = Reading 1, Config 2
    // 35 - 42 = Reading 2, Config 2


    if ( ! ( xCounter % 4003 ) )
    {
      float xTemp=0;
      // Clear the readings
      sdr_blank_readings ( 2, 3, 0x00 );

      if ( !xAltSensors )
      {
        sdr_blank_readings ( 11, 27, 0x80 );
      }
      else
      {
        sdr_blank_readings ( 27, 43, 0x80 );
      }

      // Only do this stuff if the 3.3v power is on!
      if ( powerGood3v3 )
      {
        sensor_sht21_get ( &xHumid );
        sdr_store_reading ( 2, xHumid );
        gSensorData[2] = 1000*((xHumid+SDRs[2][SDR_OFFSET]+((SDRs[2][SDR_OFFSET_MSB]&0xC0)<<2))*pow(10,(SDRs[2][SDR_SCALE]>>4)-(((SDRs[2][SDR_SCALE]>>4)&0x8)<<1)));

        for ( i = 0; i < 8; i++ )
        {
          U8 xBase1 = xAltSensors ? 27 : 11;
          U8 xBase2 = xAltSensors ? 35 : 19;
          ltc2990_read ( i, &xSensReading[0],
                             &xSensReading[1],
                             &xSensReading[2] );
          sdr_store_reading ( i + 3, xSensReading[0] );
          sdr_store_reading ( xBase1 + i, xSensReading[1] );
          sdr_store_reading ( xBase2 + i, xSensReading[2] );
          if((xBase2 + i) == 24 ) xTemp=xSensReading[2];

          for(j=0;j<SDR_RECORDS-1;++j){
        	  if(SDRs[j][SENSOR_NUM]==xBase1+i)	 gSensorData[j]=1000*((xSensReading[1]+SDRs[j][SDR_OFFSET]+((SDRs[j][SDR_OFFSET_MSB]&0xC0)<<2))*pow(10,(SDRs[j][SDR_SCALE]>>4)-(((SDRs[j][SDR_SCALE]>>4)&0x8)<<1)));
        	  if(SDRs[j][SENSOR_NUM]==xBase2+i)  gSensorData[j]=1000*((xSensReading[2]+SDRs[j][SDR_OFFSET]+((SDRs[j][SDR_OFFSET_MSB]&0xC0)<<2))*pow(10,(SDRs[j][SDR_SCALE]>>4)-(((SDRs[j][SDR_SCALE]>>4)&0x8)<<1)));
          }
		}

        if(!xAltSensors){
        	sdr_set_temp_reading ( 0, xTemp);
        	if(xTemp > SDRs[3][SDR_UPPER_NR_OFST]) arch_set_pin ( PWR_GPIO_ENABLE, GPIO_DRIVE_LOW );
		}
        xAltSensors = xAltSensors ? FALSE : TRUE;
        sensor_config ( xAltSensors );
        sensor_trigger();
        sensor_sht21_run();
      }
    }
    //if ( ! ( xCounter % 4003 ) ) for(j=0;j<SDR_RECORDS-1;++j) dprintf("Sensor %i = %f, send = %f \n", j, gSensorData[j]/1000, ( (int) (U32) gSensorData[j]));

    // Do FPGA state machine every time
    if (powerGood3v3 && powerGood12v) fpga_run();

#endif
    //     Now set the IP address is the FPGA is in a good state!
    if ( ! ( xCounter % 8003 ) )
    {
    	if (powerGood3v3 && powerGood12v) fpga_configure_networking();
    }

    if ( gIPMI_needs_checking )
    {
    	ipmi_process();
    }


    // Wait 2 seconds to update the readings...
    if(xCounter > 1500) sdr_poll();

    // Do any USB processing
    usb_run();


    //Various resets and board recovery
    //dprintf("Counter = %i\n", xCounter);

    if ( !gNuclearReset )
    {
    	// Reset the WDT
    	wdt_clear();
	} else if ( gNuclearReset == 1 )
    {
    	//Nuke the board
    	arch_set_pin ( PWR_GPIO_ENABLE, GPIO_DRIVE_LOW );
    	wdt_enable ( 1000000 );
    	gNuclearReset = 2;
    	//Let the WDT nuke the MMC
	}

    if (gHotswapReset == 1 && powerGood3v3 && !gNuclearReset)
    {
		//hotswap reset is a simulated hotswap handle out/in
    	gpio_reset_12V_up();
    	cpu_delay_ms ( 1000, FOSCM );
    	ipmi_send_sensor_event(SENSOR_HOTSWAP_NUM,HOTSWAP_EVENT_OPENED,SENSOR_TYPE_HOTSWAP,SENSOR_EVENT_GA);
		gHotswapReset = 2;
		xReset=xCounter;
    }
    if (gHotswapReset == 2 && !powerGood3v3 && !gNuclearReset && (xReset+5000 < xCounter))
    {
		//after a few seconds, reinsert the hotswap
    	ipmi_send_sensor_event(SENSOR_HOTSWAP_NUM,HOTSWAP_EVENT_CLOSED,SENSOR_TYPE_HOTSWAP,SENSOR_EVENT_GA);
    	gHotswapReset = 0;
		xReset=0;
    }

	if (gFPGAReset == 1)
	{
		dprintf("Reset FPGA...");
		//dprintf("powerGood3v3 = %i, init_b = %i, prog_b = %i\n", powerGood3v3, arch_read_pin ( FPGA_INIT_B ), arch_read_pin (FPGA_PROG_B) );
		fpga_reset();
		gFPGAReset = 0;
	}


    // Finally wait 1ms before doing the loop again
    //cpu_delay_ms ( 1, FOSCM );
    xCounter++;

  }

  return 0;
}
