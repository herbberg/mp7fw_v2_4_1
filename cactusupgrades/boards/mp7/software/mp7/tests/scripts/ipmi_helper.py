#!/bin/env python
"""
Usage: ipmi_helper.py --mch < MCH IP address / DNS alias > --slot <slot number> [--info] [--IP < new IP address >] [--MAC < new MAC address >] [--RARP] [--No-RARP] [--persistent] [--hard-reset] [--hotswap-reset] [--fpga-reset]

This is a helper script to simplify IPMI access to the Imperial MMC in leiu of a full system manager

The following arguments are required:
   -m , --mch                  : The IP address or dns alias of the MCH
   -s , --slot                 : The slot of the card you are accessing

The following arguments are optional:
   -i , --info                 : Retrieve the current network configuration of the card and the sensor data from the SDR
   -I , --IP                   : A new IP address for the card
   -M , --MAC                  : A new MAC address for the card
   -c , --current              : Write 12v & 3v3 current sensor offset values (e.g. 1.4,2.6)
   -R , --RARP                 : Card should use RARP
   -N , --No-RARP              : Card should not use RARP
   -p , --persistent           : Write the new MAC/IP to flash
   --hard-reset                : Power-cycle the card
   --hotswap-reset             : Perform a simulated hotswap removal/reinsert
   --fpga-reset
"""

import getopt, sys, re, subprocess, struct

def run( instruction ):
  print( instruction )
  process = subprocess.Popen( instruction , stdout=subprocess.PIPE , stderr=subprocess.PIPE , shell=True )
  
  std_out , std_err = process.communicate()
  
  if process.returncode:
    if len( std_out ):
      print( "STD OUT: %s" % (std_out) )
    if len( std_err ):
      print( "STD ERR: %s" % (std_err) )
    raise Exception( "Subprocess returned %i" % (process.returncode) )
  
  return std_out , std_err

def ipmi_helper( string_inst ):


    # Parse options
    try:
        opts, args = getopt.getopt(string_inst, "hm:s:iI:M:c:RNp", ["help", "mch=", "slot=", "info", "IP=", "MAC=", "current=","RARP", "No-RARP", "persistent", "hard-reset", "hotswap-reset", "fpga-reset"])
    except getopt.GetoptError, err:
        print __doc__
        sys.exit(2)

    mch = None
    slot = None
    info = False
    IP = None
    MAC = None
    current = None
    RARP= None
    NoRARP= None
    persistent = False
    hardreset = False
    hotswapreset = False
    fpgareset = False

    for opt, value in opts:
      if opt in ("-h", "--help"):
        print( __doc__ )
        sys.exit(0)
      elif opt in ("-m", "--mch"):
        mch = value
      elif opt in ("-s", "--slot"):
        slot = value
      elif opt in ("-i", "--info"):
        info = True
      elif opt in ("-I", "--IP"):
        IP = value
      elif opt in ("-M", "--MAC"):
        MAC = value
      elif opt in ("-c", "--current"):
        current = value
      elif opt in ("-R", "--RARP"):
        RARP = True
      elif opt in ("-N", "--No-RARP"):
        NoRARP = True
      elif opt in ("-p", "--persistent"):
        persistent = True
      elif opt in ("--hard-reset"):
        hardreset = True
      elif opt in ("--hotswap-reset"):
        hotswapreset = True
      elif opt in ("--fpga-reset"):
        fpgareset = True

    if len(args) != 0:
      print( "Incorrect usage! Unknown args: %s" % (", ".join(args)) )
      print(  __doc__ )
      sys.exit(1)

    if not mch or not slot:
      print( "Incorrect usage! --mch and --slot are required" )
      print( __doc__ )
      sys.exit(1)    


    if RARP and NoRARP:
      print( "RARP and No-RARP are mutually exclusive" )
      print( __doc__ )
      sys.exit(1)    


    ip_pattern = re.compile('[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') 
    mac_pattern = re.compile('[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+:[0-9a-f]+') 

    #if not ip_pattern.match( mch ):
    #  print( "Incorrect usage! --mch must provide a valid IP address" )
    #  print( __doc__ )
    #  sys.exit(1)    

    slot = int( slot )
    
    if slot < 1 or slot > 12:
      print( "Incorrect usage! --slot must refer to an a valid slot number (1-12)" )
      print( __doc__ )
      sys.exit(1)            

    slot_addr = hex( 0x70 + (2*slot) )
    sdr_addr = 0x60 + slot

    print( " --- // --- " )
    
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
    if hardreset:
      yes = set(['yes','y'])
      no = set(['no','n'])
      #print( "Are you sure you want to nuke your board? [y/n]" )
      #while True:
      #  choice = raw_input().lower()
      #  if choice in yes:
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0xFF 0xDE 0xAD' % ( mch , slot_addr ))
      print( "Successfully nuked the board" )
      print( " --- // --- " )
      #break;
      #  elif choice in no:
      #    break
      #  else:
      #    sys.stdout.write("Please respond with 'yes' or 'no'")
      
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
    if hotswapreset:
      yes = set(['yes','y'])
      no = set(['no','n'])
      print( "Are you sure you want to perform a hotswap reset of the board? [y/n]" )
      while True:
        choice = raw_input().lower()
        if choice in yes:
          std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0xEE 0xDE 0xAD' % ( mch , slot_addr ))
          print( "Successfully performed hotswap reset" )
          print( " --- // --- " )
          break;
        elif choice in no:
          break
        else:
          sys.stdout.write("Please respond with 'yes' or 'no'")

