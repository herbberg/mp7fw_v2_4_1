#!/usr/bin/python
import sys
import subprocess
import time
import array
import os
import argparse
import logging

import mp7
from mp7.tools.log_config import initLogging
from mp7.tools import parameters
from mp7.tools import helpers
import uhal
from ipmi_helper import ipmi_helper



MP7_TESTS = os.environ['MP7_TESTS']
print MP7_TESTS

with open('/etc/ethers', 'r') as fin:
    print fin.read()

def testbuffers(optical):
    print 'Testing buffers...'
    p = subprocess.call(clks.split())
    print 'Please ensure *all* channels are receiving RefClk = 125 MHz, Tx & Rx = 250 MHz and hit enter...'
    cont = raw_input().lower()
    p = subprocess.call(buflp.split())
    p = subprocess.call(cap.split())
    print 'Hardcoded pattern as data source: please measure ser/deser latency (in bx) from ./data/rx_buffer.txt. Hit enter to continue...'
    cont = raw_input().lower()
    if not optical:
        p = subprocess.call(bufap.split())
        p = subprocess.call(cap.split())
        print 'Hardcoded pattern as data source: please measure null algorithm latency (in bx) from ./data/tx_buffer.txt. Hit enter to continue...'
        cont = raw_input().lower()
    p = subprocess.call(buflpl.split())
    p = subprocess.call(cap.split())
    print 'Buffers as data source: please measure ser/deser latency (in bx) from ./data/rx_buffer.txt. Hit enter to continue...'
    cont = raw_input().lower()
    if not optical:
        p = subprocess.call(bufapl.split())
        p = subprocess.call(cap.split())
        print 'Buffer as data source: please measure null algorithm latency from ./data/tx_buffer.txt. Hit enter to continue...'
        cont = raw_input().lower()


def parseOptions():
    '''
    Parse here the command line options
    '''
    import optparse
    usage = '''
%prog name [options]
'''
    defaults = {
 	'mmcFile'	 : 'testbins/mmc_v1_6_3_mp7.elf',
	'cpldFile'	 : 'testbins/mp7_cpld_14031800.jed',
	'fpgaFile'	 : 'testbins/GoldenImage.bin',
    }
    connectionstring =  'file://${MP7_TESTS}/etc/mp7/connections-test.xml'
    parser = optparse.OptionParser( usage )
    parser.add_option('-c','--connections', dest='connections', default=connectionstring, help='Uhal connection file')
    parser.add_option('--mmc', '--mmcFile'   , dest='mmcFile'          , help='MMC binary firmware image (.elf)'     ,default=defaults['mmcFile'] )
    parser.add_option('--cpld', '--cpldFile'   , dest='cpldFile'          , help='CPLD .jed image file', default=defaults['cpldFile']  )
    parser.add_option('--fpga', '--fpgaFile'   , dest='fpgaFile'          , help='FPGA .bit image file', default=defaults['fpgaFile']  )
    parser.add_option('-M', '--macAdd' , dest='macAdd' , help='Mac address to program board with' )
    parser.add_option('-s', '--slot', dest='slot', help='AMC slot number of MP7 to test')
    parser.add_option('--mch', '--mch', dest='mch', help='IP address of MCH')
    parser.add_option('-d','--sddrive', default='/dev/sde', dest='usd',help='Drive for microsd slot, e.g. /dev/sdd')
    opts, args = parser.parse_args()

    if len(args) != 1:
        parser.error('Missing board name')
    opts.board = args[0]

    return opts,args

# logging initialization
import mp7.tools.helpers as hlp
initLogging( logging.DEBUG )

opts, args = parseOptions()

# print('verbose',args.verbose, 'loglevel',args.loglevel)
# logging initialization
initLogging( "ERROR" )

# Ads
hlp.logo()
pldfound = False

yes = set(['yes','y'])
no = set(['no','n'])


