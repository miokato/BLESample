//
//  ViewController.swift
//  BLESample
//
//  Created by mio kato on 2018/09/30.
//  Copyright © 2018年 mio kato. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {

    @IBOutlet weak var receiveLabel: UILabel!
    @IBOutlet weak var transmitValue: UITextField!
    
    // BLE
    var centralManager: CBCentralManager!
    var peripheral: CBPeripheral!
    var service: CBService!
    var characteristic: CBCharacteristic!
    var serviceUUID: CBUUID!
    var characteristicUUID: CBUUID!
    
    @IBAction func read(_ sender: UIButton) {
        let value = peripheral.readValue(for: characteristic)
        print(value)
    }
    
    // WRITE Characteristic
    @IBAction func submit(_ sender: UIButton) {
        
        let data = transmitValue.text?.data(using: String.Encoding.utf8, allowLossyConversion:true)
        peripheral.writeValue(data!, for: characteristic, type: CBCharacteristicWriteType.withResponse)
        print(data!)

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        serviceUUID = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
        characteristicUUID = CBUUID(string: "beb5483e-36e1-4688-b7f5-ea07361b26a8")

    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            print("scan start")
            self.centralManager.scanForPeripherals(withServices: nil, options: nil)
            break
        default:
            break
        }
    }
    
    // ペリフェラルを発見
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if let name = peripheral.name {
            if name == "MyESP32" {
                self.peripheral = peripheral
                centralManager.stopScan()
                central.connect(peripheral, options: nil)
                print("peripheralを発見した")
            }

        }
        // print("発見したBLEデバイス: \(peripheral)")
    }
    
    // 接続
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([serviceUUID])
        print("繋がった")
    }
    
    // サービス発見
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("サービス発見")
        if error != nil {
            print(error.debugDescription)
            return
        }
        self.service = peripheral.services?.first
        peripheral.discoverCharacteristics([characteristicUUID], for: (peripheral.services?.first)!)
    }
    
    // キャラクタリスティック発見
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        self.characteristic = service.characteristics?.first
        peripheral.setNotifyValue(true, for: (service.characteristics?.first)!)
        print("キャラクタリスティック発見")
    }
    
    // 値が更新された
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print(error.debugDescription)
            return
        }
        
        print("値が更新された")
        updateWithData(data: characteristic.value!)

    }
    
    // 更新された時のコールバック
    private func updateWithData(data: Data) {
        let reportData = data.withUnsafeBytes{[UInt8](UnsafeBufferPointer(start: $0, count: data.count))}

        if (reportData.first != nil) {
            print(reportData.last!)
            receiveLabel.text = String(reportData.last!)
        } else {
            print(CFSwapInt16LittleToHost(UInt16(reportData.last!)))
        }
    }


}

