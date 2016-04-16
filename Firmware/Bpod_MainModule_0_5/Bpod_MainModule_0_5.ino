/*{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

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
// Bpod Finite State Machine v 0.5
// Requires the DueTimer library from:
// https://github.com/ivanseidel/DueTimer
#include <DueTimer.h>
#include <SPI.h>
byte FirmwareBuildVersion = 6;
//////////////////////////////
// Hardware mapping:         /
//////////////////////////////

//     8 Sensor/Valve/LED Ports
byte PortDigitalInputLines[8] = {28, 30, 32, 34, 36, 38, 40, 42};
byte PortPWMOutputLines[8] = {9, 8, 7, 6, 5, 4, 3, 2};
byte PortAnalogInputLines[8] = {0, 1, 2, 3, 4, 5, 6, 7};

//     wire
byte WireDigitalInputLines[4] = {35, 33, 31, 29};
byte WireDigitalOutputLines[4] = {43, 41, 39, 37};

//     SPI device latch pins
byte ValveRegisterLatch = 22;
byte SyncRegisterLatch = 23;

//      Bnc
byte BncOutputLines[2] = {25, 24};
byte BncInputLines[2] = {11, 10};

//      Indicator
byte RedLEDPin = 13;
byte GreenLEDPin = 14;
byte BlueLEDPin = 12;


//////////////////////////////////
// Initialize system state vars: /
//////////////////////////////////

byte PortPWMOutputState[8] = {0}; // State of all 8 output lines (As 8-bit PWM value from 0-255 representing duty cycle. PWM cycles at 1KHZ)
byte PortValveOutputState = 0;   // State of all 8 valves
byte PortInputsEnabled[8] = {0}; // Enabled or disabled input reads of port IR lines
byte WireInputsEnabled[4] = {0}; // Enabled or disabled input reads of wire lines
boolean PortInputLineValue[8] = {0}; // Direct reads of digital values of IR beams
boolean PortInputLineLastKnownStatus[8] = {0}; // Last known status of IR beams
boolean BNCInputLineValue[2] = {0}; // Direct reads of BNC input lines
boolean BNCInputLineLastKnownStatus[2] = {0}; // Last known status of BNC input lines 
boolean WireInputLineValue[4] = {0}; // Direct reads of Wire terminal input lines
boolean WireInputLineLastKnownStatus[4] = {0}; // Last known status of Wire terminal input lines 
boolean MatrixFinished = false; // Has the system exited the matrix (final state)?
boolean MatrixAborted = false; // Has the user aborted the matrix before the final state?
boolean MeaningfulStateTimer = false; // Does this state's timer get us to another state when it expires?
int CurrentState = 1; // What state is the state machine currently in? (State 0 is the final state)
int NewState = 1;
byte OverrideFlag = 0; // If 1, ignores input channels for current cycle
byte CurrentEvent[10] = {0}; // What event code just happened and needs to be handled. Up to 10 can be acquired per 30us loop.
byte nCurrentEvents = 0; // Index of current event
byte SoftEvent = 0; // What soft event code just happened


//////////////////////////////////
// Initialize general use vars:  /
//////////////////////////////////

byte CommandByte = 0;  // Op code to specify handling of an incoming USB serial message
byte VirtualEventTarget = 0; // Op code to specify which virtual event type (Port, BNC, etc)
byte VirtualEventData = 0; // State of target
byte BrokenBytes[4] = {0}; // Outgoing bytes (used in BreakLong function)
int nWaves = 0; // number of scheduled waves registered
byte CurrentWave = 0; // Scheduled wave currently in use
byte LowByte = 0; // LowByte through FourthByte are used for reading bytes that will be combined to 16 and 32 bit integers
byte SecondByte = 0; byte ThirdByte = 0; byte FourthByte = 0;
unsigned long LongInt = 0;
int nStates = 0;
int nTotalEvents = 0;
int nEvents = 0;
int LEDBrightnessAdjustInterval = 5;
byte LEDBrightnessAdjustDirection = 1;
byte LEDBrightness = 0;
byte InputStateMatrix[128][50] = {0}; // Matrix containing all of Bpod's inputs and corresponding state transitions
// Cols: 1-16 = IR beam in...out... 17-20 = BNC1 high...low 21-28 = wire1high...low 29=Tup 30=Unused 31-40=SoftEvents 

byte OutputStateMatrix[128][17] = {0}; // Matrix containing all of Bpod's output actions for each Input state
// Cols: 1=Valves 2=BNC 3=Wire 4=Serial1 Op Code 5=Serial2 Op Code 6=StateIndependentTimerTrig 7=StateIndependentTimerCancel 8-15=PWM values (LED)

byte GlobalTimerMatrix[128][5] = {0}; // Matrix contatining state transitions for global timer elapse events
byte GlobalCounterMatrix[128][5] = {0}; // Matrix contatining state transitions for global timer elapse events
boolean GlobalTimersActive[5] = {0}; // 0 if timer x is inactive, 1 if it's active.
unsigned long GlobalTimerEnd[5] = {0}; // Future Times when active global timers will elapse
unsigned long GlobalTimers[5] = {0}; // Timers independent of states
unsigned long GlobalCounterCounts[5] = {0}; // Event counters 
byte GlobalCounterAttachedEvents[5] = {254}; // Event each event counter is attached to 
unsigned long GlobalCounterThresholds[5] = {0}; // Event counter thresholds (trigger events if crossed)
unsigned long TimeStamps[10000] = {0}; // TimeStamps for events on this trial
int MaxTimestamps = 10000; // Maximum number of timestamps (to check when to start event-dropping)
int CurrentColumn = 0; // Used when re-mapping event codes to columns of global timer and counter matrices
unsigned long StateTimers[128] = {0}; // Timers for each state
unsigned long StartTime = 0; // System Start Time
unsigned long MatrixStartTime = 0; // Trial Start Time
unsigned long MatrixStartTimeMillis = 0; // Used for 32-bit timer wrap-over correction in client
unsigned long StateStartTime = 0; // Session Start Time
unsigned long NextLEDBrightnessAdjustTime = 0;
byte ConnectedToClient = 0;
unsigned long CurrentTime = 0;
unsigned long TimeFromStart = 0;
unsigned long Num2Break = 0; // For conversion from int32 to bytes
unsigned long SessionStartTime = 0;
byte connectionState = 0; // 1 if connected to MATLAB
byte RunningStateMatrix = 0; // 1 if state matrix is running

void setup() {
  for (int x = 0; x < 8; x++) {
     pinMode(PortDigitalInputLines[x], INPUT_PULLUP);
     pinMode(PortPWMOutputLines[x], OUTPUT);
     analogWrite(PortPWMOutputLines[x], 0);
   }
   for (int x = 0; x < 4; x++) {
     pinMode(WireDigitalInputLines[x], INPUT_PULLUP);
     pinMode(WireDigitalOutputLines[x], OUTPUT);
   }
   for (int x = 0; x < 2; x++) {
     pinMode(BncInputLines[x], INPUT);
     pinMode(BncOutputLines[x], OUTPUT);
   }
   pinMode(ValveRegisterLatch, OUTPUT);
   pinMode(SyncRegisterLatch, OUTPUT);
   pinMode(RedLEDPin, OUTPUT);
   pinMode(GreenLEDPin, OUTPUT);
   pinMode(BlueLEDPin, OUTPUT);
   SerialUSB.begin(115200);
   Serial1.begin(115200);
   Serial2.begin(115200);
   SPI.begin();
   SetWireOutputLines(0);
   SetBNCOutputLines(0);
   updateStatusLED(0);
   ValveRegWrite(0);
   Timer3.attachInterrupt(handler);
  Timer3.start(100); // Runs every 100us
}

void loop() {
  
}

void handler() {
  if (connectionState == 0) {
    updateStatusLED(1);
  }
  if (SerialUSB.available() > 0) {
  CommandByte = SerialUSB.read();  // P for Program, R for Run, O for Override, 6 for Device ID
  switch (CommandByte) {
    case '6':  // Initialization handshake
      connectionState = 1;
      updateStatusLED(2);
      SerialUSB.print(5);
      delayMicroseconds(100000);
      SerialUSB.flush();
      SessionStartTime = millis();
      break;
    case 'F':  // Return firmware build number
      SerialUSB.write(FirmwareBuildVersion);
      ConnectedToClient = 1;
      break;
    case 'O':  // Override hardware state
      manualOverrideOutputs();
      OverrideFlag = true;
      break;
    case 'I': // Read and return digital input line states
        while (SerialUSB.available() == 0) {}
        LowByte = SerialUSB.read();
        while (SerialUSB.available() == 0) {}
        SecondByte = SerialUSB.read();
        switch (LowByte) {
          case 'B': // Read BNC input line
            ThirdByte = digitalRead(BncInputLines[SecondByte]);
          break;
          case 'P': // Read port digital input line
            ThirdByte = digitalRead(PortDigitalInputLines[SecondByte]);
          break;
          case 'W': // Read wire digital input line
            ThirdByte = digitalRead(WireDigitalInputLines[SecondByte]);
          break;
        }
        SerialUSB.write(ThirdByte);
        break;
    case 'Z':  // Bpod governing machine has closed the client program
      ConnectedToClient = 0;
      connectionState = 0;
      SerialUSB.write('1');
      updateStatusLED(0);
      break;
    case 'S': // Soft code. Since not in a state matrix, read bytes and ignore data.
        while (SerialUSB.available() == 0) {}
        VirtualEventTarget = SerialUSB.read();
        while (SerialUSB.available() == 0) {}
        VirtualEventData = SerialUSB.read();
      break;
    case 'H': // Recieve byte from USB and send to serial module 1 or 2
        while (SerialUSB.available() == 0) {}
        LowByte = SerialUSB.read();
        while (SerialUSB.available() == 0) {}
        SecondByte = SerialUSB.read();
        switch (LowByte) {
          case 1: // Send to serial port 1
            Serial1.write(SecondByte);
          break;
          case 2: // Send to serial port 2
            Serial2.write(SecondByte);
          break;
        }
     break;
    case 'V': // Manual override: execute virtual event
    while (SerialUSB.available() == 0) {}
    VirtualEventTarget = SerialUSB.read();
    while (SerialUSB.available() == 0) {}
    VirtualEventData = SerialUSB.read();
    if (RunningStateMatrix) {
    OverrideFlag = true;  // Skips this loop iteration's input state refresh to ensure intended effect and avoid negation by a state change
    switch (VirtualEventTarget) {
      case 'P': // Virtual poke PortInputLineLastKnownStatus
        if (PortInputLineLastKnownStatus[VirtualEventData] == LOW) {
          PortInputLineValue[VirtualEventData] = HIGH;
        } else {
          PortInputLineValue[VirtualEventData] = LOW;
        }
        break;
        case 'B': // Virtual BNC input
          if (BNCInputLineLastKnownStatus[VirtualEventData] == LOW) {
            BNCInputLineValue[VirtualEventData] = HIGH;
          } else {
            BNCInputLineValue[VirtualEventData] = LOW;
          }
          break;
        case 'W': // Virtual Wire input
          if (WireInputLineLastKnownStatus[VirtualEventData] == LOW) {
              WireInputLineValue[VirtualEventData] = HIGH;
            } else {
              WireInputLineValue[VirtualEventData] = LOW;
            }
        break;
        case 'S':  // Soft event
              SoftEvent = VirtualEventData;
        break;
      }
    } break;
    case 'P':  // Get new state matrix from client
      while (SerialUSB.available() == 0) {} 
      nStates = SerialUSB.read();
      // Get Input state matrix
      for (int x = 0; x < nStates; x++) {
        for (int y = 0; y < 40; y++) {
          while (SerialUSB.available() == 0) {}
          InputStateMatrix[x][y] = SerialUSB.read();
        }
      }
      // Get Output state matrix
      for (int x = 0; x < nStates; x++) {
        for (int y = 0; y < 17; y++) {
          while (SerialUSB.available() == 0) {}
          OutputStateMatrix[x][y] = SerialUSB.read();
        }
      }
      // Get global timer matrix
      for (int x = 0; x < nStates; x++) {
        for (int y = 0; y < 5; y++) {
          while (SerialUSB.available() == 0) {}
          GlobalTimerMatrix[x][y] = SerialUSB.read();
        }
      }
      // Get global counter matrix
      for (int x = 0; x < nStates; x++) {
        for (int y = 0; y < 5; y++) {
          while (SerialUSB.available() == 0) {}
          GlobalCounterMatrix[x][y] = SerialUSB.read();
        }
      }
      // Get global counter attached events
      for (int x = 0; x < 5; x++) {
          while (SerialUSB.available() == 0) {}
          GlobalCounterAttachedEvents[x] = SerialUSB.read();
      }
      // Get input channel configurtaion
      for (int x = 0; x < 8; x++) {
          while (SerialUSB.available() == 0) {}
          PortInputsEnabled[x] = SerialUSB.read();
      }
      for (int x = 0; x < 4; x++) {
          while (SerialUSB.available() == 0) {}
          WireInputsEnabled[x] = SerialUSB.read();
      }
      
      // Get state timers
      for (int x = 0; x < nStates; x++) {
              StateTimers[x] = ReadLong();
      }
      // Get global timers
      for (int x = 0; x < 5; x++) {
              GlobalTimers[x] = ReadLong();
      }
      // Get global counter event count thresholds
      for (int x = 0; x < 5; x++) {
          GlobalCounterThresholds[x] = ReadLong();
      }
      SerialUSB.write(1);
      break;
      case 'R':  // Run State Matrix
      updateStatusLED(3);
      NewState = 0;
      CurrentState = 0;
      nTotalEvents = 0;
      nEvents = 0;
      MatrixFinished = false;
      // Reset event counters
      for (int x = 0; x < 5; x++) {
        GlobalCounterCounts[x] = 0;
      }
      // Read initial state of sensors      
      for (int x = 0; x < 8; x++) {
        if (PortInputsEnabled[x] == 1) { 
          PortInputLineValue[x] = digitalRead(PortDigitalInputLines[x]); // Read each photogate's current state into an array
          if (PortInputLineValue[x] == HIGH) {PortInputLineLastKnownStatus[x] = HIGH;} else {PortInputLineLastKnownStatus[x] = LOW;} // Update last known state of input line
        } else {
          PortInputLineLastKnownStatus[x] = LOW; PortInputLineValue[x] = LOW;
        } 
      }
      for (int x = 0; x < 2; x++) {
        BNCInputLineValue[x] = digitalRead(BncInputLines[x]);
        if (BNCInputLineValue[x] == HIGH) {BNCInputLineLastKnownStatus[x] = true;} else {BNCInputLineLastKnownStatus[x] = false;}
      }
      for (int x = 0; x < 4; x++) {
        if (WireInputsEnabled[x] == 1) { 
          WireInputLineValue[x] = digitalRead(WireDigitalInputLines[x]);
          if (WireInputLineValue[x] == HIGH) {WireInputLineLastKnownStatus[x] = true;} else {WireInputLineLastKnownStatus[x] = false;}
        }
      }
      // Set meaningful state timer variable (false if state timer is not used, so that a Tup event isn't generated)
      if (InputStateMatrix[CurrentState][38] != CurrentState) {
        MeaningfulStateTimer = true; 
      } else {
        MeaningfulStateTimer = false; 
      }

      // Reset timers
      MatrixStartTime = 0;
      StateStartTime = MatrixStartTime;
      CurrentTime = MatrixStartTime;
      MatrixStartTimeMillis = millis();
      // Adjust outputs, scheduled waves, serial codes and sync port for first state
      setStateOutputs(CurrentState);
      RunningStateMatrix = 1;
      break;
      case 'X':   // Exit state matrix and return data
      MatrixFinished = true;
      RunningStateMatrix = false;
      setStateOutputs(0); // Returns all lines to low by forcing final state
      break;
    } // End switch commandbyte
  } // End SerialUSB.available
  
  if (RunningStateMatrix) {
    OverrideFlag = false;
    nCurrentEvents = 0;
    CurrentEvent[0] = 254; // Event 254 = No event
    SoftEvent = 254;
    CurrentTime++;
         if (OverrideFlag == false) {
           // Refresh state of sensors and inputs
           for (int x = 0; x < 8; x++) {
             if (PortInputsEnabled[x] == 1) { 
              PortInputLineValue[x] = digitalRead(PortDigitalInputLines[x]);
             }
          }
          for (int x = 0; x < 2; x++) {
            BNCInputLineValue[x] = digitalRead(BncInputLines[x]);
          }
          for (int x = 0; x < 4; x++) {
            if (WireInputsEnabled[x] == 1) { 
              WireInputLineValue[x] = digitalRead(WireDigitalInputLines[x]);
            }
          }
         }
         // Determine which port event occurred
         int Ev = 0; // Since port-in and port-out events are indexed sequentially, Ev replaces x in the loop.
         for (int x = 0; x < 8; x++) {
               // Determine port entry events
               if ((PortInputLineValue[x] == HIGH) && (PortInputLineLastKnownStatus[x] == LOW)) {
                  PortInputLineLastKnownStatus[x] = HIGH; CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
               }
               Ev = Ev + 1;
               // Determine port exit events
               if ((PortInputLineValue[x] == LOW) && (PortInputLineLastKnownStatus[x] == HIGH)) {
                  PortInputLineLastKnownStatus[x] = LOW; CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
               }
               Ev = Ev + 1;
         }
         // Determine which BNC event occurred
         for (int x = 0; x < 2; x++) { 
           // Determine BNC low-to-high events
           if ((BNCInputLineValue[x] == HIGH) && (BNCInputLineLastKnownStatus[x] == LOW)) {
              BNCInputLineLastKnownStatus[x] = HIGH; CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
           }
           Ev = Ev + 1;
           // Determine BNC high-to-low events
           if ((BNCInputLineValue[x] == LOW) && (BNCInputLineLastKnownStatus[x] == HIGH)) {
              BNCInputLineLastKnownStatus[x] = LOW; CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
           }
           Ev = Ev + 1;
         }
         // Determine which Wire event occurred
         for (int x = 0; x < 4; x++) { 
           // Determine Wire low-to-high events
             if ((WireInputLineValue[x] == HIGH) && (WireInputLineLastKnownStatus[x] == LOW)) {
                WireInputLineLastKnownStatus[x] = HIGH; CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
             }
             Ev = Ev + 1;
             // Determine Wire high-to-low events
             if ((WireInputLineValue[x] == LOW) && (WireInputLineLastKnownStatus[x] == HIGH)) {
                WireInputLineLastKnownStatus[x] = LOW; CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
             }
             Ev = Ev + 1;
         }
          // Map soft events to event code scheme
          if (SoftEvent < 254) {
            CurrentEvent[nCurrentEvents] = SoftEvent + Ev; nCurrentEvents++;
          }
          Ev = 40;
          // Determine if a global timer expired
          for (int x = 0; x < 5; x++) {
            if (GlobalTimersActive[x] == true) {
              if (CurrentTime >= GlobalTimerEnd[x]) {
                CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
                GlobalTimersActive[x] = false;
              }
            }
            Ev = Ev + 1; 
          }
          // Determine if a global event counter threshold was exceeded
          for (int x = 0; x < 5; x++) {
            if (GlobalCounterAttachedEvents[x] < 254) {
              // Check for and handle threshold crossing
              if (GlobalCounterCounts[x] == GlobalCounterThresholds[x]) {
                CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
              }
              // Add current event to count (Crossing triggered on next cycle)
              if (CurrentEvent[0] == GlobalCounterAttachedEvents[x]) {
                GlobalCounterCounts[x] = GlobalCounterCounts[x] + 1;
              }
            }
            Ev = Ev + 1; 
          }
          Ev = 39;
          // Determine if a state timer expired
          TimeFromStart = CurrentTime - StateStartTime;
          if ((TimeFromStart >= StateTimers[CurrentState]) && (MeaningfulStateTimer == true)) {
            CurrentEvent[nCurrentEvents] = Ev; nCurrentEvents++;
          }
          
          // Now determine if a state transition should occur, based on the first CurrentEvent detected
          if (CurrentEvent[0] < 40) {
            NewState = InputStateMatrix[CurrentState][CurrentEvent[0]];
          } else if (CurrentEvent[0] < 45) {
            CurrentColumn = CurrentEvent[0] - 40;
            NewState = GlobalTimerMatrix[CurrentState][CurrentColumn];
          } else if (CurrentEvent[0] < 50) {
            CurrentColumn = CurrentEvent[0] - 45;
            NewState = GlobalCounterMatrix[CurrentState][CurrentColumn];
          }
          // Store timestamp of events captured in this cycle
          if ((nTotalEvents + nCurrentEvents) < MaxTimestamps) {
            for (int x = 0; x < nCurrentEvents; x++) {
              TimeStamps[nEvents] = CurrentTime;
              nEvents++;
            } 
          }
          // Make state transition if necessary
          if (NewState != CurrentState) {
             if (NewState == nStates) {
                RunningStateMatrix = false;
                MatrixFinished = true;
             } else {
                setStateOutputs(NewState);
                StateStartTime = CurrentTime;
                CurrentState = NewState;
             }
          }
          // Write events captured to USB (if events were captured)
          if (nCurrentEvents > 0) {
            SerialUSB.write(1); // Code for returning events
            SerialUSB.write(nCurrentEvents);
            for (int x = 0; x < nCurrentEvents; x++) {
              SerialUSB.write(CurrentEvent[x]);
            }
          }
  } // End running state matrix
  if (MatrixFinished) {
    MatrixFinished = 0;
    SyncRegWrite(0); // Reset the sync lines
      ValveRegWrite(0); // Reset valves
      for (int x=0;x<8;x++) { // Reset PWM lines
        PortPWMOutputState[x] = 0;
      }
      UpdatePWMOutputStates();
      SetBNCOutputLines(0); // Reset BNC outputs
      SetWireOutputLines(0); // Reset wire outputs
      SerialUSB.write(1); // Op Code for sending events
      SerialUSB.write(1); // Read one event
      SerialUSB.write(255); // Send Matrix-end code
      // Send trial-start timestamp (in milliseconds, basically immune to microsecond 32-bit timer wrap-over)
          Num2Break = MatrixStartTimeMillis-SessionStartTime;
          breakLong(Num2Break);
          SerialUSB.write(BrokenBytes[0]);
          SerialUSB.write(BrokenBytes[1]);
          SerialUSB.write(BrokenBytes[2]);
          SerialUSB.write(BrokenBytes[3]);
      // Send matrix start timestamp (in microseconds)
          breakLong(MatrixStartTime);
          SerialUSB.write(BrokenBytes[0]);
          SerialUSB.write(BrokenBytes[1]);
          SerialUSB.write(BrokenBytes[2]);
          SerialUSB.write(BrokenBytes[3]);
        if (nEvents > 9999) {nEvents = 10000;}
          SerialUSB.write(lowByte(nEvents));
          SerialUSB.write(highByte(nEvents));
        for (int x = 0; x < nEvents; x++) {
          Num2Break = TimeStamps[x];
          breakLong(Num2Break);
          SerialUSB.write(BrokenBytes[0]);
          SerialUSB.write(BrokenBytes[1]);
          SerialUSB.write(BrokenBytes[2]);
          SerialUSB.write(BrokenBytes[3]);
        }
        updateStatusLED(0);
        updateStatusLED(2);
        for (int x=0; x<5; x++) { // Shut down active global timers
          GlobalTimersActive[x] = false;
        }
  } // End Matrix finished
} // End timer handler

unsigned long ReadLong() {
  while (SerialUSB.available() == 0) {}
  LowByte = SerialUSB.read();
  while (SerialUSB.available() == 0) {}
  SecondByte = SerialUSB.read();
  while (SerialUSB.available() == 0) {}
  ThirdByte = SerialUSB.read();
  while (SerialUSB.available() == 0) {}
  FourthByte = SerialUSB.read();
  LongInt =  (unsigned long)(((unsigned long)FourthByte << 24) | ((unsigned long)ThirdByte << 16) | ((unsigned long)SecondByte << 8) | ((unsigned long)LowByte));
  return LongInt;
}

void breakLong(unsigned long LongInt2Break) {
  //BrokenBytes is a global array for the output of long int break operations
  BrokenBytes[3] = (byte)(LongInt2Break >> 24);
  BrokenBytes[2] = (byte)(LongInt2Break >> 16);
  BrokenBytes[1] = (byte)(LongInt2Break >> 8);
  BrokenBytes[0] = (byte)LongInt2Break;
}

void SetBNCOutputLines(int BNCState) {
  switch(BNCState) {
        case 0: {digitalWriteDirect(BncOutputLines[0], LOW); digitalWriteDirect(BncOutputLines[1], LOW);} break;
        case 1: {digitalWriteDirect(BncOutputLines[0], HIGH); digitalWriteDirect(BncOutputLines[1], LOW);} break;
        case 2: {digitalWriteDirect(BncOutputLines[0], LOW); digitalWriteDirect(BncOutputLines[1], HIGH);} break;
        case 3: {digitalWriteDirect(BncOutputLines[0], HIGH); digitalWriteDirect(BncOutputLines[1], HIGH);} break;
  }
}
int ValveRegWrite(int value) {
  // Write to water chip
  SPI.transfer(value);
  digitalWriteDirect(ValveRegisterLatch,HIGH);
  digitalWriteDirect(ValveRegisterLatch,LOW);
}

int SyncRegWrite(int value) {
  // Write to LED driver chip
  SPI.transfer(value);
  digitalWriteDirect(SyncRegisterLatch,HIGH);
  digitalWriteDirect(SyncRegisterLatch,LOW);
}

void UpdatePWMOutputStates() {
  for (int x = 0; x < 8; x++) {
    analogWrite(PortPWMOutputLines[x], PortPWMOutputState[x]);
  }
}
void SetWireOutputLines(int WireState) {
  for (int x = 0; x < 4; x++) {
    digitalWriteDirect(WireDigitalOutputLines[x],bitRead(WireState,x));
  }
}

void updateStatusLED(int Mode) {
  CurrentTime = millis();
  switch (Mode) {
    case 0: {
      analogWrite(RedLEDPin, 0);
      digitalWriteDirect(GreenLEDPin, 0);
      analogWrite(BlueLEDPin, 0);
    } break;
    case 1: { // Waiting for matrix
    if (ConnectedToClient == 0) {
        if (CurrentTime > NextLEDBrightnessAdjustTime) {
          NextLEDBrightnessAdjustTime = CurrentTime + LEDBrightnessAdjustInterval;
          if (LEDBrightnessAdjustDirection == 1) {
            if (LEDBrightness < 255) {
              LEDBrightness = LEDBrightness + 1;
            } else {
              LEDBrightnessAdjustDirection = 0;
            }
          }
          if (LEDBrightnessAdjustDirection == 0) {
            if (LEDBrightness > 0) {
              LEDBrightness = LEDBrightness - 1;
            } else {
              LEDBrightnessAdjustDirection = 2;
            }
          }
          if (LEDBrightnessAdjustDirection == 2) {
            NextLEDBrightnessAdjustTime = CurrentTime + 500;
            LEDBrightnessAdjustDirection = 1;
          }
          analogWrite(BlueLEDPin, LEDBrightness);
        }
      }
    } break;
    case 2: {
      analogWrite(BlueLEDPin, 0);
      digitalWriteDirect(GreenLEDPin, 1);
    } break;
    case 3: {
      analogWrite(BlueLEDPin, 0);
      digitalWriteDirect(GreenLEDPin, 1);
      analogWrite(RedLEDPin, 128);
    } break;
  }
}

void setStateOutputs(byte State) {
    byte CurrentTimer = 0; // Used when referring to the timer currently being triggered
    byte CurrentCounter = 0; // Used when referring to the counter currently being reset
    ValveRegWrite(OutputStateMatrix[State][0]);
    SetBNCOutputLines(OutputStateMatrix[State][1]);
    SetWireOutputLines(OutputStateMatrix[State][2]);
    Serial1.write(OutputStateMatrix[State][3]);
    Serial2.write(OutputStateMatrix[State][4]);
    if (OutputStateMatrix[State][5] > 0) {
      SerialUSB.write(2); // Code for soft-code byte
      SerialUSB.write(OutputStateMatrix[State][5]); // Code for soft-code byte
    }
    for (int x = 0; x < 8; x++) {
      analogWrite(PortPWMOutputLines[x], OutputStateMatrix[State][x+9]);
    }
    // Trigger global timers
    CurrentTimer = OutputStateMatrix[State][6];
    if (CurrentTimer > 0){
      CurrentTimer = CurrentTimer - 1; // Convert to 0 index
      GlobalTimersActive[CurrentTimer] = true; 
      GlobalTimerEnd[CurrentTimer] = CurrentTime+GlobalTimers[CurrentTimer];
    }
    // Cancel global timers
    CurrentTimer = OutputStateMatrix[State][7];
    if (CurrentTimer > 0){
      CurrentTimer = CurrentTimer - 1; // Convert to 0 index
      GlobalTimersActive[CurrentTimer] = false;
    }
    // Reset event counters
    CurrentCounter = OutputStateMatrix[State][8];
    if (CurrentCounter > 0){
      CurrentCounter = CurrentCounter - 1; // Convert to 0 index
      GlobalCounterCounts[CurrentCounter] = 0;
    }
    if (InputStateMatrix[State][39] != State) {MeaningfulStateTimer = true;} else {MeaningfulStateTimer = false;}
    SyncRegWrite((State+1)); // Output binary state code, corrected for zero index
}

void manualOverrideOutputs() {
  byte OutputType = 0;
  while (SerialUSB.available() == 0) {} 
  OutputType = SerialUSB.read();
  switch(OutputType) {
    case 'P':  // Override PWM lines
      for (int x = 0; x < 8; x++) {
        while (SerialUSB.available() == 0) {} 
        PortPWMOutputState[x] = SerialUSB.read();
      }
      UpdatePWMOutputStates(); 
      break;
    case 'V':  // Override valves
      while (SerialUSB.available() == 0) {} 
      LowByte = SerialUSB.read();
      ValveRegWrite(LowByte);
      break;
    case 'B': // Override BNC lines
      while (SerialUSB.available() == 0) {} 
      LowByte = SerialUSB.read();
      SetBNCOutputLines(LowByte);
      break;
    case 'W':  // Override wire terminal output lines
      while (SerialUSB.available() == 0) {} 
      LowByte = SerialUSB.read();
      SetWireOutputLines(LowByte);
      break;
    case 'S': // Override serial module port 1
      while (SerialUSB.available() == 0) {} 
      LowByte = SerialUSB.read();  // Read data to send
      Serial1.write(LowByte);
      break;
    case 'T': // Override serial module port 2
      while (SerialUSB.available() == 0) {} 
      LowByte = SerialUSB.read();  // Read data to send
      Serial2.write(LowByte);
      break;
    }
 }
 
 void digitalWriteDirect(int pin, boolean val){
  if(val) g_APinDescription[pin].pPort -> PIO_SODR = g_APinDescription[pin].ulPin;
  else    g_APinDescription[pin].pPort -> PIO_CODR = g_APinDescription[pin].ulPin;
}
