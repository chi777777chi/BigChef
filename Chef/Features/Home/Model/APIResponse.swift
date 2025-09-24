//
//  APIResponse.swift
//  ChefHelper
//
//  Created by 羅辰澔 on 2025/5/8.
//

import Foundation

// MARK: - Recipe API Response Models
struct RecipesAPIResponse: Decodable {
    let code: Int
    let message: String
    let data: RecipesData
}

struct RecipesData: Decodable {
    let records: [Recipe]
    let total: Int
    let size: Int
    let current: Int
    let pages: Int
}

struct Recipe: Decodable, Identifiable {
    let id: String
    let name: String?
    let slug: String?
    let description: String?
    let imageUrl: String?
    let prepTime: String?
    let cookTime: String?
    let totalTime: String?
    let recipeYield: String?
    let rating: Double?
    let orgUrl: String?
    let notes: String?
    let visibility: Bool?
    let approvalStatus: String?
    let userId: String?
    let authorName: String?
    let reviewedBy: String?
    let reviewedAt: String?
    let createdAt: String?
    let updatedAt: String?

    // 自定義初始化器來處理 null 值
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // 處理 id 為 null 的情況 - 生成 UUID 作為後備
        if let decodedId = try container.decodeIfPresent(String.self, forKey: .id),
           !decodedId.isEmpty {
            self.id = decodedId
        } else {
            self.id = UUID().uuidString
            print("⚠️ Recipe ID 為 null 或空，使用生成的 UUID: \(self.id)")
        }

        // 解析其他可選欄位
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.slug = try container.decodeIfPresent(String.self, forKey: .slug)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.prepTime = try container.decodeIfPresent(String.self, forKey: .prepTime)
        self.cookTime = try container.decodeIfPresent(String.self, forKey: .cookTime)
        self.totalTime = try container.decodeIfPresent(String.self, forKey: .totalTime)
        self.recipeYield = try container.decodeIfPresent(String.self, forKey: .recipeYield)
        self.rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        self.orgUrl = try container.decodeIfPresent(String.self, forKey: .orgUrl)
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.visibility = try container.decodeIfPresent(Bool.self, forKey: .visibility)
        self.approvalStatus = try container.decodeIfPresent(String.self, forKey: .approvalStatus)
        self.userId = try container.decodeIfPresent(String.self, forKey: .userId)
        self.authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        self.reviewedBy = try container.decodeIfPresent(String.self, forKey: .reviewedBy)
        self.reviewedAt = try container.decodeIfPresent(String.self, forKey: .reviewedAt)
        self.createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
    }

    // 定義 CodingKeys
    private enum CodingKeys: String, CodingKey {
        case id, name, slug, description, imageUrl, prepTime, cookTime, totalTime
        case recipeYield, rating, orgUrl, notes, visibility, approvalStatus
        case userId, authorName, reviewedBy, reviewedAt, createdAt, updatedAt
    }

    // 計算屬性提供預設值和 UI 友善的資料
    var displayName: String {
        return name?.isEmpty == false ? name! : "未命名食譜"
    }

    var displayDescription: String {
        return description?.isEmpty == false ? description! : "暫無描述"
    }

    var displayImageUrl: String {
        return imageUrl?.isEmpty == false ? imageUrl! : "default-recipe-image"
    }

    var displayPrepTime: String {
        return prepTime?.isEmpty == false ? prepTime! : "未知"
    }

    var displayCookTime: String {
        return cookTime?.isEmpty == false ? cookTime! : "未知"
    }

    var displayTotalTime: String {
        return totalTime?.isEmpty == false ? totalTime! : "未知"
    }

    var displayYield: String {
        return recipeYield?.isEmpty == false ? recipeYield! : "未知份量"
    }

    var displayRating: Double {
        return rating ?? 0.0
    }

    var isApproved: Bool {
        return approvalStatus == "approved"
    }

    var hasValidImage: Bool {
        return imageUrl != nil && !imageUrl!.isEmpty
    }

    var isValid: Bool {
        // 檢查食譜是否有效（至少要有名稱）
        return displayName != "未命名食譜" && !displayName.isEmpty
    }

    var debugInfo: String {
        return """
        Recipe Debug Info:
        - ID: \(id)
        - Name: \(name ?? "nil")
        - Description: \(description ?? "nil")
        - ApprovalStatus: \(approvalStatus ?? "nil")
        - IsValid: \(isValid)
        - IsApproved: \(isApproved)
        """
    }
}

