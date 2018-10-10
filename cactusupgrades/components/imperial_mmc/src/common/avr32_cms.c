#include "imperial_mmc/avr32_cms.h"
#include "imperial_mmc/avr32_arch.h"
#include "imperial_mmc/avr32_ipmi.h"
#include "imperial_mmc/avr32_fru.h"
#include "imperial_mmc/avr32_usb.h"

// obtain MAC address of this board using CMS standard command
U8 oem_cmd_getmacaddress ( U8* pDataIn, U8 pDataInLen,
                           U8* pDataOut, U8* pDataOutLen )
{
  *pDataOutLen = 0x00;
  dprintf ( "[CMS] get MAC address command!\n" );

  if ( pDataInLen > 1 )
  {
    // more than one argument -> fail
    return IPMI_CC_REQ_DATA_INV_LENGTH;
  }

  // determine number of MAC address that is requested,
  // which must be 0 because all boards running this code
  // only have one network interface and thus one MAC address
  U8 nmac = 0;
  if ( pDataInLen == 1 )
  {
    struct IPMI_CMS_GETMAC_REQ* xRequest =
      ( struct IPMI_CMS_GETMAC_REQ* ) pDataIn;

    nmac =xRequest->nMac;
  }

  if ( nmac!=0 )
  {
    // invalid MAC address requested. Return status code 0xcc
    *pDataOutLen = 1;
    *pDataOut = 0xcc;
  }
  else
  {
    struct IPMI_CMS_GETMAC_RESP* xResp =
      ( struct IPMI_CMS_GETMAC_RESP* ) pDataOut;
    *pDataOutLen = sizeof ( struct IPMI_CMS_GETMAC_RESP );

    // determine MAC address, MAC address type (48 or 64 bit), checksum
    xResp->Status = 0x00;
    fru_get_net_mac ( xResp->MACAddr );
    U8 pLen = sizeof( xResp->MACAddr );
    if ( pLen==6 ) xResp->MACtype = 0x01;
    if ( pLen==8 ) xResp->MACtype = 0x02;
    xResp->MACchecksum = ipmi_checksum(xResp->MACAddr, pLen);
  }


  return IPMI_CC_OK;
}



U8 oem_cmd_getipaddress ( U8* pDataIn, U8 pDataInLen,
                          U8* pDataOut, U8* pDataOutLen )
{
  *pDataOutLen = 0x00;
  dprintf ( "[CMS] get IP address command!\n" );

  if ( pDataInLen > 1 )
  {
    // more than one argument -> fail
    return IPMI_CC_REQ_DATA_INV_LENGTH;
  }

  // determine number of IP address that is requested,
  // which must be 0 because all boards running this code
  // only have one network interface and thus one MAC address
  U8 nip = 0;
  if ( pDataInLen == 1 )
  {
    struct IPMI_CMS_GETIP_REQ* xRequest =
      ( struct IPMI_CMS_GETIP_REQ* ) pDataIn;

    nip =xRequest->nIP;
  }

  // check whether we are in RARP mode, in which case the MMC does not
  // know the current IP address
  U8 rarp = 0;
  fru_get_net_rarp ( &rarp );


  if ( nip!=0 )
  {
    // invalid IP address requested. Return status code 0xcc
    *pDataOutLen = 1;
    *pDataOut = 0xcc;
  }
  else if ( rarp!=0 )
  {
    // we don't actually know the IP address because the FPGA obtains it itself
    *pDataOutLen = 1;
    *pDataOut = 0xc2;
  }
  else
  {
    struct IPMI_CMS_GETIP_RESP* xResp =
      ( struct IPMI_CMS_GETIP_RESP* ) pDataOut;
    *pDataOutLen = sizeof ( struct IPMI_CMS_GETIP_RESP );

    xResp->Status = 0x00; // success
    xResp->IPtype = 0x01; // address type IPv4
    fru_get_net_ip ( xResp->IPAddr );
    xResp->IPchecksum = ipmi_checksum(xResp->IPAddr, 4);
  }

  return IPMI_CC_OK;
}


U8 oem_cmd_setipaddress ( U8* pDataIn, U8 pDataInLen,
                          U8* pDataOut, U8* pDataOutLen )
{
  *pDataOutLen = 0x00;
  dprintf ( "[CMS] Set IP address command!\n" );

  if ( (pDataInLen !=6) && (pDataInLen != 10) )
  {
    // expect interface number, address type, IP address
    // and optionally a netmask (which we will ignore).
    // any other length of the request is thus invalid.
    return IPMI_CC_REQ_DATA_INV_LENGTH;
  }

  struct IPMI_CMS_SETIP_REQ* xRequest =
    ( struct IPMI_CMS_SETIP_REQ* ) pDataIn;


  // determine number of IP address that is requested,
  // which must be 0 because all boards running this code
  // only have one network interface and thus one IP address
  if ( xRequest->nIP!=0 )
  {
    // invalid IP address requested. Return status code 0xcc
    *pDataOutLen = 1;
    *pDataOut = 0xcc;
  }
  else if ( xRequest->IPtype!=1 )
  {
    // we only have IPv4 addresses (type 1). Return error.
    *pDataOutLen = 1;
    *pDataOut = 0xc2;
  }
  else
  {
    // set the IP address
    fru_set_net_ip ( xRequest->IPAddr );
    // disable RARP mode
    U8 rarp = 0;
    fru_set_net_rarp ( &rarp );
    // enable network
    U8 netenable = 1;
    fru_set_net_enable( &netenable );
    
    // IPMI response
    struct IPMI_CMS_SETIP_RESP* xResp =
      ( struct IPMI_CMS_SETIP_RESP* ) pDataOut;
    *pDataOutLen = sizeof ( struct IPMI_CMS_SETIP_RESP );

    xResp->Status = 0x00;
    xResp->IPchecksum = ipmi_checksum(xRequest->IPAddr, 4);
  }

  return IPMI_CC_OK;
}


