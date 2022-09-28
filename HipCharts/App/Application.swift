//
//  App.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation

let app = Application(dependencies: .init())
let logger = app.dependencies.logger

struct Application {
    let dependencies: Dependencies
}

extension Application {
    struct Dependencies {
        let downloadManager = DownloadManager()
        let defaults = UserDefaults.standard
        let logger = ConsoleLogger()
    }
}

