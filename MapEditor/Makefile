
#MYALIBS= debug.lib
MYALIBS= reqtoolsnb.lib

CC = cc
ASM = as

CFLAGS = -so -sb
#CFLAGS = -bs
AFLAGS = 
LFLAGS = 
#LFLAGS = -g

M      = Work:Aztec5/WW/

# Our application sources
APP1   = MapEditor3d
APP2   = PicIff
APP3   = Support
APP4   = SetUp
APP5   = ProcessMap
APP6   = GLDAccess
APP7   = Objects
APP8   = Effects
APP9   = Textures
APP10  = Sounds
APP11  = Gfx

APP1O  = $(APP1).o $(APP2).o $(APP3).o $(APP4).o $(APP5).o $(APP6).o $(APP7).o $(APP8).o $(APP9).o $(APP10).o $(APP11).o

.SUFFIXES:
.SUFFIXES:	.o .c .h .asm .i

# Make all of the applications
all:	$(APP1) $(APP2) $(APP3) $(APP4) $(APP5) $(APP6) $(APP7) $(APP8) $(APP9) $(APP10) $(APP11)


.c.o:
	cc $(CFLAGS) -hi$(M)System.hi -o $*.o $*.c

.asm.o:
	as -i $(AFLAGS) -o $*.o $*.asm

# Linkage for each application

$(APP1): $(APP1O)
$(APP2): $(APP1O)
$(APP3): $(APP1O)
$(APP4): $(APP1O)
$(APP5): $(APP1O)
$(APP6): $(APP1O)
$(APP7): $(APP1O)
$(APP8): $(APP1O)
$(APP9): $(APP1O)
$(APP10): $(APP1O)
$(APP11): $(APP1O)
	ln +cd -o $(APP1) $(LFLAGS) $(APP1O) -lc +l amiga.lib $(MYALIBS)
