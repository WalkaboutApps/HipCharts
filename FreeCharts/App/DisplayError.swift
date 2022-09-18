//
//  DisplayError.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation

protocol DisplayableError: Error {
    var displayString: String { get }
}

struct DisplayError: DisplayableError {
    var code: Int
    var debugDescription: String { _debugDescription ?? displayString }
    let displayString: String
    
    private let _debugDescription: String?
    
    init(code: Int = 0, debugDescription: String? = nil, displayString: String) {
        self.code = code
        self._debugDescription = debugDescription
        self.displayString = displayString
    }
    
    init(anyError: Error, defaultDisplayString: String) {
        if let displayError = anyError as? DisplayError {
            code = displayError.code
            _debugDescription = displayError.debugDescription
            displayString = displayError.displayString
        } else if let http = anyError as? HTTPError {
            code = http.statusCode ?? -1000
            _debugDescription = http.responseText
            displayString = defaultDisplayString
        } else {
            let ns = anyError as NSError
            code = ns.code
            _debugDescription = ns.debugDescription
            displayString = defaultDisplayString
        }
    }
}
