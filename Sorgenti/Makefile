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

AFLAGS = -Fhunk -phxass -sd -extsd -sdreg=5 -linedebug -nowarn=62 -quiet
AFLAGS += -I$(PREFIX)/m68k-amigaos/ndk-include
AFLAGS += -I$(PREFIX)/m68k-amigaos/ndk/include
AFLAGS += -DCHEATS
#AFLAGS += -DDEVMODE

AFLAGS060 = $(AFLAGS) -m68060

#Always	provide symbols, will be stripped away  for target executable
CFLAGS += -g -ggdb
LFLAGS += -g -ggdb

# Our application sources
OBJS_COMMON  =	sincos.o \
				Animations.o \
				Presentation.o \
				TMapMain.o \
				Map.o \
				c2p1x1_8_c5_bm_040.o \
				c2p2x1_8_c5_bm.o \
				c2p2x2_8_c5_bm.o \
				Interrupt.o \
				movement.o \
				Text.o \
				Scores.o \
				devices.o \
				Loader.o \
				FileAccess.o \
				Terminal.o \
				Audio.o \
				Player/Music.o \
				Last.o

OBJS_COMMON += c2pnew.o
#OBJS_COMMON += c2p8.o

OBJS_030 = TMap.o \
		   DrawScreen.o \
		   3d.o \
		   Objects.o

OBJS_060 = $(patsubst %.o,%060.o,$(OBJS_030))
OBJS_LC060 = $(patsubst %.o,%lc060.o,$(OBJS_030))

TARGETS=Breathless Breathless060 BreathlessLC060

# Make all of the applications
all: $(TARGETS)

clean:
	rm -rf *.o *.map $(TARGETS)

Breathless: $(OBJS_030) $(OBJS_COMMON) | Makefile
	$(VLINK) -b amigahunk -sc -M$@.map -o $@ $^
	$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

Breathless060: $(OBJS_060) $(OBJS_COMMON) | Makefile
		$(VLINK) -b amigahunk -sc -M$@.map -o $@ $^
		$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

BreathlessLC060: $(OBJS_LC060) $(OBJS_COMMON) | Makefile
		$(VLINK) -b amigahunk -sc -M$@.map -o $@ $^
		$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

ASMDEPS=Makefile TMap.i MulDiv64.i

%.o: %.asm $(ASMDEPS)
	$(ASM) $(AFLAGS) -m68030 $< -o $@

%060.o: %.asm $(ASMDEPS)
	$(ASM) $(AFLAGS060) -DUSEFPU $< -o $@

%lc060.o: %.asm $(ASMDEPS)
	$(ASM) $(AFLAGS060) $< -o $@

