UART Terminal test is the "Hello World" of Bpod modules. It is useful to verify connectivity.

This firmware runs on Arduino M0 (uploaded with Arduino.org, not .cc). Connect the M0, via the Bpod Arduino shield and an Ethernet cable, to a "Serial" jack on Bpod.

If you launch a serial terminal in Arduino, type digits (1-9) into the terminal to send the equivalent bytes (0x1 - 0x9) to Bpod. Bytes arriving from Bpod will be displayed in the Arduino serial terminal.