#common mp7 butler cmds
rstbot570='mp7butler.py -c %s reset   %s --clkcfg default-int_si570' % (  opts.connections, opts.board )
rstbot5326='mp7butler.py -c %s reset   %s --clkcfg default-int_si5326' % (  opts.connections, opts.board )
rsttop='mp7butler.py -c %s reset   %s --clkcfg default-int_si5326'  % (  opts.connections, opts.board )
rstbotext='mp7butler.py -c %s reset   %s --clkcfg default-ext'  % (  opts.connections, opts.board )
rsttopext='mp7butler.py -c %s reset   %s --clkcfg default-ext'  % (  opts.connections, opts.board )
mgtlp='mp7butler.py -c %s mgts   %s --loopback --no-align'  % (  opts.connections, opts.board )
mgtfp='mp7butler.py -c %s mgts  %s --forcepattern'  % (  opts.connections, opts.board )
clks='mp7butler.py -c %s clocks  %s'  % (  opts.connections, opts.board )
buflp='mp7butler.py -c %s buffers  %s loopPatt'  % (  opts.connections, opts.board )
bufap='mp7butler.py -c %s buffers  %s algoPatt'  % (  opts.connections, opts.board )
buflpl='mp7butler.py -c %s buffers  %s loopPlay --inject=generate:pattern'  % (  opts.connections, opts.board )
bufapl='mp7butler.py -c %s buffers  %s algoPlay --inject=generate:pattern'  % (  opts.connections, opts.board )
cap='mp7butler.py -c %s capture  %s'  % (  opts.connections, opts.board )


'''

#program CPLD and FPGA
print( "\nDo you want to program the CPLD (via JTAG)? [y/n]" )
while True:
    choice = raw_input().lower()
    if choice in yes:
        print "\nProgramming CPLD with file: ", opts.cpldFile, "\n"
        while not pldfound:
            process = subprocess.Popen("impact -batch", shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
            process.stdin.write("setMode -bs\n")
            process.stdin.write("setCable -port auto\n")
            process.stdin.write("identify\n")
            out, err = process.communicate()
            if out.find('xc2c256')==-1:
                raw_input("\nCould not find CPLD in JTAG chain. Please connect CPLD and hit enter...")
            else:
                pldfound=True
                process = subprocess.Popen("impact -batch", shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                process.stdin.write("setMode -bs\n")
                process.stdin.write("setCable -port auto\n")
                process.stdin.write("Identify -inferir\n")
                process.stdin.write("identifyMPM\n")
                cmd = "assignFile -p 1 -file %s\n" % opts.cpldFile
                process.stdin.write(cmd)
                process.stdin.write("Program -p 1 -e -v \n")
                time.sleep(2)
                print '\nFound XC2C256. Programming CPLD (~ few seconds)...\n'
                out, err = process.communicate()
                print out
                if out.find("Programming completed successfully.")==-1:
                    print "Failed to program device. Please check JTAG chain. Exiting..."
                    sys.exit(1)
                print "Finished Programming CPLD"
                break;
    elif choice in no:
        break
    else:
        sys.stdout.write("Please respond with 'yes' or 'no'")


print( "Do you want to program the FPGA via JTAG? [y/n]" )
while True:
        choice = raw_input().lower()
        if choice in yes:
                pldfound = False
                print "\nProgramming FPGA with file: ", opts.fpgaFile, "\n"
                while not pldfound:
                        process = subprocess.Popen("impact -batch", shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                        process.stdin.write("setMode -bs\n")
                        process.stdin.write("setCable -port auto\n")
                        process.stdin.write("identify\n")
                        out, err = process.communicate()
                        #xc7vx690t
                        if out.find('xc7vx485t')==-1:
                                raw_input("\nCould not find FPGA in JTAG chain. Please connect FPGA and hit enter...")
                        else:
                                pldfound=True
                process = subprocess.Popen("impact -batch", shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                process.stdin.write("setMode -bs\n")
                process.stdin.write("setCable -port auto\n")
                process.stdin.write("Identify -inferir\n")
                process.stdin.write("identifyMPM\n")
                cmd = "assignFile -p 1 -file %s\n" % opts.fpgaFile
                process.stdin.write(cmd)
                process.stdin.write("Program -p 1 \n")
                time.sleep(15)
                print '\nFound XC7VX690T. Programming FPGA (~ 1 minute)...\n'
                out, err = process.communicate()
                print out
                if out.find("Programmed successfully.")==-1:
                        print "Failed to program device. Please check JTAG chain. Exiting..."
                        sys.exit(1)
                raw_input("\nFinished programming FPGA. Press enter to continue...")
                break
        elif choice in no:
                break
        else:
                sys.stdout.write("Please respond with 'yes' or 'no'")
'''

