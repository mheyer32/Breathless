DEBUG ?= 0
BINDIR ?= bin
PROFILE ?= 0

CC = m68k-amigaos-gcc
STRIP=m68k-amigaos-strip
ASM = vasmm68k_mot
VLINK = vlink
LINK = m68k-amigaos-ld

PREFIX = $(shell ./getprefix.sh "$(CC)")
ROOT_DIR:=$(shell dirname $(realpath $(firstword $(MAKEFILE_LIST))))

CFLAGS = -noixemul
CFLAGS += -O3 -fbaserel -m68030 -msmall-code -mregparm=4
CFLAGS += -Werror -Wimplicit -Wstrict-prototypes -Wno-int-conversion -fstrict-aliasing
#CFLAGS += -Wno-int-to-pointer-cast

LFLAGS = -fbaserel -nostartfiles -nostdlib --print-map -Map link.map

AFLAGS = -Fhunk -phxass -sd -sdreg=5 -linedebug
AFLAGS += -I$(PREFIX)/m68k-amigaos/ndk-include
AFLAGS += -I$(PREFIX)/m68k-amigaos/ndk/include

#Always	provide symbols, will be stripped away  for target executable
CFLAGS += -g -ggdb
LFLAGS += -g -ggdb

# Our application sources
OBJS  = TMap.o \
	Presentation.o \
	TMapMain.o \
	Map.o \
	DrawScreen.o \
	c2p8.o\
	3d.o \
	Interrupt.o \
	movement.o \
	sincos.o \
	Text.o \
	Animations.o \
	Objects.o \
	Scores.o \
	devices.o \
	Loader.o \
	FileAccess.o \
	Terminal.o \
	Audio.o \
	SecurityCode1.o \
	Player/Music.o \
	Last.o

# Make all of the applications
all:	Breathless

clean:
	rm -rf *.o

#-L$(PREFIX)/m68k-amigaos/lib/libb -lamiga
Breathless: $(OBJS) Makefile
	#$(LINK) $(LDFLAGS) $(OBJS) -o $@
	$(VLINK) -b amigahunk -sc -Mlinker.map  -o $@ $(OBJS)
	$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm | Makefile
	$(ASM) $(AFLAGS) -m68030 $^

%.o: %.asm060 | Makefile
	$(ASM) $(AFLAGS) -m68060 $^
