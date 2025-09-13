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
}

final class NetworkService: NetworkServiceProtocol {

    private var cancellables = Set<AnyCancellable>()

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

}
