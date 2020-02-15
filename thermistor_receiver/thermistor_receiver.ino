

#include "SSD1306.h" // alias for `#include "SSD1306Wire.h"`
#include <LoRa.h>

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <BLE2902.h>

// BLE
#define THERMISTOR_SERVICE  "1ee1520a-450e-11ea-b77f-2e728ce88125"
#define TEMP_CHARACTERISTIC "2bbc248c-450e-11ea-b77f-2e728ce88125"
#define WIND_CHARACTERISTIC "2bbc248d-450e-11ea-b77f-2e728ce88125"

BLEServer* pServer = NULL;
BLEService *pService = NULL;
BLECharacteristic *pTempCharacteristic = NULL;
BLECharacteristic *pWindCharacteristic = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

// LoRa
#define SECRET  "cantezcan"
#define BAND    866E6

//OLED pins to ESP32 GPIOs via this connecthin:
#define OLED_SDA 4
#define OLED_SCL 15
#define OLED_RST 16

SSD1306  display(0x3c, OLED_SDA, OLED_SCL);

typedef struct {
   uint8_t value1[2];
   uint8_t value2[2];
} Measurement;

typedef struct {
   String value1;
   String value2;
} Display;

Measurement temperature, wind;
Display tempString, windString;

int counter = 0;

void init_OLED() {
  Serial.println("Start Init OLED");  
  pinMode(OLED_RST, OUTPUT);
  digitalWrite(OLED_RST, LOW);    // set GPIO16 low to reset OLED
  delay(50); 
  digitalWrite(OLED_RST, HIGH); // while OLED is running, must set GPIO16 in high
  
  display.init();
  display.flipScreenVertically();
  display.setColor(WHITE);
  display.setTextAlignment(TEXT_ALIGN_LEFT);
  display.setFont(ArialMT_Plain_16);
  Serial.println("LoRa Init OK!");
}

void init_LORA() {
  Serial.println("Start init LoRa Sender");
  LoRa.setPins(LORA_DEFAULT_SS_PIN, LORA_DEFAULT_RESET_PIN, LORA_DEFAULT_DIO0_PIN);
  if (!LoRa.begin(BAND)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }
  Serial.println("LoRa Initial OK!");
}

class TermistorCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      deviceConnected = false;
    }
};

void init_BLE() {
  Serial.println("Stat Init Bluetooth");
  BLEDevice::init("CT-THERMISTOR");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new TermistorCallbacks());
  pService = pServer->createService(THERMISTOR_SERVICE);
  pTempCharacteristic = pService->createCharacteristic(
                                            TEMP_CHARACTERISTIC,
                                            BLECharacteristic::PROPERTY_READ   |
                                            BLECharacteristic::PROPERTY_WRITE  |
                                            BLECharacteristic::PROPERTY_NOTIFY |
                                            BLECharacteristic::PROPERTY_INDICATE
                                          );
  pWindCharacteristic = pService->createCharacteristic(
                                            WIND_CHARACTERISTIC,
                                            BLECharacteristic::PROPERTY_READ   |
                                            BLECharacteristic::PROPERTY_WRITE  |
                                            BLECharacteristic::PROPERTY_NOTIFY |
                                            BLECharacteristic::PROPERTY_INDICATE
                                          );                    
  pTempCharacteristic->addDescriptor(new BLE2902());
  pWindCharacteristic->addDescriptor(new BLE2902());
  pService->start();
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(THERMISTOR_SERVICE);
  pAdvertising->setScanResponse(true);
  pAdvertising->setMinPreferred(0x06);  // functions that help with iPhone connections issue
  pAdvertising->setMinPreferred(0x12);
  BLEDevice::startAdvertising();
  Serial.println("Bluetooth Initialized");
}

void setup() {
  Serial.begin(115200);
  init_OLED();
  init_LORA();
  init_BLE();
}

void drawText(int x, int y, String s, bool sz = true) {

  if ( sz ) {
    display.setFont(ArialMT_Plain_10);
  } else {
    display.setFont(ArialMT_Plain_16);
  }
  display.drawString(x, y, s);
  display.display();
}

void parsePacket(String packet) {

  Serial.println("packet = " + packet);
  
  int pos1 = packet.indexOf('|');
  String temp = packet.substring(pos1 + 1); 
  
  int pos2 = temp.indexOf('|'); 
  String windDummyStr = temp.substring(0, pos2);
  double windDouble = (windDummyStr.toDouble() * 4) / 60.0;
  String windStr = String(windDouble);

  temp = temp.substring(pos2 + 1);
  pos2 = temp.indexOf('|'); 
  String tempStr = temp.substring(0, pos2);
  int number = (temp.substring(pos2+1)).toInt();
  Serial.println("Number = " + String(number));
  
  float tempr = tempStr.toFloat();
  uint16_t tempValue;
  tempValue = (uint16_t)(tempr *100);
  
  float windval = windStr.toFloat();
  uint16_t windValue;  
  windValue = (uint16_t)(windval *100);

  if (number == 1) {
    Serial.println("1 - Wind " + windStr + " Temp " + tempStr);
    temperature.value1[0] = tempValue;
    temperature.value1[1] = tempValue>>8;    
    wind.value1[0] = windValue;
    wind.value1[1] = windValue>>8;

    tempString.value1 = tempStr;
    windString.value1 = windStr;
  } else 
  if (number == 2) {
    Serial.println("2 - Wind " + windStr + " Temp " + tempStr);
    temperature.value2[0] = tempValue;
    temperature.value2[1] = tempValue>>8;
    wind.value2[0] = windValue;
    wind.value2[1] = windValue>>8;
    tempString.value2 = tempStr;
    windString.value2 = windStr;
  }

  display.clear();
  drawText(10, 05, "W(m/s):");
  drawText(10, 20, "T( °C):");

  drawText(55, 05, windString.value1);
  drawText(55, 20, tempString.value1);
  
  drawText(100, 05, windString.value2);
  drawText(100, 20, tempString.value2);
  display.display();
  

  if (deviceConnected) {

    pTempCharacteristic->setValue((uint8_t*)&temperature, 4);
    pTempCharacteristic->notify();
    pWindCharacteristic->setValue((uint8_t*)&wind, 4);
    pWindCharacteristic->notify();

  }
}

void loop() {

  if (deviceConnected) {
    drawText(10, 45, "BLE Connected", true);
  } else {
    drawText(10, 45, "BLE Not Connected", true);
  }
  // disconnecting
  if (!deviceConnected && oldDeviceConnected) {
    delay(100); // give the bluetooth stack the chance to get things ready
    pServer->startAdvertising(); // restart advertising
    Serial.println("Connection Lost or disconnected! Restarting advertising");
    oldDeviceConnected = deviceConnected;
  }
  // connecting
  if (deviceConnected && !oldDeviceConnected) {
    // do stuff here on connecting
    oldDeviceConnected = deviceConnected;
  }

  int packetSize = LoRa.parsePacket();
  if (packetSize) {
    String s = String(packetSize);
    char *buffer = (char*) malloc (packetSize + 1);
    int count = 0;
    while (LoRa.available()) {
      buffer[count++] = LoRa.read();
    }
    buffer[count] = '\0';
    String packet = String(buffer);
    free(buffer);
    if (packet.startsWith(SECRET)) {
      parsePacket(packet);
    } else {
      Serial.println("Packet is NOT mine");
    }
  }
}
