# thermistor
# Free Flight Thermal Detector

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

## Sender Project
This is the part, where the wind and temperature values recorded and transmitted over LoRa to the receiver. There might be 2 sender with numbers 1 and 2. If you modify and build the files by yourself, be sure to have the correct numbers for the 2 sender. 

Also important are the *LoRa* parameters

//LoRa Parameters
#define SECRET  "put here your own secret"
with this secret you can distinguish from other users on the filed, who might have the same system.

#define BAND    866E6 
this defines the 8gg MHz operation for the European terrotory. You can set this according to your needs to other values. Be sure that your system supports the frequency.

## Receiver Project
Receiver is the part, which gets the LoRa data from max 2 sender and process it. Reciever is also a BLE server which is advertising a special service over Bluetooth Low Energy (BLE) with 2 characteristics (Wind and Temperature) with Notify attribute.

The name of the BLE service is CT-THERMISTOR by default. I use this value to distinguish from other BLE devices on searching and bonding. Therefore, it is advised to change it and do not forget to set the correct value also in iOS App. The intelligent algortihm that bonding with the strongest device is not programmed, so if there are other devices on the field and you did not change this value, it is possible to bond other persons device :-)

If you changed the Frequency in the sender, you should also adjust it here. The same is with the secret!

## iOS App
App is written in Swift 5 and for an old iPAd that I have at home 32 bit old iPAd mini. Therefore the iOS version is set to 9.3

If you want to compile the app by yourself, you should change the Bundle Identifier, Mobile Provisioning, all the other things you can use freely. Do not forget to change the BLE server name, if you changed it in the previous steps.


For the housing I made my design, which is optimized for the froggit sensor and the receiver is sitting in a box, which can be found on the thingiverse.com
https://www.thingiverse.com/thing:3237860

The stl files of my part is under the source code. You should process them with e.g. cura software to print it accoording to your needs.



The connection of BME280 is shown in the following picture. Pay attention, the Ports are what I have choosen.

![alt text](https://github.com/iDeveloperCom/thermistor/blob/master/lora.png "TTGO LoRa")



