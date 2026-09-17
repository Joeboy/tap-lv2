
# compiler
CC ?= gcc
PICOLV2 ?= 0

# flags
CFLAGS += -ffast-math -fomit-frame-pointer -Wall -Werror -fPIC -DPIC -I../utils
PICOLV2_RUNTIME_OBJ =

ifeq ($(PICOLV2),1)
MCPU = -mcpu=cortex-m33 -mthumb -mfloat-abi=hard -mfpu=fpv5-sp-d16
CC = arm-none-eabi-gcc
CFLAGS += -O2 -fno-finite-math-only $(MCPU) -ffreestanding -fno-builtin \
	-fvisibility=hidden -DPICOLV2 -idirafter /usr/include -std=gnu11
LDFLAGS += -shared $(MCPU) -nostdlib -Wl,-Bsymbolic -Wl,-z,undefs \
	-Wl,-z,max-page-size=0x1000 -Wl,--no-warnings -Wl,-s \
	-Wl,--start-group -lgcc -lc -lm -lnosys -Wl,--end-group
PICOLV2_RUNTIME_OBJ = picolv2-runtime.o
else
CFLAGS += -O3 -funroll-loops -fstrength-reduce
LDFLAGS += -shared -Wl,-O1 -Wl,--as-needed -Wl,--no-undefined -Wl,--strip-all -lm -lrt
ifneq ($(NOOPT),true)
CFLAGS += -mtune=generic -msse -msse2 -mfpmath=sse
endif
endif

# remove command
RM = rm -f

# plugin name
PLUGIN = $(shell basename $(shell pwd) | tr A-Z a-z)
PLUGIN_SO = tap_$(PLUGIN).so

# effect path
EFFECT_PATH = $(PLUGIN).lv2

# installation path
ifndef INSTALL_PATH
INSTALL_PATH = /usr/local/lib/lv2
endif
INSTALLATION_PATH = $(DESTDIR)$(INSTALL_PATH)/tap-$(EFFECT_PATH)

# sources and objects
SRC = $(wildcard *.c)

## rules
all: $(PLUGIN_SO)

$(PLUGIN_SO): $(SRC) $(wildcard *.h) ../utils/tap_utils.h $(PICOLV2_RUNTIME_OBJ)
	$(CC) $(SRC) $(PICOLV2_RUNTIME_OBJ) $(CFLAGS) $(LDFLAGS) -o $(PLUGIN_SO)

picolv2-runtime.o: ../../../lib/picolv2lib.c
	$(CC) $(CFLAGS) -c $< -o $@

clean:
	$(RM) *.so *.o *~

install: all
	mkdir -p $(INSTALLATION_PATH)
	cp -r *.so *.ttl modgui $(INSTALLATION_PATH)
