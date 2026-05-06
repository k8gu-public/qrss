# lightweight qrss keyer for 8-pin TinyAVR
These notes are terse and specific to my setup (Debian Linux and OG serial/RS232 Atmel STK500 programmer/development board)

1. Install avra and avrdude for your Linux distribution.

2. Edit avrQrss128k.asm for your callsign and QRSS mode (FSKCW or DFCW)

3. Assemble AVR code

    avra -I /usr/share/avra avrQrss128k.asm

4. STK500 programmer set up per manual for ATTiny12 high-voltage serial programming

5. Run avrdude to set fuse bits for 128-kHz clock and flash MCU

    avrdude -p t13 -c stk500hvsp -P /dev/ttyS0 -U lfuse:w:0x6B:m -U flash:w:avrpwm.hex:i

