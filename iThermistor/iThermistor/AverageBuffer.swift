//
//  AverageBuffer.swift
//  iThermistor
//
//  Created by Can Tezcan on 02.02.20.
//  Copyright © 2020 Can Tezcan. All rights reserved.
//

import Foundation

struct AverageBuffer {
    
    var capacity: Int
    
    init() {
        capacity = 1000;
        buffer = Array(repeating: 0.0, count:  capacity)
    }
    
    init(with cap: Int) {
        capacity = cap
        buffer = Array(repeating: 0.0, count:  capacity)
    }
    
    mutating func append(newval :Double) {
        buffer[locationIndex] = newval
        locationIndex += 1
        if count != capacity {
            count += 1
        }
        if locationIndex == capacity {
            locationIndex = 0
        }
        average = calculate_avg()
    }
    
    func getAverage() -> Double {
        return average
    }
    
    
    
    private func calculate_avg() -> Double {
        var calc: Double = 0
        for i in 0..<capacity {
            calc += buffer[i]
        }
        return calc / Double(count)
    }
    
    
    private var average: Double = 0
    private var locationIndex: Int = 0
    private var buffer: Array<Double>
    private var count: Int = 0;
}

