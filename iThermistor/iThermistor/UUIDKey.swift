//
//  UUIDKey.swift
//  Basic Chat
//
//  Created by Trevor Beaton on 12/3/16.
//  Copyright © 2016 Vanguard Logic LLC. All rights reserved.
//

import CoreBluetooth
//Uart Service uuid

let kBLEService_UUID = "1ee1520a-450e-11ea-b77f-2e728ce88125"
let kBLE_Characteristic_uuid_Temp = "2bbc248c-450e-11ea-b77f-2e728ce88125"
let kBLE_Characteristic_uuid_Wind = "2bbc248d-450e-11ea-b77f-2e728ce88125"

let MaxCharacters = 20

let BLEService_UUID = CBUUID(string: kBLEService_UUID)
let BLE_Characteristic_uuid_Temp = CBUUID(string: kBLE_Characteristic_uuid_Temp)
let BLE_Characteristic_uuid_Wind = CBUUID(string: kBLE_Characteristic_uuid_Wind)
