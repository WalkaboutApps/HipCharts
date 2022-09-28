//
//  URLResponse+Error.swift
//  FreeCharts
//
//  Created by Fish Sticks on 9/17/22.
//

import Foundation

enum HTTPError: Error {
    case statusCode(Int, Data?)
}

extension HTTPError {
    var statusCode: Int? {
        switch self {
        case .statusCode(let code, _):
            return code
        }
    }
    var responseText: String? {
        switch self {
        case .statusCode(_, let data):
            if let data = data, let responseText = String(data: data, encoding: .utf8) {
                return String(responseText.prefix(1000))
            }
            return nil
        }
    }
}

extension URLResponse {
    func httpError(data: Data?) -> HTTPError? {
        if let res = self as? HTTPURLResponse {
            if !(200 ... 299).contains(res.statusCode) {
                return HTTPError.statusCode(res.statusCode, data)
            }
        }
        return nil
    }
}
