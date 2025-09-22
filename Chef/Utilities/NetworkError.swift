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
    case httpError(Int)
    case noData
    case timeout
    case decodingError(String)

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
        case .httpError(let code):
            return "HTTP 錯誤：\(code)"
        case .noData:
            return "沒有收到資料"
        case .timeout:
            return "請求超時，請檢查網路連線"
        case .decodingError(let message):
            return "資料解析錯誤：\(message)"
        }
    }
}
