# thermistor
Free Flight Thermal Detector

This system is utilizing the TTGO LoRa BLE Esp32 boards. 2 is without the OLED display, 1 with OLED display. From the company froggit using the wind sensor spare part (propeller with reed relay, any other would also work) and 2 pieces BME280 I2C breakout boards.

The 2 sender is setup as follows.

BME280 SDA is at Port 21 on TTGO
BME280 SCL is at Port 13 on TTGO

Wind Sensor two wires are connected to Port 25 (Interrupt PIN for counting the rotation, set to HIGH with PULLUP) and Port 33 as ground pin to PULL the signal to LOW as an interrupt

these are parameters in source code, so you can change them if you know what you are doing.

There are three main parts
- Sender Project
- Receiver Project
- iOS Swift Project

Sender Project
This is the part, where the wind and temperature values recorded and transmitted over LoRa to the receiver. There might be 2 sender with numbers 1 and 2. If you modify and build the files by yourself, be sure to have the correct numbers for the 2 sender. 

Also important are the *LoRa* parameters

//LoRa Parameters
#define SECRET  "put here your own secret"
with this secret you can distinguish from other users on the filed, who might have the same system.

#define BAND    866E6 
this defines the 8gg MHz operation for the European terrotory. You can set this according to your needs to other values. Be sure that your system supports the frequency.


