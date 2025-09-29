//
//  NetworkSwevice.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

import Foundation
import Combine

protocol NetworkServiceProtocol {
    func request<T: Decodable>(url: String, decodeType: T.Type) -> Future<T, Error>
    func fetchRecipes(page: Int, size: Int) -> Future<RecipesAPIResponse, Error>
    func fetchRecipeDetail(by name: String) -> Future<RecipeDetailAPIResponse, Error>
    func login(email: String, password: String) -> Future<LoginResponse, Error>
    func fetchFavorites(page: Int, size: Int) -> Future<RecipesAPIResponse, Error>
}

final class NetworkService: NetworkServiceProtocol {

    private var cancellables = Set<AnyCancellable>()
    private let baseURL = "http://192.168.1.125:8081"

    // MARK: - Helper Methods
    private var authorizationToken: String? {
        return UserDefaults.standard.string(forKey: "accessToken")
    }

    private func createAuthenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let token = authorizationToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    func request<T: Decodable>(url: String, decodeType: T.Type) -> Future<T, Error> {
        return Future<T, Error> { [weak self] promise in
            guard let self = self,
                  let url = URL(string: url) else {
                return promise(.failure(NetworkError.invalidURL))
            }
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = 60.0 // 60 seconds
            let session = URLSession(configuration: configuration)
            session.dataTaskPublisher(for: url)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse else { 
                        throw NetworkError.invalidResponse 
                    }
                    
                    switch httpResponse.statusCode {
                    case 200:
                        return data
                    case 404:
                        throw NetworkError.unknown("找不到請求的資源")
                    case 410:
                        throw NetworkError.unknown("服務不可用")
                    case 500...599:
                        throw NetworkError.unknown("伺服器內部錯誤")
                    default:
                        throw NetworkError.unknown("HTTP \(httpResponse.statusCode)")
                    }
                }
                .decode(type: decodeType.self, decoder: JSONDecoder())
                .receive(on: RunLoop.main)
                .sink { completion in
                    if case let .failure(error) = completion {
                        switch error {
                        case let decodingError as DecodingError:
                            promise(.failure(NetworkError.unknown("解碼錯誤：\(decodingError.localizedDescription)")))
                        case let apiError as NetworkError:
                            promise(.failure(apiError))
                        default:
                            promise(.failure(NetworkError.unknown(error.localizedDescription)))
                        }
                    }
                } receiveValue: { promise(.success($0)) }
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Recipe API Methods
    func fetchRecipes(page: Int = 1, size: Int = 20) -> Future<RecipesAPIResponse, Error> {
        return Future<RecipesAPIResponse, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown("Service unavailable")))
            }

            let urlString = "\(self.baseURL)/api/v1/recipes?page=\(page)&size=\(size)"

            print("NetworkService: 🌐 準備發送 API 請求")
            print("NetworkService: 📡 URL: \(urlString)")

            guard let url = URL(string: urlString) else {
                print("NetworkService: ❌ 無效的 URL: \(urlString)")
                return promise(.failure(NetworkError.invalidURL))
            }

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = 60.0
            let session = URLSession(configuration: configuration)

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "Accept")

            session.dataTaskPublisher(for: request)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }

                    print("NetworkService: 📊 收到 HTTP 回應")
                    print("NetworkService: 🔢 狀態碼: \(httpResponse.statusCode)")
                    print("NetworkService: 📦 資料大小: \(data.count) bytes")

                    // 🔍 新增：列印原始 JSON 回應
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("NetworkService: 🔍 API 原始回應 JSON:")
                        print("--- JSON 開始 ---")
                        print(jsonString)
                        print("--- JSON 結束 ---")
                    } else {
                        print("NetworkService: ❌ 無法轉換回應為 UTF-8 字串")
                    }

                    switch httpResponse.statusCode {
                    case 200:
                        return data
                    case 404:
                        throw NetworkError.unknown("找不到菜品資料")
                    case 500...599:
                        throw NetworkError.unknown("伺服器內部錯誤")
                    default:
                        throw NetworkError.httpError(httpResponse.statusCode)
                    }
                }
                .tryMap { data in
                    // 🔍 嘗試解析 JSON，提供詳細錯誤資訊
                    do {
                        let decoder = JSONDecoder()
                        print("NetworkService: 🔄 開始解析 JSON...")
                        let result = try decoder.decode(RecipesAPIResponse.self, from: data)
                        print("NetworkService: ✅ JSON 解析成功")
                        return result
                    } catch let decodingError as DecodingError {
                        print("NetworkService: ❌ JSON 解析錯誤詳情:")
                        print("錯誤: \(decodingError)")

                        switch decodingError {
                        case .valueNotFound(let type, let context):
                            print("❌ 缺少值:")
                            print("  - 期待類型: \(type)")
                            print("  - 路徑: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                            print("  - 描述: \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("❌ 類型不匹配:")
                            print("  - 期待類型: \(type)")
                            print("  - 路徑: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                            print("  - 描述: \(context.debugDescription)")
                        case .keyNotFound(let key, let context):
                            print("❌ 缺少鍵值:")
                            print("  - 鍵: \(key.stringValue)")
                            print("  - 路徑: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                            print("  - 描述: \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("❌ 資料損壞:")
                            print("  - 路徑: \(context.codingPath.map { $0.stringValue }.joined(separator: " -> "))")
                            print("  - 描述: \(context.debugDescription)")
                        @unknown default:
                            print("❌ 未知解析錯誤: \(decodingError)")
                        }

                        throw NetworkError.unknown("JSON 解析失敗：\(decodingError.localizedDescription)")
                    } catch {
                        print("NetworkService: ❌ 其他解析錯誤: \(error)")
                        throw NetworkError.unknown("資料處理失敗：\(error.localizedDescription)")
                    }
                }
                .receive(on: RunLoop.main)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print("NetworkService: ❌ 最終錯誤: \(error)")
                        promise(.failure(error))
                    }
                } receiveValue: { response in
                    print("NetworkService: ✅ API 請求成功")
                    print("NetworkService: 📦 收到 \(response.data.list.count) 個食譜")
                    print("NetworkService: 📋 資料概要:")
                    print("  - API 狀態碼: \(response.code)")
                    print("  - 訊息: \(response.message)")
                    print("  - 總記錄數: \(response.data.total)")
                    promise(.success(response))
                }
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Recipe Detail API
    func fetchRecipeDetail(by name: String) -> Future<RecipeDetailAPIResponse, Error> {
        return Future<RecipeDetailAPIResponse, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown("Service unavailable")))
            }

            // URL編碼食物名稱以處理中文字符
            guard let encodedName = name.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
                return promise(.failure(NetworkError.invalidURL))
            }

            let urlString = "\(self.baseURL)/api/v1/recipes/\(encodedName)"

            print("NetworkService: 🌐 準備發送食譜詳細資料 API 請求")
            print("NetworkService: 📡 URL: \(urlString)")

            guard let url = URL(string: urlString) else {
                print("NetworkService: ❌ 無效的 URL: \(urlString)")
                return promise(.failure(NetworkError.invalidURL))
            }

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = 60.0
            let session = URLSession(configuration: configuration)

            session.dataTaskPublisher(for: url)
                .tryMap { output in
                    print("NetworkService: 📊 收到食譜詳細資料 HTTP 回應")
                    print("NetworkService: 🔢 狀態碼: \((output.response as? HTTPURLResponse)?.statusCode ?? 0)")
                    print("NetworkService: 📦 資料大小: \(output.data.count) bytes")

                    // 打印原始JSON以供調試
                    if let jsonString = String(data: output.data, encoding: .utf8) {
                        print("NetworkService: 🔍 食譜詳細資料 API 原始回應 JSON:")
                        print("--- JSON 開始 ---")
                        print(jsonString)
                        print("--- JSON 結束 ---")
                    }

                    if let httpResponse = output.response as? HTTPURLResponse {
                        guard httpResponse.statusCode == 200 else {
                            print("NetworkService: ❌ HTTP 錯誤，狀態碼: \(httpResponse.statusCode)")
                            throw NetworkError.httpError(httpResponse.statusCode)
                        }
                    }
                    return output.data
                }
                .decode(type: RecipeDetailAPIResponse.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print("NetworkService: ❌ 食譜詳細資料請求失敗: \(error)")
                        promise(.failure(error))
                    }
                } receiveValue: { response in
                    print("NetworkService: ✅ 食譜詳細資料請求成功")
                    print("NetworkService: 📋 食譜名稱: \(response.data.displayName)")
                    promise(.success(response))
                }
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Authentication API
    func login(email: String, password: String) -> Future<LoginResponse, Error> {
        return Future<LoginResponse, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown("Service unavailable")))
            }

            let urlString = "\(self.baseURL)/api/v1/auth/login"

            print("NetworkService: 🌐 準備發送登入 API 請求")
            print("NetworkService: 📡 URL: \(urlString)")
            print("NetworkService: 📧 Email: \(email)")

            guard let url = URL(string: urlString) else {
                print("NetworkService: ❌ 無效的 URL: \(urlString)")
                return promise(.failure(NetworkError.invalidURL))
            }

            let loginRequest = LoginRequest(email: email, password: password)

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")

            do {
                let jsonData = try JSONEncoder().encode(loginRequest)
                request.httpBody = jsonData

                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("NetworkService: 📤 請求 JSON:")
                    print(jsonString)
                }
            } catch {
                print("NetworkService: ❌ JSON 編碼錯誤: \(error)")
                return promise(.failure(error))
            }

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = 60.0
            let session = URLSession(configuration: configuration)

            session.dataTaskPublisher(for: request)
                .tryMap { output in
                    print("NetworkService: 📊 收到登入 HTTP 回應")
                    print("NetworkService: 🔢 狀態碼: \((output.response as? HTTPURLResponse)?.statusCode ?? 0)")
                    print("NetworkService: 📦 資料大小: \(output.data.count) bytes")

                    // 打印原始JSON以供調試
                    if let jsonString = String(data: output.data, encoding: .utf8) {
                        print("NetworkService: 🔍 登入 API 原始回應 JSON:")
                        print("--- JSON 開始 ---")
                        print(jsonString)
                        print("--- JSON 結束 ---")
                    }

                    if let httpResponse = output.response as? HTTPURLResponse {
                        guard httpResponse.statusCode == 200 else {
                            print("NetworkService: ❌ HTTP 錯誤，狀態碼: \(httpResponse.statusCode)")
                            throw NetworkError.httpError(httpResponse.statusCode)
                        }
                    }
                    return output.data
                }
                .decode(type: LoginResponse.self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print("NetworkService: ❌ 登入請求失敗: \(error)")
                        promise(.failure(error))
                    }
                } receiveValue: { response in
                    print("NetworkService: ✅ 登入請求成功")
                    print("NetworkService: 👤 用戶: \(response.data.displayName)")
                    print("NetworkService: 📧 Email: \(response.data.email)")
                    promise(.success(response))
                }
                .store(in: &self.cancellables)
        }
    }

    // MARK: - Favorites API
    func fetchFavorites(page: Int = 1, size: Int = 20) -> Future<RecipesAPIResponse, Error> {
        return Future<RecipesAPIResponse, Error> { [weak self] promise in
            guard let self = self else {
                return promise(.failure(NetworkError.unknown("Service unavailable")))
            }

            let urlString = "\(self.baseURL)/api/v1/favorites?page=\(page)&size=\(size)"

            print("NetworkService: 🌐 準備發送 Favorites API 請求")
            print("NetworkService: 📡 URL: \(urlString)")

            guard let url = URL(string: urlString) else {
                print("NetworkService: ❌ 無效的 URL: \(urlString)")
                return promise(.failure(NetworkError.invalidURL))
            }

            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForResource = 60.0
            let session = URLSession(configuration: configuration)

            var request = self.createAuthenticatedRequest(url: url)
            request.httpMethod = "GET"

            // 檢查是否有Authorization token
            if let authHeader = request.value(forHTTPHeaderField: "Authorization") {
                print("NetworkService: 🔐 Authorization: \(authHeader)")
            } else {
                print("NetworkService: ⚠️ 沒有 Authorization token")
            }

            session.dataTaskPublisher(for: request)
                .tryMap { (data, response) -> Data in
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw NetworkError.invalidResponse
                    }

                    print("NetworkService: 📊 收到 Favorites HTTP 回應")
                    print("NetworkService: 🔢 狀態碼: \(httpResponse.statusCode)")
                    print("NetworkService: 📦 資料大小: \(data.count) bytes")

                    // 列印原始 JSON 回應
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("NetworkService: 🔍 Favorites API 原始回應 JSON:")
                        print("--- JSON 開始 ---")
                        print(jsonString)
                        print("--- JSON 結束 ---")
                    } else {
                        print("NetworkService: ❌ 無法轉換回應為 UTF-8 字串")
                    }

                    switch httpResponse.statusCode {
                    case 200:
                        return data
                    case 401:
                        throw NetworkError.unknown("未授權：請重新登入")
                    case 403:
                        throw NetworkError.unknown("權限不足")
                    case 404:
                        throw NetworkError.unknown("找不到收藏資料")
                    case 500...599:
                        throw NetworkError.unknown("伺服器內部錯誤")
                    default:
                        throw NetworkError.httpError(httpResponse.statusCode)
                    }
                }
                .tryMap { data in
                    do {
                        let decoder = JSONDecoder()
                        print("NetworkService: 🔄 開始解析 Favorites JSON...")
                        let result = try decoder.decode(RecipesAPIResponse.self, from: data)
                        print("NetworkService: ✅ Favorites JSON 解析成功")
                        return result
                    } catch let decodingError as DecodingError {
                        print("NetworkService: ❌ Favorites JSON 解析錯誤詳情:")
                        print("錯誤: \(decodingError)")
                        throw NetworkError.unknown("JSON 解析失敗：\(decodingError.localizedDescription)")
                    } catch {
                        print("NetworkService: ❌ 其他 Favorites 解析錯誤: \(error)")
                        throw NetworkError.unknown("資料處理失敗：\(error.localizedDescription)")
                    }
                }
                .receive(on: RunLoop.main)
                .sink { completion in
                    if case let .failure(error) = completion {
                        print("NetworkService: ❌ Favorites 請求最終錯誤: \(error)")
                        promise(.failure(error))
                    }
                } receiveValue: { response in
                    print("NetworkService: ✅ Favorites API 請求成功")
                    print("NetworkService: 📦 收到 \(response.data.list.count) 個收藏食譜")
                    print("NetworkService: 📋 資料概要:")
                    print("  - API 狀態碼: \(response.code)")
                    print("  - 訊息: \(response.message)")
                    print("  - 總記錄數: \(response.data.total)")
                    promise(.success(response))
                }
                .store(in: &self.cancellables)
        }
    }

}
