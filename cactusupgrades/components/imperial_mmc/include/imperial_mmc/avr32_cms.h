#ifndef AVR32_CMS_H_
#define AVR32_CMS_H_

#include "avr32_arch.h"

U8 oem_cmd_getmacaddress ( U8* pDataIn, U8 pDataInLen,
                           U8* pDataOut, U8* pDataOutLen );

U8 oem_cmd_getipaddress ( U8* pDataIn, U8 pDataInLen,
                          U8* pDataOut, U8* pDataOutLen );

U8 oem_cmd_setipaddress ( U8* pDataIn, U8 pDataInLen,
                          U8* pDataOut, U8* pDataOutLen );


struct IPMI_CMS_GETMAC_REQ
{
  U8 nMac;
} __attribute__ ( ( __packed__ ) );

struct IPMI_CMS_GETMAC_RESP
{
  U8 Status;
  U8 MACtype;
  U8 MACchecksum;
  U8 MACAddr[6];
} __attribute__ ( ( __packed__ ) );

struct IPMI_CMS_GETIP_REQ
{
  U8 nIP;
} __attribute__ ( ( __packed__ ) );

struct IPMI_CMS_GETIP_RESP
{
  U8 Status;
  U8 IPtype;
  U8 IPchecksum;
  U8 IPAddr[4];
} __attribute__ ( ( __packed__ ) );


struct IPMI_CMS_SETIP_REQ
{
  U8 nIP;
  U8 IPtype;
  U8 IPAddr[4];
} __attribute__ ( ( __packed__ ) );

struct IPMI_CMS_SETIP_RESP
{
  U8 Status;
  U8 IPchecksum;
} __attribute__ ( ( __packed__ ) );


#endif /* AVR32_CMS_H_ */

