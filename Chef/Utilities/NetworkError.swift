//
//  NetworkError.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

import Foundation

// MARK: - Network Error Types
enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case unknown(String)
    case serviceUnavailable
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "無效的網址"
        case .invalidResponse:
            return "伺服器回應無效"
        case .unknown(let message):
            return message
        case .serviceUnavailable:
            return "服務暫時無法使用，請稍後再試"
        }
    }
}
