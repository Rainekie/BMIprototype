int ledRPin = 13;
int ledBPin = 12;


void setup()
{
  Serial.begin(115200);
  pinMode(ledRPin, OUTPUT);
  pinMode(ledBPin, OUTPUT);
}

void loop()
{
  if (Serial.available()) {
    int value1 = Serial.read();
    if(value1 == 1){
      digitalWrite(ledRPin, 1);
    }
    else if (value1 == 2){
      digitalWrite(ledBPin, 1);
    }
    else if (value1 == 0){
      digitalWrite(ledRPin, 0);
      digitalWrite(ledBPin, 0);
    }
    
  }
}
