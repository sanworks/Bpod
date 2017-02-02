/*
  ----------------------------------------------------------------------------

  This file is part of the Sanworks Bpod repository
  Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA

  ----------------------------------------------------------------------------

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, version 3.

  This program is distributed  WITHOUT ANY WARRANTY and without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/
#include "ArCOM.h" // ArCOM is a serial interface wrapper developed by Sanworks, to streamline transmission of datatypes and arrays over serial
#define SERIAL_TX_BUFFER_SIZE 256
#define SERIAL_RX_BUFFER_SIZE 256
ArCOM myUSB(SerialUSB); // Creates an ArCOM object called myUSB, wrapping SerialUSB
ArCOM myUART(Serial1); // Creates an ArCOM object called myUART, wrapping Serial1
uint32_t FirmwareVersion = 1;
char moduleName[] = "ValveModule"; // Name of module for manual override UI and state machine assembler
byte opCode = 0; 
byte channel = 0; 
const byte enablePin = 4;
const byte inputChannels[8] = {5, 6, 8, 9, 13, 12, 11, 10}; // Arduino pins
const byte outputChannels[8] = {3, 2, 1, 0, 7, 6, 5, 4}; // Valve channels 0-7, for each arduino pin in inputChannels
byte valveState[8] = {0};
void setup() {
  // put your setup code here, to run once:
  Serial1.begin(1312500); //1312500 //2625000
  pinMode(enablePin, OUTPUT);
  digitalWrite(enablePin, HIGH);
  for (int i = 0; i < 8; i++) {
    pinMode(inputChannels[i], OUTPUT);
    digitalWrite(inputChannels[i], 0);
  }
}

void loop() {
  if (myUSB.available()>0) {
    opCode = myUSB.readByte();
    channel = opCode - 65;
    valveState[channel] = 1 - valveState[channel];
    digitalWrite(inputChannels[outputChannels[channel]], valveState[channel]);
  }
  if (myUART.available()) {
   opCode = myUART.readByte();
   switch(opCode) {
    case 255:
      returnModuleInfo();
    break;
    default:
      channel = opCode - 65;
      valveState[channel] = 1 - valveState[channel];
      digitalWrite(inputChannels[outputChannels[channel]], valveState[channel]);
    break;
   }
  }
}

void returnModuleInfo() {
  myUART.writeByte(65); // Acknowledge
  myUART.writeUint32(FirmwareVersion); // 4-byte firmware version
  myUART.writeUint32(sizeof(moduleName)-1); // Length of module name
  myUART.writeCharArray(moduleName, sizeof(moduleName)-1); // Module name
}

