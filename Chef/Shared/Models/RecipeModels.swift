import Foundation

// MARK: - 食材模型，用於傳送與接收食材資訊
struct Ingredient: Codable, Identifiable, Equatable {
    var id = UUID()  // ✅ 本地唯一識別碼，只給 SwiftUI 用，不會進 JSON

    var name: String
    var type: String
    var amount: String
    var unit: String
    var preparation: String

    // ❌ 不讓 id 編碼或解碼
    private enum CodingKeys: String, CodingKey {
        case name, type, amount, unit, preparation
    }
}
// MARK: - 設備模型
struct Equipment: Codable, Identifiable, Equatable {
    var id = UUID()  // ✅ SwiftUI UI 更新用，不進 JSON

    var name: String
    var type: String
    var size: String
    var material: String
    var power_source: String

    private enum CodingKeys: String, CodingKey {
        case name, type, size, material, power_source
    }
}

// MARK: - 使用者偏好設定
struct Preference: Codable {
    var cooking_method: String         // 烹飪方式，例如「煎」
    var dietary_restrictions: [String] // 飲食限制，例如["無"]
    var serving_size: String           // 份量，例如「2人份」
    var recipe_description: String?    // 食譜敘述，例如「希望是簡單易做的家常菜」
}

// MARK: - 食譜推薦請求資料結構
struct SuggestRecipeRequest: Codable {
    var available_ingredients: [Ingredient] // 使用者提供的食材清單
    var available_equipment: [Equipment]    // 使用者提供的設備清單
    var preference: Preference              // 使用者烹飪偏好
}

// MARK: - 食譜推薦回傳資料結構
struct SuggestRecipeResponse: Codable {
    var dish_name: String             // 推薦的菜名
    var dish_description: String      // 菜色描述
    var ingredients: [Ingredient]     // 所需食材
    var  equipment: [Equipment]        // 所需設備
    var recipe: [RecipeStep]          // 食譜步驟清單
}

// MARK: - AR 動畫類型（與後端 API 對應）
enum ARAnimationType: String, Codable {
    case putIntoContainer
    case stir
    case pourLiquid
    case flipPan
    case countdown
    case temperature
    case flame
    case sprinkle
    case torch
    case cut
    case peel
    case flip
    case beatEgg
}

// MARK: - AR 動畫參數（與後端 API 對應）
struct ARAnimationParams: Codable {
    var coordinate: [Double]?
    var container: String?
    var ingredient: String?
    var color: String?
    var time: Double?
    var temperature: Double?
    var flameLevel: String?

    // ✅ 忽略後端的 "type" 欄位（已經在 arType 中）
    private enum CodingKeys: String, CodingKey {
        case coordinate
        case container
        case ingredient
        case color
        case time
        case temperature
        case flameLevel
        // 不包含 "type" 以忽略它
    }
}

// MARK: - 食譜步驟，每一個步驟都包含標題與操作清單
struct RecipeStep: Codable, Identifiable {
    var id: Int { step_number }       // SwiftUI 識別用，使用步驟編號
    var step_number: Int              // 步驟編號
    var title: String                 // 步驟標題
    var description: String           // 步驟敘述
    var actions: [Action]             // 操作細節清單
    var estimated_total_time: String  // 預估總時間（含準備與烹飪）
    var temperature: String           // 火侯說明
    var warnings: String?             // 警告（可為 null）
    var notes: String                 // 備註
    var arType: ARAnimationType?      // AR 動畫類型（可選）
    var arParameters: ARAnimationParams?  // AR 動畫參數（可選）

    // ✅ 映射後端的命名到 Swift 駝峰命名
    private enum CodingKeys: String, CodingKey {
        case step_number
        case title
        case description
        case actions
        case estimated_total_time
        case temperature
        case warnings
        case notes
        case arType = "ARtype"              // 後端是 "ARtype"
        case arParameters = "ar_parameters" // 後端是 "ar_parameters"
    }
}

// MARK: - 單一操作細節（屬於 RecipeStep 內的一部分）
struct Action: Codable {
    var action: String                 // 動作名稱，例如「翻炒」
    var tool_required: String          // 所需工具
    var material_required: [String]    // 所需材料名稱列表
    var time_minutes: Int              // 時間（分鐘）
    var instruction_detail: String     // 詳細說明
}

// MARK: - 圖片掃描請求資料結構
struct ScanImageRequest: Codable {
    var image: String              // Base64 編碼的圖片數據
    var description_hint: String   // 描述提示，例如"蔬菜和鍋子"
}

// MARK: - 圖片掃描回傳資料結構
struct ScanImageResponse: Codable {
    var ingredients: [Ingredient]  // 識別出的食材清單
    var equipment: [Equipment]     // 識別出的設備清單
    var summary: String           // 掃描結果摘要
}
