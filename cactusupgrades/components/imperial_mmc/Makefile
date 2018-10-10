#--------------------------------------------------------------------------------------------------------------------------------------------
ifeq ($(Board), T5_0)
	BOARDID = -DMINI_T5_REV=0
	BOARD_SRC = $(wildcard src/mini_t5/*.c)
	BOARD_INC = include/imperial_mmc/mini_t5
else ifeq ($(Board), T5_1)
	BOARDID = -DMINI_T5_REV=1
	BOARD_SRC = $(wildcard src/mini_t5/*.c)
	BOARD_INC = include/imperial_mmc/mini_t5
else ifeq ($(Board), T5_2)
	BOARDID = -DMINI_T5_REV=2
	BOARD_SRC = $(wildcard src/mini_t5/*.c)
	BOARD_INC = include/imperial_mmc/mini_t5
else ifeq ($(Board), MP7_0)
	BOARDID = -DMP7_REV=0
	BOARD_SRC = $(wildcard src/mp7/r0/*.c)
	BOARD_INC = include/imperial_mmc/mp7/r0
else ifeq ($(Board), MP7_1)
	BOARDID = -DMP7_REV=1
	BOARD_SRC = $(wildcard src/mp7/r1/*.c)
	BOARD_INC = include/imperial_mmc/mp7/r1
else ifeq ($(Board), MP7_2)
	BOARDID = -DMP7_REV=2
	BOARD_SRC = $(wildcard src/mp7/r2/*.c)
	BOARD_INC = include/imperial_mmc/mp7/r2
else ifeq ($(Board), FC7_0)
	BOARDID = -DFC7_REV=0
	BOARD_SRC = $(wildcard src/fc7/r0/*.c)
	BOARD_INC = include/imperial_mmc/fc7/r0
else ifeq (1,1)
	BOARDID = NOBOARD
endif
#--------------------------------------------------------------------------------------------------------------------------------------------

ATMEL_HEADER_VERSION = 6.1.3.1475
ATMEL_HEADER_SOURCE = externs/atmel-headers-${ATMEL_HEADER_VERSION}.zip
ATMEL_HEADER_TARGET = atmel-headers-${ATMEL_HEADER_VERSION}/avr32/uc3a3256.h

UNAME := $(shell uname -m)

ifeq ($(UNAME), x86_64)
 	SYS = 64
else
 	SYS = 32
endif

AVR_TOOLCHAIN = avr32-gcc

AVR_TOOLCHAIN_VERSION = $(shell ${AVR_TOOLCHAIN} --version )
AVR_TOOLCHAIN_VERSION_CORRECT = $(shell echo "${AVR_TOOLCHAIN_VERSION}" | grep -e "4.3.3" )

#--------------------------------------------------------------------------------------------------------------------------------------------
#The C code
C_SOURCES =	${BOARD_SRC} \
		$(wildcard src/common/*c) \
		$(wildcard atmel/DRIVERS/*.c)

C_OBJECT_FILES = $(patsubst %.c,obj/%.o,${C_SOURCES})


# All "user" files should include imperial_mmc in the #include to be uHAL-like
C_INCLUDE =	-I${BOARD_INC} \
		-Iinclude \
		-Iatmel/UTILS/LIBS/NEWLIB_ADDONS/INCLUDE \
		-Iatmel/UTILS \
		-Iatmel/UTILS/PREPROCESSOR \
		-Iatmel/DRIVERS \
		-Iatmel-headers-${ATMEL_HEADER_VERSION}

C_BUILDFLAGS = -O0 -g3 -Wall -MMD -MP -c -fmessage-length=0 -mpart=uc3a3256 -ffunction-sections -masm-addr-pseudos ${BOARDID}
#--------------------------------------------------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------------------------------------------------
# The Assembler code
ASM_SOURCES =	atmel/ASM/trampoline.x \
		atmel/DRIVERS/exception.x \
		atmel/UTILS/STARTUP_FILES/GCC/crt0.x


ASM_OBJECT_FILES = $(patsubst %.x,obj/%.o,${ASM_SOURCES})

ASM_INCLUDE =	-Iatmel/UTILS \
		-Iatmel/UTILS/PREPROCESSOR \
		-Iatmel-headers-${ATMEL_HEADER_VERSION}

ASM_BUILDFLAGS = -x assembler-with-cpp -c -mpart=uc3a3256 -Wa,-g3
# --------------------------------------------------------------------------------------------------------------------------------------------
	

#--------------------------------------------------------------------------------------------------------------------------------------------	
#The target file
TARGET = bin/ImperialMMC.elf
TARGET_BUILDFLAGS = -nostartfiles -mpart=uc3a3256 -Wl,--gc-sections --rodata-writable -Wl,--direct-data -lm
#--------------------------------------------------------------------------------------------------------------------------------------------

#--------------------------------------------------------------------------------------------------------------------------------------------	
#The target file
TARGET2 = bin/ImperialMMC.bin
#--------------------------------------------------------------------------------------------------------------------------------------------	


#--------------------------------------------------------------------------------------------------------------------------------------------
.PHONY: all _all  clean _cleanall

default: all

clean: _cleanall
_cleanall:
	rm -rf obj
	rm -rf bin
	rm -rf atmel-headers-${ATMEL_HEADER_VERSION}

makedir:
	mkdir -p bin
	mkdir -p obj/src/common
	mkdir -p obj/src/mini_t5
	mkdir -p obj/src/mp7/r0
	mkdir -p obj/src/mp7/r1
	mkdir -p obj/src/mp7/r2
	mkdir -p obj/src/fc7/r0
	mkdir -p obj/atmel/DRIVERS
	mkdir -p obj/atmel/ASM
	mkdir -p obj/atmel/UTILS/STARTUP_FILES/GCC

board_test:
	@if [ ${BOARDID} == "NOBOARD" ]; then \
		echo "INVALID BOARD OR NO BOARD CHOSEN. PLEASE SELECT BOARD BY COMPILING USING 'make Board=T5_{0,1,2}' OR 'make Board=MP7_{0,1,2}'"; \
		exit 1; \
	fi;


checkgcc_version:
	@if [ -z "${AVR_TOOLCHAIN_VERSION}" ]; then \
		echo "AVR Toolchain is not installed. Your system is $(SYS)-bit. Please install *Atmel AVR 32-bit Toolchain 3.4.2 - Linux $(SYS)-bit* from \
		http://www.atmel.com/tools/ATMELAVRTOOLCHAINFORLINUX.aspx"; \
	elif [ -z "${AVR_TOOLCHAIN_VERSION_CORRECT}" ]; then \
		echo "A different version of AVR Toolchain is installed that has not been tested with the MMC code. Code functionality may be compromised. \
		Your system is $(SYS)-bit. If issues arise, please install *AVR 32-bit Toolchain 3.4.2 - Linux $(SYS)-bit* from \
		http://www.atmel.com/tools/ATMELAVRTOOLCHAINFORLINUX.aspx"; \
	else \
		echo "The recommended version of AVR Toolchain is installed."; \
	fi;

echo_clean:
	@echo "MAKE CLEAN BEFORE MAKE IN CASE BOARD HAS BEEN CHANGED..."
	rm -rf obj
	rm -rf bin
	rm -rf atmel-headers-${ATMEL_HEADER_VERSION}


all: _all

_all: 	board_test \
	echo_clean \
	makedir \
	checkgcc_version \
	${TARGET2}

${ATMEL_HEADER_TARGET} : ${ATMEL_HEADER_SOURCE}
	@if [ ! -f ${ATMEL_HEADER_TARGET} ]; then \
		unzip -qq ${ATMEL_HEADER_SOURCE}; \
	fi;

${TARGET}: ${C_OBJECT_FILES} ${ASM_OBJECT_FILES}
	${AVR_TOOLCHAIN} ${C_OBJECT_FILES} ${ASM_OBJECT_FILES} -o $@ ${TARGET_BUILDFLAGS}

${TARGET2}: ${TARGET}
	avr32-objcopy -O binary $< $@

${C_OBJECT_FILES}: obj/%.o : %.c ${ATMEL_HEADER_TARGET}
	${AVR_TOOLCHAIN} $(C_INCLUDE) $(C_BUILDFLAGS) -o $@ $<

-include $(C_OBJECT_FILES:.o=.d)
	
${ASM_OBJECT_FILES}: obj/%.o : %.x ${ATMEL_HEADER_TARGET}
	${AVR_TOOLCHAIN} $(ASM_INCLUDE) $(ASM_BUILDFLAGS) -o $@ $<

-include $(ASM_OBJECT_FILES:.o=.d)	

#--------------------------------------------------------------------------------------------------------------------------------------------