// MARK: - Home Page Data Structure (for organizing recipes)
struct AllDishes: Decodable {
    let categories: [DishCategory]
    var populars: [Dish]
    let specials: [Dish]
}

// MARK: - Dish Category Model (keep existing for categories)
struct DishCategory: Decodable, Identifiable {
    let id, name, image: String

    enum CodingKeys: String, CodingKey {
        case id
        case name = "title"
        case image
    }
}

// MARK: - Legacy Dish Model (converted from Recipe for existing UI)
struct Dish: Decodable, Identifiable {
    let id, name, description, image: String
    let rating: Double?

    // Convert Recipe to Dish for existing UI components
    init(from recipe: Recipe) {
        self.id = recipe.id
        self.name = recipe.displayName
        self.description = recipe.displayDescription
        self.image = recipe.displayImageUrl
        self.rating = recipe.rating
    }

    // Legacy init for mock data (will be removed)
    init(id: String, name: String, description: String, image: String, rating: Double? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.image = image
        self.rating = rating
    }
}

// MARK: - Legacy API Response (for backward compatibility during migration)
struct APIResponse: Decodable {
    let status: Int
    let message: String
    let data: AllDishes?
}

// MARK: - Preview Helpers
extension Recipe {
    static func createPreview() -> Recipe {
        // 建立模擬的 JSON 資料來創建預覽 Recipe
        let jsonData = """
        {
            "id": "1",
            "name": "香煎雞腿排",
            "slug": "pan-fried-chicken-thigh",
            "description": "嫩滑多汁的香煎雞腿排，外酥內嫩",
            "imageUrl": "https://picsum.photos/300/200?random=1",
            "prepTime": "15分鐘",
            "cookTime": "20分鐘",
            "totalTime": "35分鐘",
            "recipeYield": "2人份",
            "rating": 4.5,
            "orgUrl": null,
            "notes": "可配菜搭配食用",
            "visibility": true,
            "approvalStatus": "approved",
            "userId": "user1",
            "authorName": "大廚師",
            "reviewedBy": null,
            "reviewedAt": null,
            "createdAt": "2025-01-01T12:00:00Z",
            "updatedAt": "2025-01-01T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        return try! decoder.decode(Recipe.self, from: jsonData)
    }

    static let preview = createPreview()

    // Helper method to create Recipe from Dish (for fallback)
    static func createFromDish(_ dish: Dish) -> Recipe {
        let jsonData = """
        {
            "id": "\(dish.id)",
            "name": "\(dish.name)",
            "slug": null,
            "description": "\(dish.description)",
            "imageUrl": "\(dish.image)",
            "prepTime": null,
            "cookTime": null,
            "totalTime": null,
            "recipeYield": null,
            "rating": \(dish.rating ?? 0.0),
            "orgUrl": null,
            "notes": null,
            "visibility": true,
            "approvalStatus": "approved",
            "userId": null,
            "authorName": null,
            "reviewedBy": null,
            "reviewedAt": null,
            "createdAt": null,
            "updatedAt": null
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        return try! decoder.decode(Recipe.self, from: jsonData)
    }
}

extension Dish {
    static let preview = Dish(
        id: "1",
        name: "測試菜品",
        description: "這是一個測試用的菜品描述",
        image: "https://picsum.photos/200",
        rating: 4.5
    )
}

extension DishCategory {
    static let preview = DishCategory(
        id: "1",
        name: "測試分類",
        image: "https://picsum.photos/200"
    )
}

extension AllDishes {
    static let preview = AllDishes(
        categories: [
            DishCategory.preview,
            DishCategory(id: "2", name: "測試分類2", image: "https://picsum.photos/201")
        ],
        populars: [
            Dish.preview,
            Dish(id: "2", name: "測試菜品2", description: "描述2", image: "https://picsum.photos/202", rating: 4.2)
        ],
        specials: [
            Dish.preview,
            Dish(id: "3", name: "測試菜品3", description: "描述3", image: "https://picsum.photos/203", rating: 4.8)
        ]
    )
}

extension APIResponse {
    static let preview = APIResponse(
        status: 200,
        message: "Success",
        data: AllDishes.preview
    )
}