print( "Do you want to program the MMC? [y/n]" )
while True:
        choice = raw_input().lower()
        if choice in yes:
            while(True):
                print 'Please ensure that avr32program is in your path, e.g.:'
                print 'export PATH="$PATH:/opt/as4e-ide/plugins/com.atmel.avr.utilities.linux.x86_64_3.0.0.201009140848/os/linux/x86_64/bin"'
                #Erase chip, program MMC with binary file given by options, and run!
                print 'Programming MMC with binary file: %s' % opts.mmcFile
                print 'Note: occasionally the AVR debugger will not connect to the board. If this happens, please just retry.'
                progcmd = 'avr32program program -finternal@0x80000000,64Kb -E -e -v -R -r %s' % opts.mmcFile
                print progcmd.split()
                p = subprocess.call(progcmd.split())
                time.sleep(4)
                print 'Please remove and reinsert the board. Press enter to continue, or "r" to retry...'
                cont = raw_input().lower()
                if cont == 'r':
                    print 'Retrying program mmc...'
                else:
                    break
            break
        elif choice in no:
                break
        else:
                sys.stdout.write("Please respond with 'yes' or 'no'")


print("Do you want to format a microSD card and upload the **GoldenImage.bin**? [y/n]")
while True:
        choice = raw_input().lower()
        if choice in yes:
            while(True):
                #Format SD card, program with GoldenImage.bin
                chmodCmd = 'sudo chmod 777 %s' % opts.usd
                process = subprocess.Popen(chmodCmd,  shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                out, err = process.communicate()
                print out
                formatCmd = './imgtool %s format Firmware' % opts.usd
                process = subprocess.Popen(formatCmd, shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                out, err = process.communicate()
                print out
                print 'Programming uSD with GoldenImage.bin, using image file testbins/test_bottom.bit'
                uploadCmd = './imgtool %s add GoldenImage.bin testbins/test_bottom.bit' % opts.usd
                process = subprocess.Popen(chmodCmd,  shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                process = subprocess.Popen(uploadCmd, shell=True, stderr=None, stdout=subprocess.PIPE, stdin=subprocess.PIPE)
                out, err = process.communicate()
                print out
                print 'Please insert microSD card into the MP7XE, ensure dip switch 4 is down (rest up), and insert the board into the crate. Hit enter to continue, or "r" to retry...'
                cont = raw_input().lower()
                if cont == 'r':
                    print 'Retrying to format and upload GoldenImage.bin to microSD card...'
                else:
                    break
            break
        elif choice in no:
            break
        else:
            sys.stdout.write("Please respond with 'yes' or 'no'")



print( "Do you want to configure the board network settings? [y/n]" )
while True:
        choice = raw_input().lower()
        if choice in yes:
            #Program flash with Mac/IP/RARP enable
            if not opts.macAdd:
                print 'Please enter MAC address (lower case)...'
                opts.macAdd = raw_input().lower()
            if not opts.mch:
                print 'Please enter mch ip address...'
                opts.mch = raw_input().lower()
            if not opts.slot:
                print 'Please enter AMC slot number...'
                opts.slot = raw_input().lower()
            print 'Setting MAC address...'
            setMacCmd = "-m %s -s %i -M %s" % ( opts.mch, int(opts.slot), opts.macAdd )
            ipmi_helper(setMacCmd.split())
            print 'Setting RARP enable...'
            setRarpCmd = "-m %s -s %i -R" % (opts.mch, int(opts.slot))
            ipmi_helper(setRarpCmd.split())
            print 'Committing network settings to flash...'
            setPersistent =  "-m %s -s %i -p" % (opts.mch, int(opts.slot))
            ipmi_helper(setPersistent.split())
            time.sleep(1)
            break
       	elif choice in no:
            break
	else:
            sys.stdout.write("Please respond with 'yes' or 'no'")

print( "Do you want to configure the 12v and 3v3 current sensors? [y/n]" )
while True:
    choice = raw_input().lower()
    if choice in yes:
        while True:
            c12 = c3v3 = -12.8
            if not opts.slot:
                print 'Please enter slot number...'
                opts.slot = raw_input().lower()
            print 'Resetting current sensor calibration..'
            if not opts.mch:
                print 'Please enter mch ip address...'
                opts.mch = raw_input().lower()
            curcalcmd = "-m %s -s %i -c -12.8,-12.8" % (opts.mch, int(opts.slot))
            ipmi_helper(curcalcmd.split())
            time.sleep(0.5)
            setPersistent =  "-m %s -s %i -p" % (opts.mch, int(opts.slot))
            ipmi_helper(setPersistent.split())
            time.sleep(1)
            print "Printing sensor info..."
            printsensorcmd = "-m %s -s %i -i" % (opts.mch, int(opts.slot))
            ipmi_helper(printsensorcmd.split())
            print "Please type in the value for +12 I, e.g. -2.8"
            c12 = raw_input().lower()
            print "Please type in the value for +3.3 I, e.g. 1.2"
            c3v3 =  raw_input().lower()
            print "Calibrating current sensors..."
            curcalcmd = "-m %s -s %i -c %s,%s" % (opts.mch, int(opts.slot), c12,c3v3)
            ipmi_helper(curcalcmd.split())
            time.sleep(0.5)
            setPersistent =  "-m %s -s %i -p" % (opts.mch, int(opts.slot))
            ipmi_helper(setPersistent.split())
            time.sleep(1)
            print "Printing new sensor readings..."
            ipmi_helper(printsensorcmd.split())
            print 'Please check that +12 I is 3.40 Amps and + 3.3 I is 1.60 Amps (within 0.1 Amps), and hit enter to continue, or "r" to retry...'
            cont = raw_input().lower()
            if cont == 'r':
                print 'Retrying current sensor config...'
            else:
                break
        break
    elif choice in no:
        break
    else:
        sys.stdout.write("Please respond with 'yes' or 'no'")


#Run MP7 tests

fin=False
print( "Do you want to run the MP7 tests? [y/n]" )
while True:
	choice = raw_input().lower()
	if choice in yes:

            

            print 'Listing firmware on microSD card...'
            cmd = 'mp7butler.py -c %s scansd  %s'   % (  opts.connections, opts.board )
            p = subprocess.call(cmd.split())
            print 'Do you want to upload test firmware? [y/n]'
            while True:
                fwchoice = raw_input().lower()
                if fwchoice in yes:
                    print 'Uploading test firmware...'
                    #cmd = 'mp7butler.py -c %s uploadfw  %s  testbins/qdrtestxe.bin  qdrtestxe.bin'   % (  opts.connections, opts.board )
                    #p = subprocess.call(cmd.split())
                    #cmd = 'mp7butler.py -c %s uploadfw  %s  testbins/1_4top.bin  1_4top.bin'   % (  opts.connections, opts.board )
                    #p = subprocess.call(cmd.split())
                    cmd = 'mp7butler.py -c %s uploadfw  %s  testbins/test_bottom.bit  test_bottom.bit'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    cmd = 'mp7butler.py -c %s uploadfw  %s  testbins/test_bottom.bit  looptest.bin'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    cmd = 'mp7butler.py -c %s downloadimage  %s  testbins/looptest.bin  looptest.bin'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    cmd = 'mp7butler.py -c %s uploadfw  %s  testbins/looptest.bin  looptestup.bin'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    cmd = 'mp7butler.py -c %s rebootfpga  %s  looptestup.bin'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    print 'FPGA should now have rebooted to image file "looptestup.bin". Hit enter to continue, or "x" to exit...'
                    cont = raw_input().lower()
                    if cont == 'x':
                        sys.exit(1)
                    cmd = 'mp7butler.py -c %s deleteimage  %s  looptest.bin' % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split()) 
                    cmd = 'mp7butler.py -c %s deleteimage  %s  looptestup.bin' % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())  
                    print 'Check firmware images "looptest.bin" and "looptestup.bin" have been deleted. Images on uSD should now be 1_4top, 1_4bot, GoldenImage, and qdrtestxe. Hit enter to continue with QDR tests, or "x" to exit...'
                    cont = raw_input().lower()
                    if cont == 'x':
                        sys.exit(1)
                    break
                elif fwchoice in no:
                    break
                else:
                    sys.stdout.write("Please respond with 'yes' or 'no'")
            print 'Do you want to run QDR Ram tests? [y/n]'
            while True:
                fwchoice = raw_input().lower()
                if fwchoice in yes:
                    print 'Rebooting FPGA to QDR RAM test firmware image...'
                    cmd = 'mp7butler.py -c %s rebootfpga  %s  qdrtestxe.bin'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    print 'Running QDR RAM test...'
                    cmd = 'mp7butler.py -c %s qdr  %s'  % (  opts.connections, opts.board )
                    p = subprocess.call(cmd.split())
                    print 'QDR RAM test complete. Press enter to continue, or "x" to exit...'
                    cont = raw_input().lower()
                    if cont == 'x':
                        sys.exit(1)
                    else:
                        break
                elif fwchoice in no:
                    break
                else:
                    sys.stdout.write("Please respond with 'yes' or 'no'")
            print 'Rebooting FPGA with main test firmware: BOTTOM clock path...'
            cmd = 'mp7butler.py -c %s rebootfpga  %s  test_bottom.bit'  % (  opts.connections, opts.board )
            p = subprocess.call(cmd.split())
            print 'Scanning MiniPOD sensors...'
            cmd = 'mp7butler.py -c %s minipods  %s'  % (  opts.connections, opts.board )
            p = subprocess.call(cmd.split())
            print 'Please check  MiniPOD sensor values are close to nominal. Hit enter to continue with datapath configuration and testing, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)



            print 'Resetting board and configuring clocking with SI570... BOTTOM CLOCKING PATH'
            p = subprocess.call(rstbot570.split())
            print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            print 'Configuring MGTs in loopback...'
            while(True):
                p = subprocess.call(mgtlp.split())
                print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
                cont = raw_input().lower()
                if cont == 'x':
                    sys.exit(1)
                elif cont == 'r':
                    print 'Retrying configure MGTs...'
                else:
                    break
            testbuffers(False)
            ## print 'Resetting board and configuring clocking with SI570...'
##             p = subprocess.call(rstbot570.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             print 'Configuring MGTs for optical loopback. Ensure loopback fibres are connected and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             while(True):
##                 p = subprocess.call(mgtfp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(True)




            print 'Resetting board and configuring clocking with SI5326...'
            p = subprocess.call(rstbot5326.split())
            print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            print 'Configuring MGTs in loopback...'
            while(True):
                p = subprocess.call(mgtlp.split())
                print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
                cont = raw_input().lower()
                if cont == 'x':
                    sys.exit(1)
                elif cont == 'r':
                    print 'Retrying configure MGTs...'
                else:
                    break
            testbuffers(False)
            ## print 'Resetting board and configuring clocking with SI5326...'
##             p = subprocess.call(rstbot5326.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter...'
##             cont = raw_input().lower()
##             print 'Configuring MGTs for optical loopback. Ensure loopback fibres are connected and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             while(True):
##                 p = subprocess.call(mgtfp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(True)


            


            ## print 'Rebooting FPGA with main test firmware: TOP clock path...'
##             cmd = 'mp7butler.py -c %s rebootfpga  %s  1_4top.bin'  % (  opts.connections, opts.board )
##             p = subprocess.call(cmd.split())
##             print 'Resetting board and configuring clocking with SI5326... TOP CLOCKING PATH'
##             p = subprocess.call(rsttop.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             print 'Configuring MGTs in loopback...'
##             while(True):
##                 p = subprocess.call(mgtlp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(False)
##             p = subprocess.call(rsttop.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             print 'Configuring MGTs for optical loopback. Ensure loopback fibres are connected and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             while(True):
##                 p = subprocess.call(mgtfp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(True)


            

            cmd = 'mp7butler.py -c %s rebootfpga  %s  test_bottom.bit'  % (  opts.connections, opts.board )
            p = subprocess.call(cmd.split())
            print 'Resetting board and configuring EXTERNAL clocking. BOTTOM CLOCKING PATH'
            p = subprocess.call(rstbotext.split())
            print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            print 'Configuring MGTs in loopback...'
            while(True):
                p = subprocess.call(mgtlp.split())
                print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
                cont = raw_input().lower()
                if cont == 'x':
                    sys.exit(1)
                elif cont == 'r':
                    print 'Retrying configure MGTs...'
                else:
                    break
            testbuffers(False)
            
            ## p = subprocess.call(rstbotext.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             print 'Configuring MGTs for optical loopback. Ensure loopback fibres are connected and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             while(True):
##                 p = subprocess.call(mgtfp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(True)

            

            print 'Resetting board and configuring EXTERNAL clocking. BOTTOM CLOCKING PATH'
            p = subprocess.call(rstbotext.split())
            print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            print 'Printing TTC block counters. Expect single and double errors to be 0. Hit enter to continue, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            cmd = 'mp7butler.py -c %s checkttc  %s'  % (  opts.connections, opts.board )
            p = subprocess.call(cmd.split())
            print 'Scanning the B-channel/clock phase. Please record phase range. Hit enter to continue, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            cmd = 'mp7butler.py -c %s ttcscan  %s'  % (  opts.connections, opts.board )
            p = subprocess.call(cmd.split())
            print 'Please record phase range. Hit enter to continue, or "x" to exit...'
            cont = raw_input().lower()
            if cont == 'x':
                sys.exit(1)
            

            ## cmd = 'mp7butler.py -c %s rebootfpga  %s  1_4top.bin'  % (  opts.connections, opts.board )
##             p = subprocess.call(cmd.split())
##             print 'Resetting board and configuring EXTERNAL clocking. TOP CLOCKING PATH'
##             p = subprocess.call(rsttopext.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)

            

##             print 'Configuring MGTs in loopback...'
##             while(True):
##                 p = subprocess.call(mgtlp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(False)
##             p = subprocess.call(rsttopext.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter...'
##             cont = raw_input().lower()
##             print 'Configuring MGTs for optical loopback. Ensure loopback fibres are connected and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             while(True):
##                 p = subprocess.call(mgtfp.split())
##                 print 'Ensure there are no alignment errors or CRC errors. If there are errors, retry as usually the errors will disappear after being configured a second time. Hit enter to continue, "r" to retry, or "x" to exit...'
##                 cont = raw_input().lower()
##                 if cont == 'x':
##                     sys.exit(1)
##                 elif cont == 'r':
##                     print 'Retrying configure MGTs...'
##                 else:
##                     break
##             testbuffers(True)


            

##             print 'Resetting board and configuring EXTERNAL clocking. TOP CLOCKING PATH. Hit enter to continue...'
##             cont = raw_input().lower()
##             p = subprocess.call(rsttopext.split())
##             print 'Please ensure Measured f40 = 40 MHz and hit enter, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             print 'Printing TTC block counters. Expect single and double errors to be 0. Hit enter to continue, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             cmd = 'mp7butler.py -c %s checkttc  %s'  % (  opts.connections, opts.board )
##             p = subprocess.call(cmd.split())
##             print 'Scanning the B-channel/clock phase. Please record phase range. Hit enter to continue, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)
##             cmd = 'mp7butler.py -c %s ttcscan  %s'  % (  opts.connections, opts.board )
##             p = subprocess.call(cmd.split())
##             print 'Please record phase range. Hit enter to continue, or "x" to exit...'
##             cont = raw_input().lower()
##             if cont == 'x':
##                 sys.exit(1)



            break
            

       	elif choice in no:
            break
	else:
            sys.stdout.write("Please respond with 'yes' or 'no'")

print("******* End of MP7XE test sequence. Phew! *******")

            

