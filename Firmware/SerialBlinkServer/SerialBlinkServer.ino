byte BlinkIndex = 0;

void setup()
{
  Serial1.begin(115200);
  pinMode(13, OUTPUT); 
}

void loop()
{
  if (Serial1.available()) {
    BlinkIndex = Serial1.read();
    for (int x = 0; x < BlinkIndex; x++) {
      digitalWrite(13, HIGH); delay(100);
      digitalWrite(13, LOW);  delay(100);
    }
  }    
}