# ----------------------------------------------------------------------------------------------------------------------------------------------------------
    if fpgareset:
      yes = set(['yes','y'])
      no = set(['no','n'])
      print( "Are you sure you want to reset the FPGA? [y/n]" )
      while True:
        choice = raw_input().lower()
        if choice in yes:
          std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0xDD 0xDE 0xAD' % ( mch , slot_addr ))
          print( "Successfully reset FPGA" )
          print( " --- // --- " )
          break;
        elif choice in no:
          break
        else:
          sys.stdout.write("Please respond with 'yes' or 'no'")
      

      
# ----------------------------------------------------------------------------------------------------------------------------------------------------------

    if IP:
      if not ip_pattern.match( IP ):
        print( "Incorrect usage! --IP must provide a valid IP address" )
        print( __doc__ )
        sys.exit(1)
      
      IP = [ hex(int(s)) for s in re.findall( r'\d+' , IP ) ]
      IP = " ".join( IP )
      
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x03 %s' %( mch , slot_addr , IP ) )
      print( "Successfully set the IP address (not committed to flash)" )
      print( " --- // --- " )

# ----------------------------------------------------------------------------------------------------------------------------------------------------------

    if MAC:
      if not mac_pattern.match( MAC ):
        print( "Incorrect usage! --MAC must provide a valid MAC address" )
        print( __doc__ )
        sys.exit(1)
      
      MAC = [ hex(int(s , 16)) for s in re.findall( r'[0-9a-f]+' , MAC ) ]
      MAC = " ".join( MAC )
      
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x02 %s' % ( mch , slot_addr , MAC ))
      print( "Successfully set the MAC address (not committed to flash)" )
      print( " --- // --- " )

#-----------------------------------------------------------------------------------------------------------------------------------------------------------

    if current:
      print("Setting current offset variables to 12v: %s, 3v3: %s" % (current.split(",")[0], current.split(",")[1] ))
      sens12v = int(10*(float(current.split(",")[0])))
      sens3v3 = int(10*(float(current.split(",")[1])))
      if sens12v < -128 or sens12v > 127 or sens3v3 < -128 or sens3v3 > 127:
        print("Incorrect usage. Current offset outside allowed range (-12.8 to 12,7)")
        print( __doc__ )
        sys.exit(1)
      
      sens12vhex = hex(int("{0:b}".format(sens12v),2)) if sens12v>=0 else hex(int("{0:b}".format(sens12v+256),2))
      sens3v3hex = hex(int("{0:b}".format(sens3v3),2)) if sens3v3>=0 else hex(int("{0:b}".format(sens3v3+256),2))

      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x07 %s %s' % ( mch , slot_addr , sens12vhex, sens3v3hex ))
      print( "Successfully set current offset variables (not committed to flash)" )
      print( " --- // --- " )      
# ----------------------------------------------------------------------------------------------------------------------------------------------------------

    if RARP:
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x04 0x01' % ( mch , slot_addr ))
      print( "Successfully set the board to use RARP (not committed to flash)" )
      print( " --- // --- " )
    elif NoRARP:
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x04 0x00' % ( mch , slot_addr ))
      print( "Successfully set the board to not use RARP (not committed to flash)" )
      print( " --- // --- " )      
# ----------------------------------------------------------------------------------------------------------------------------------------------------------
    
    if persistent:
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x01 0xFE 0xEF' % ( mch , slot_addr ))
      print( "Successfully committed to flash" )
      print( " --- // --- " )
      
# ----------------------------------------------------------------------------------------------------------------------------------------------------------

    if info:
      std_out , std_err = run( 'ipmitool -H %s -P "" -B 0 -T 0x82 -b 7 -t %s raw 0x30 0x05' % ( mch , slot_addr ) )
      return_val = std_out.split()
      
      if len( return_val ) == 13:
        has_sens_offsets = True
      elif len( return_val ) == 11:
        has_sens_offsets = False
      else:
        print( "ERROR Returned value does not conform to expected format" )
        sys.exit(1)  
      
      IP = ".".join( [ str(int(x , 16)) for x in return_val[0:4] ] )
      MAC = ":".join( return_val[4:10] )
      UseRARP =  bool( int(return_val[10], 16) )
      if has_sens_offsets:
        sens12v = float(int(return_val[11],16)-256)/10 if int(return_val[11],16) > 127 else float(int(return_val[11],16))/10
        sens3v3 = float(int(return_val[12],16)-256)/10 if int(return_val[12],16) > 127 else float(int(return_val[12],16))/10

      print( "IP %s" % ( IP ) )
      print( "MAC %s" % ( MAC ) )
      print( "RARP %s" % ( UseRARP ) )
      if has_sens_offsets:
        print( "Current sensor offset values - 12v: %s, 3v3: %s" % ( sens12v, sens3v3 ) )
      print( " --- // --- " )
      
      std_out , std_err = run( 'ipmitool -H %s -A none sdr entity 193.%i' % ( mch , sdr_addr ) )
      for s in std_out.split('\n'):
        if "Disabled" in s:
          print( '%s          [ Not necessarily "Disabled" ]' % s )
        else:
          print( s )
          
      print( " --- // --- " )


if __name__=="__main__":

  ipmi_helper(sys.argv[1:])

