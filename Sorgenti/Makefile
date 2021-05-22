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

AFLAGS = -Fhunk -phxass -sd -extsd -sdreg=5 -linedebug
AFLAGS += -I$(PREFIX)/m68k-amigaos/ndk-include
AFLAGS += -I$(PREFIX)/m68k-amigaos/ndk/include

#Always	provide symbols, will be stripped away  for target executable
CFLAGS += -g -ggdb
LFLAGS += -g -ggdb

# Our application sources
OBJS_COMMON  =	sincos.o \
				Animations.o \
				Presentation.o \
				TMapMain.o \
				Map.o \
				c2p8.o\
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

OBJS_030 = TMap.o \
		   DrawScreen.o \
		   3d.o \
		   Objects.o

OBJS_060 = TMap060.o \
		   DrawScreen060.o \
		   3d060.o \
		   Objects060.o


# Make all of the applications
all:	Breathless Breathless060

clean:
	rm -rf $(OBJS_COMMON) $(OBJS_030) $(OBJS_060) Breathless Breathless060

Breathless: $(OBJS_030) $(OBJS_COMMON) | Makefile
	$(VLINK) -b amigahunk -sc -Mlinker.map  -o $@ $^
	$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

Breathless060: $(OBJS_060) $(OBJS_COMMON) | Makefile
		$(VLINK) -b amigahunk -sc -Mlinker.map  -o $@ $^
		$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm | Makefile
	$(ASM) $(AFLAGS) -m68030 $^ -o $@

%060.o: %.asm060 | Makefile
	$(ASM) $(AFLAGS) -m68060 $^ -o $@
