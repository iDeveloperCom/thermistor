
#include <Adafruit_BME280.h>
#include <LoRa.h>
#include <Wire.h>

#define DEVICEID "2"

void IRAM_ATTR handleInterrupt();
void IRAM_ATTR onTimer();

//LoRa Parameters
#define SECRET  "cantezcan"
#define BAND    866E6

//BMP 180 definition
#define BMP_SDA 21
#define BMP_SCL 13

Adafruit_BME280 bmp;
TwoWire I2Cone = TwoWire(1);

// Interrupt 
const byte interruptPin = 25;
volatile long windCounter = 0;
volatile int interruptCounter = 0;

hw_timer_t * timer = NULL;
portMUX_TYPE timerMux = portMUX_INITIALIZER_UNLOCKED; 
portMUX_TYPE windMux = portMUX_INITIALIZER_UNLOCKED;

void init_LORA() {
  LoRa.setPins(LORA_DEFAULT_SS_PIN, LORA_DEFAULT_RESET_PIN, LORA_DEFAULT_DIO0_PIN);
  Serial.println("LoRa Sender");
  if (!LoRa.begin(BAND)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }
  Serial.println("LoRa Initial OK!");
}

void initBMP() {
  Serial.println("BMP180 Init");  
  
  I2Cone.begin(BMP_SDA, BMP_SCL, 100000); 
  bool status1 = bmp.begin(0x76, &I2Cone);  
  if (!status1) {
    Serial.println("Could not find a valid BME 280 sensor, check wiring, address, sensor ID!");
    while (1);
  }
  Serial.println("BMP180 initialized!");  
}

void initInterrupt() {
  Serial.println("Interrupt Setup");
  pinMode(33, OUTPUT);
  digitalWrite(33, LOW);
  pinMode(interruptPin, INPUT_PULLUP);
  attachInterrupt(digitalPinToInterrupt(interruptPin), handleInterrupt, FALLING);

  timer = timerBegin(0, 80, true);
  timerAttachInterrupt(timer, &onTimer, true);
  timerAlarmWrite(timer, 500000, true);
  timerAlarmEnable(timer);
}

void setup() {
  Serial.begin(115200);
  init_LORA();
  Wire.begin(BMP_SDA, BMP_SCL); 
  initBMP();
  initInterrupt(); 
}

String readTemp() {
  float temperature = bmp.readTemperature();
  String s = String(temperature);
  Serial.println("Read Temp = " + s);
  return s;
}

void IRAM_ATTR handleInterrupt() {
  portENTER_CRITICAL_ISR(&windMux);
  windCounter++;
  portEXIT_CRITICAL_ISR(&windMux);
}

void IRAM_ATTR onTimer() {
  portENTER_CRITICAL_ISR(&timerMux);
  interruptCounter++;
  portEXIT_CRITICAL_ISR(&timerMux); 
}


void loop() {
  if (interruptCounter > 1) {
    Serial.println("Sending packet");
    portENTER_CRITICAL(&windMux);
    unsigned long wind = windCounter;
    windCounter = 0;
    interruptCounter = 0;
    portEXIT_CRITICAL(&windMux);
    String windString = String(wind);
    String tempString = readTemp();
    String loraString = "|" + windString + "|" + tempString + "|" + DEVICEID;
    LoRa.beginPacket();
    LoRa.print(SECRET);
    LoRa.print(loraString);
    LoRa.print("\0");
    LoRa.endPacket();
    Serial.println("Packet sent " + loraString);
  }  
}
