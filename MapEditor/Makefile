DEBUG ?= 0
BINDIR ?= bin
PROFILE  ?= 0

CC = m68k-amigaos-gcc
STRIP=m68k-amigaos-strip
ASM = vasmm68k_mot

CFLAGS = -noixemul
CFLAGS += -O3 -fbaserel -m68030 -msmall-code -mregparm=4
CFLAGS += -Werror -Wimplicit -Wstrict-prototypes -Wno-int-conversion -fstrict-aliasing

#CFLAGS += -Wno-int-to-pointer-cast

LFLAGS = -noixemul -lamiga -lstubs

AFLAGS = -Fhunk -phxass -nosym -ldots -m68030

#Always	provide symbols, will be stripped away  for target executable
CFLAGS += -g -ggdb
LFLAGS += -g -ggdb

# Our application sources
OBJS = \
	PicIff.o \
	Support.o \
	SetUp.o \
	ProcessMap.o \
	GLDAccess.o \
	Objects.o \
	Effects.o \
	Textures.o \
	Sounds.o \
	Gfx.o \
	MapEditor3d.o


# Make all of the applications
all:	MapEditor

clean:
	rm -rf *.o

MapEditor: $(OBJS) Makefile
	$(CC) $(CFLAGS) $(LDFLAGS) $(OBJS) -o $@
	$(STRIP) --strip-debug --strip-unneeded $@ -o $(BINDIR)/$@

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.asm | Makefile
	$(ASM) $(AFLAGS) $^
