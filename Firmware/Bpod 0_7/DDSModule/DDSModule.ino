#include "ArCOM.h"
#include <SPI.h>
#include "ad983x.h"
ArCOM USBCOM(Serial);
ArCOM StateMachineCOM(Serial1);
ArCOM ModuleCOM(Serial2);
// Pins
const byte DACcs = 14;
const byte DDScs = 15;

unsigned int dacVal = 0;

AD983X_SW myDDS(DDScs, 10);
union {
  byte Bytes[2];
  int16_t Uint16[1];
} dacBuffer;
byte dacBytes[2] = {0};
float frequency = 0;
unsigned long frequencyInt = 0;
unsigned long adcValue = 0;
byte op = 0;
boolean newOp = false;
byte opSource = 0;
byte currentFrequencyRegister = 0;

SPISettings DACSettings(4000000, MSBFIRST, SPI_MODE2); // Settings for DAC

void setup() {
  Serial1.begin(1312500);
  Serial2.begin(1312500);
  SPI.begin();
  SPI.beginTransaction(DACSettings);
  pinMode(DACcs, OUTPUT);
  pinMode(23, INPUT); // Temporary, due to PCB error
  frequency = 2000;
  myDDS.begin();
  myDDS.setFrequency(0, frequency);
  myDDS.setOutputMode(OUTPUT_MODE_SINE); // OUTPUT_MODE_SINE OUTPUT_MODE_TRIANGLE
  dacVal = 0;
  dacWrite(0);
}

void loop() {
  if (USBCOM.available() > 0) {
    op = USBCOM.readByte();
    newOp = true;
    opSource = 0;
  } else if (StateMachineCOM.available() > 0) {
    //op = StateMachineCOM.readByte();
    newOp = true;
    opSource= 1;
  } else if (ModuleCOM.available() > 0) {
    op = ModuleCOM.readByte();
    newOp = true;
    opSource = 2;
  }
  if (newOp) {
    newOp = false;
    switch(op) {
      case 'F':
        switch (opSource) {
          case 0:
            frequencyInt = USBCOM.readUint32();
            frequency = ((double)frequencyInt);
          break;
          case 1:
            frequencyInt = StateMachineCOM.readUint32();
            frequency = ((double)frequencyInt);
          break;
          case 2:
            adcValue = ModuleCOM.readUint32();
            frequency = freqMap(adcValue, 0, 65535, 20, 17000);
          break;
        }
        myDDS.setFrequency(0, frequency);
        myDDS.setFrequency(1, frequency);
//        if (currentFrequencyRegister == 1) {
//          currentFrequencyRegister = 0;
//          myDDS.setFrequency(0, frequency);
//        } else {
//          currentFrequencyRegister = 1;
//          myDDS.setFrequency(1, frequency);
//        }
      break;
      case 'A':
      switch (opSource) {
          case 0:
            dacVal = USBCOM.readUint32();
          break;
          case 1:
            dacVal = StateMachineCOM.readUint32();
          break;
          case 2:
            dacVal = ModuleCOM.readUint32();
          break;
        }
        dacWrite(dacVal);
      break;
    }
  }
}

void dacWrite(unsigned int value) {
  dacBuffer.Uint16[0] = value;
  dacBytes[0] = dacBuffer.Bytes[1];
  dacBytes[1] = dacBuffer.Bytes[0];
  digitalWrite(DACcs, LOW);
  SPI.transfer(dacBytes, 2);
  digitalWrite(DACcs, HIGH);
}

double freqMap(long x, long in_min, long in_max, long out_min, long out_max)
{
  return ((double)x - (double)in_min) * ((double)out_max - (double)out_min) / ((double)in_max - (double)in_min) + (double)out_min;
}
