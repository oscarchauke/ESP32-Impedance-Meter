#include <Arduino.h>

const int ledPin = 2;                           // Change this to the desired pin

const unsigned long halfPeriod = 50; // Calculate half the period in microseconds

void setup()
{
  Serial.begin(115200);
  pinMode(ledPin, OUTPUT);
  Serial.printf("Output Pin: %d\n", ledPin);
  Serial.printf("Delay: %d\n", halfPeriod);
}

void loop()
{
  digitalWrite(ledPin, HIGH);    // Turn the LED on
  delayMicroseconds(halfPeriod); // Wait for half the period
  digitalWrite(ledPin, LOW);     // Turn the LED off
  delayMicroseconds(halfPeriod); // Wait for half the period
}
