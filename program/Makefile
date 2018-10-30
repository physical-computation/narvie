TREEROOT	= ../cross-compiler-build
include $(TREEROOT)/conf/setup.conf

PROGRAM		= led
INIT			= init

OPTFLAGS	= -g -O0
CFLAGS		= $(TARGET-ARCH-FLAGS) -Wall 
LDFLAGS		= -Ttext $(LOADADDR)
LOADADDR	= 0x00


OBJS	=\
	$(PROGRAM).o\


all:	$(PROGRAM) $(PROGRAM).sr Makefile

$(INIT).o: $(INIT).s
	$(CC) -O0 -c -o $(INIT).o $(INIT).s

$(PROGRAM): $(OBJS) $(INIT).o
	$(LD) $(LDFLAGS) $(INIT).o $(OBJS) -o $@

$(PROGRAM).sr:$(PROGRAM)
	$(OBJCOPY) -O srec $(PROGRAM) $@

$(PROGRAM).o: $(PROGRAM).c Makefile
	$(CC) $(CFLAGS) $(OPTFLAGS) -c $(PROGRAM).c


clean:
	$(RM) init.i *.o $(PROGRAM) $(PROGRAM).sr $(PROGRAM).map
