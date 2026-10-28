# Makefile for the Pololu 3pi+ 32U4 (ATmega32U4 @ 16 MHz) on macOS
#
#   make           build main.hex (compiles every .c file in this folder,
#                  so font.c and OLED.c are picked up automatically)
#   make program   build, wait for you to double-tap RESET, then flash
#   make clean     delete build files
#
# To force a specific port:  make program PORT=/dev/cu.usbmodem14101

MCU     = atmega32u4
F_CPU   = 16000000UL
TARGET  = main

SRC     = $(wildcard *.c)
OBJ     = $(SRC:.c=.o)
HDR     = $(wildcard *.h)

CC      = avr-gcc
OBJCOPY = avr-objcopy
SIZE    = avr-size

CFLAGS  = -mmcu=$(MCU) -DF_CPU=$(F_CPU) -Os -g -Wall -std=gnu11 \
          -ffunction-sections -fdata-sections
LDFLAGS = -mmcu=$(MCU) -Wl,--gc-sections

PORT   ?=

.PHONY: all program clean

all: $(TARGET).hex
	@$(SIZE) $(TARGET).elf

$(TARGET).elf: $(OBJ)
	$(CC) $(LDFLAGS) $^ -o $@

%.o: %.c $(HDR)
	$(CC) $(CFLAGS) -c $< -o $@

$(TARGET).hex: $(TARGET).elf
	$(OBJCOPY) -O ihex -R .eeprom $< $@

# Waits up to 20 s for a NEW /dev/cu.usbmodem* port (the bootloader),
# so other USB serial devices you have plugged in are ignored.
program: $(TARGET).hex
	@port="$(PORT)"; \
	if [ -z "$$port" ]; then \
	  before=" $$(ls /dev/cu.usbmodem* 2>/dev/null | tr '\n' ' ') "; \
	  echo ">>> Double-tap RESET on the robot now (waiting up to 20 s)..."; \
	  i=0; \
	  while [ $$i -lt 200 ] && [ -z "$$port" ]; do \
	    for p in /dev/cu.usbmodem*; do \
	      [ -e "$$p" ] || continue; \
	      case "$$before" in *" $$p "*) ;; *) port="$$p" ;; esac; \
	    done; \
	    [ -z "$$port" ] && sleep 0.1; \
	    i=$$((i+1)); \
	  done; \
	  if [ -z "$$port" ]; then echo ">>> No bootloader port appeared. Try again."; exit 1; fi; \
	  sleep 0.5; \
	fi; \
	echo ">>> Programming via $$port"; \
	avrdude -p $(MCU) -c avr109 -P "$$port" -U flash:w:$(TARGET).hex:i

clean:
	rm -f *.o $(TARGET).elf $(TARGET).hex