//
//  RecipeRecommendationState.swift
//  ChefHelper
//
//  Created by Claude on 2025/9/22.
//

import Foundation

// MARK: - Recommendation Status Enum

enum RecipeRecommendationStatus {
    case idle              // 初始狀態
    case configuring       // 配置食材和器具中
    case loading           // 請求推薦中
    case success(RecipeRecommendationResponse)  // 成功獲得推薦
    case error(RecipeRecommendationError)       // 錯誤狀態
}

// NOTE: RecipeRecommendationError is now defined in RecipeRecommendationService.swift
// This ensures consistency across the recommendation flow

// MARK: - Recipe Recommendation State

class RecipeRecommendationState: ObservableObject {

    // MARK: - Published Properties
    @Published var status: RecipeRecommendationStatus = .idle
    @Published var retryCount: Int = 0

    // MARK: - Constants
    let maxRetryCount = 3

    // MARK: - Computed Properties

    var isLoading: Bool {
        if case .loading = status {
            return true
        }
        return false
    }

    var hasError: Bool {
        if case .error = status {
            return true
        }
        return false
    }

    var hasResult: Bool {
        if case .success = status {
            return true
        }
        return false
    }

    var currentError: RecipeRecommendationError? {
        if case .error(let error) = status {
            return error
        }
        return nil
    }

    var currentResult: RecipeRecommendationResponse? {
        if case .success(let response) = status {
            return response
        }
        return nil
    }

    var canRetry: Bool {
        guard let error = currentError else { return false }
        return error.isRetryable && retryCount < maxRetryCount
    }

    // MARK: - State Management Methods

    func startConfiguring() {
        status = .configuring
        retryCount = 0
    }

    func startLoading() {
        status = .loading
    }

    func handleSuccess(_ response: RecipeRecommendationResponse) {
        status = .success(response)
        retryCount = 0
    }

    func handleError(_ error: RecipeRecommendationError) {
        status = .error(error)
    }

    func incrementRetryCount() {
        retryCount += 1
    }

    func reset() {
        status = .idle
        retryCount = 0
    }

    func resetToConfiguring() {
        status = .configuring
        retryCount = 0
    }
}

// MARK: - Extensions

extension RecipeRecommendationStatus: Equatable {
    static func == (lhs: RecipeRecommendationStatus, rhs: RecipeRecommendationStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.configuring, .configuring),
             (.loading, .loading):
            return true
        case (.success(let lhsResponse), .success(let rhsResponse)):
            return lhsResponse.dishName == rhsResponse.dishName
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// RecipeRecommendationError Equatable conformance is already defined in RecipeRecommendationService.swift