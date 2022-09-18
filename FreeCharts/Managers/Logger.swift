//
//  Logger.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation

struct ConsoleLogger {
    enum Level: String {
        case info = "Info"
    }
    
    func log(_ message: String) {
        log(.info, message)
    }
    
    func log(_ level: Level = .info, _ message: String) {
        NSLog("Logger: \(level.rawValue): " + message)
    }
}
