// Note: Upload with Arduino.cc v1.8.1+
byte inByte = 0;
void setup() {
  Serial1.begin(1312500); //1312500 //2625000
  pinMode(13, OUTPUT);
  digitalWrite(13, HIGH);
}

void loop() {
  if (SerialUSB.available()>0) {
    inByte = SerialUSB.read();
    Serial1.write(inByte-48); // Sends ASCII numbers as actual numbers
  }
  if (Serial1.available()) {
   inByte = Serial1.read();
     SerialUSB.write(inByte);
  }
}
