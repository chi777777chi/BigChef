//
//  ConfigManager.swift
//  ChefHelper
//

import Foundation

class ConfigManager {
    static let shared = ConfigManager()

    private var config: [String: Any] = [:]

    private init() {
        loadConfiguration()
    }

    private func loadConfiguration() {
        // 嘗試從 Config.plist 讀取配置
        if let path = Bundle.main.path(forResource: "Config", ofType: "plist"),
           let plist = NSDictionary(contentsOfFile: path) as? [String: Any] {
            config = plist
            print("ConfigManager: 已載入配置文件")
        } else {
            // 如果沒有配置文件，使用預設值
            print("ConfigManager: 警告 - 找不到 Config.plist，使用預設配置")
            loadDefaultConfiguration()
        }
    }

    private func loadDefaultConfiguration() {
        config = [
            "API_BASE_URL": "http://localhost:8081",
            "API_VERSION": "v1",
            "DEBUG_MODE": true,
            "TIMEOUT_INTERVAL": 30
        ]
    }

    // MARK: - Public API

    var apiBaseURL: String {
        return config["API_BASE_URL"] as? String ?? "http://localhost:8081"
    }

    var apiVersion: String {
        return config["API_VERSION"] as? String ?? "v1"
    }

    var debugMode: Bool {
        return config["DEBUG_MODE"] as? Bool ?? false
    }

    var timeoutInterval: TimeInterval {
        return TimeInterval(config["TIMEOUT_INTERVAL"] as? Int ?? 30)
    }

    var fullAPIBaseURL: String {
        return "\(apiBaseURL)/api/\(apiVersion)"
    }

    // MARK: - Debug Info

    func printConfiguration() {
        print("📱 ConfigManager 配置:")
        print("  - API Base URL: \(apiBaseURL)")
        print("  - API Version: \(apiVersion)")
        print("  - Debug Mode: \(debugMode)")
        print("  - Timeout: \(timeoutInterval)s")
        print("  - Full API URL: \(fullAPIBaseURL)")
    }
}