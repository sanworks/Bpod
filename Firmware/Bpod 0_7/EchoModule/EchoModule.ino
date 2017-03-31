// Note: Upload with Arduino.cc v1.8.1+

// This module is an echo server - any bytes arriving from the Bpod state machine will be sent back to it.
// The only exception is byte 255, which is reserved to request module information.
// Note:
// If the module is also connected to a USB serial terminal (e.g. "Serial Monitor" in the Arduino application), 
// incoming bytes from the terminal are sent to the state machine.
// Incoming bytes from the state machine are echoed back to it, and also sent to the terminal.

#include "ArCOM.h"

// Module setup
unsigned long FirmwareVersion = 1;
char moduleName[] = "EchoModule"; // Name of module for manual override UI and state machine assembler
ArCOM Serial1COM(Serial1); // UART serial port

byte inByte = 0;
void setup() {
  Serial1.begin(1312500);
  pinMode(13, OUTPUT); // Set board LED to illuminate
  digitalWrite(13, HIGH);
}

void loop() {
  if (SerialUSB.available() > 0) { // If a byte arrived from USB
    inByte = SerialUSB.read(); // Read the byte
    Serial1.write(inByte); // Send to state machine
  }
  if (Serial1.available()) { // If a byte arrived from the state machine
     inByte = Serial1.read();
     switch (inByte) { 
      case 255: // Return module name and info
        returnModuleInfo();
      break;
      default:
       Serial1.write(inByte); // Echo byte back to state machine
       SerialUSB.write(inByte); // Send copy to USB serial terminal
      break;
     }
  }
}

void returnModuleInfo() {
  Serial1COM.writeByte(65); // Acknowledge
  Serial1COM.writeUint32(FirmwareVersion); // 4-byte firmware version
  Serial1COM.writeUint32(sizeof(moduleName)-1); // Length of module name
  Serial1COM.writeCharArray(moduleName, sizeof(moduleName)-1); // Module name
}
