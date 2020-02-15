
import Foundation
import UIKit
import CoreBluetooth




class BLECentralViewController : UIViewController, UITableViewDelegate, UITableViewDataSource{

    var tempCharacteristic : CBCharacteristic?
    var windCharacteristic : CBCharacteristic?
    var blePeripheral : CBPeripheral?
    var characteristicASCIIValue = NSString()


    //Data
    var centralManager : CBCentralManager!
    var RSSIs = [NSNumber]()
    var data = NSMutableData()
    var writeData: String = ""
    var peripherals: [CBPeripheral] = []
    var selectedPeripheral: CBPeripheral?
    var characteristicValue = [CBUUID: NSData]()
    var timer = Timer()
    var characteristics = [String : CBCharacteristic]()
    
    //UI
    @IBOutlet weak var baseTableView: UITableView!
    @IBOutlet weak var refreshButton: UIBarButtonItem!
    var refreshControl = UIRefreshControl()

    
    @IBAction func refreshAction(_ sender: AnyObject) {
        self.refreshControl.endRefreshing()
        disconnectFromDevice()
        self.peripherals = []
        self.RSSIs = []
        self.baseTableView.reloadData()
        startScan()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        peripherals.removeAll()
        
        self.baseTableView.delegate = self
        self.baseTableView.dataSource = self
        self.baseTableView.reloadData()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(refreshAction(_:)), for: UIControl.Event.valueChanged)
        self.baseTableView.addSubview(refreshControl) // not required when using UITableViewController

        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disconnectFromDevice()
        self.peripherals = []
        self.RSSIs = []
        self.baseTableView.reloadData()
        startScan()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        print("Stop Scanning")
        centralManager?.stopScan()
    }
    
    func startScan() {
        peripherals.removeAll()
        print("Now Scanning...")
        self.timer.invalidate()
        centralManager?.scanForPeripherals(withServices: [] , options: [CBCentralManagerScanOptionAllowDuplicatesKey:false])
        Timer.scheduledTimer(timeInterval: 17, target: self, selector: #selector(self.cancelScan), userInfo: nil, repeats: false)
    }
    
    /*We also need to stop scanning at some point so we'll also create a function that calls "stopScan"*/
    @objc func cancelScan() {
        self.centralManager?.stopScan()
        print("Scan Stopped")
        print("Number of Peripherals Found: \(peripherals.count)")
    }
    
    func disconnectFromDevice () {
        if let bleph = blePeripheral {
            centralManager?.cancelPeripheralConnection(bleph)
        }
    }
    
    func connectToDevice () {
        centralManager?.connect(blePeripheral!, options: nil)
    }
    
    func disconnectAllConnection() {
        centralManager.cancelPeripheralConnection(blePeripheral!)
    }
    
    
    //Table View Functions
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.peripherals.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let peripheral = self.peripherals[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlueCell") as! PeripheralTableViewCell
        let RSSI = self.RSSIs[indexPath.row]
        cell.peripheralLabel.text = peripheral.name
        cell.rssiLabel.text = "RSSI: \(RSSI)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        blePeripheral = peripherals[indexPath.row]
        connectToDevice()
    }
}

extension BLECentralViewController : CBCentralManagerDelegate {
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            if name.starts(with: "CT") || name.starts(with: "ESP32") {
                print("Discovered \(String(describing: peripheral.name))")
                DispatchQueue.main.async { [weak self] in
                    if !(self?.peripherals.contains(peripheral))! {
                        self?.peripherals.append(peripheral)
                        self?.RSSIs.append(RSSI)
                        self?.baseTableView.reloadData()
                    }
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        centralManager?.stopScan()
        data.length = 0
        self.selectedPeripheral = peripheral
        peripheral.delegate = self
        peripheral.discoverServices([BLEService_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected")
        NotificationCenter.default.post(name: NSNotification.Name("DISCONNECTED"), object: nil)
        self.startScan()
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if error != nil {
            print("Failed to connect to peripheral")
            return
        }
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // We will just handle it the easy way here: if Bluetooth is on, proceed...start scan!
            print("Bluetooth Enabled")
            startScan()
            
        } else {
//            print("Bluetooth Disabled- Make sure your Bluetooth is turned on")
//
//            let alertVC = UIAlertController(title: "Bluetooth is not enabled", message: "Make sure that your bluetooth is turned on", preferredStyle: UIAlertController.Style.alert)
//            let action = UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: { (action: UIAlertAction) -> Void in
//                self.dismiss(animated: true, completion: nil)
//            })
//            alertVC.addAction(action)
//            self.present(alertVC, animated: true, completion: nil)
        }
    }
}

extension BLECentralViewController: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
        print("Discovered Services: \(services)")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if ((error) != nil) {
            print("Error discovering services: \(error!.localizedDescription)")
            return
        }
        guard let characteristics = service.characteristics else {
            return
        }
        print("Found \(characteristics.count) characteristics!")
        for characteristic in characteristics {
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Wind)  {
                windCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: windCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Wind Characteristic: \(characteristic.uuid)")
            }
            if characteristic.uuid.isEqual(BLE_Characteristic_uuid_Temp){
                tempCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: tempCharacteristic!)
                peripheral.readValue(for: characteristic)
                print("Temp Characteristic: \(characteristic.uuid)")
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
        self.performSegue(withIdentifier: "UartViewControllerSegue", sender: nil)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == windCharacteristic {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: "WIND"), object: characteristic.value)
        }
        if characteristic == tempCharacteristic {
            NotificationCenter.default.post(name:NSNotification.Name(rawValue: "TEMP"), object: characteristic.value)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("\(error.debugDescription)")
            return
        }
        if ((characteristic.descriptors) != nil) {
            
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Error changing notification state:\(String(describing: error?.localizedDescription))")
            
        } else {
            print("Characteristic's value subscribed")
        }
        
        if (characteristic.isNotifying) {
            print ("Subscribed. Notification has begun for: \(characteristic.uuid)")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Message sent")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        guard error == nil else {
            print("Error discovering services: error")
            return
        }
        print("Succeeded!")
    }

}
