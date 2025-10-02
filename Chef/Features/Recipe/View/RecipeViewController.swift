//
//  RecipeViewController.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/4/24.
//

//
//  RecipeViewController.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/4/24.
//

import UIKit



class ViewController: UIViewController {
    // 發送 POST 請求的函數
    private static var baseURL: String {
        Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String ?? ""
    }


    @IBAction func request(_ sender: Any) {

        // 設定設備、食材和偏好

        let equipment = [Equipment(name: "平底鍋", type: "鍋具", size: "中型", material: "不鏽鋼", power_source: "電")]

        let ingredients = [

            Ingredient(name: "油", type: "食材", amount: "2", unit: "湯匙", preparation: "無"),

            Ingredient(name: "牛排", type: "食材", amount: "1", unit: "塊", preparation: "無")

        ]

        let preference = Preference(cooking_method: "煎", dietary_restrictions: ["無"], serving_size: "1人份")
        // 創建請求資料

        let request = SuggestRecipeRequest(available_ingredients: ingredients, available_equipment: equipment, preference: preference)

        // 呼叫 generateRecipe 函數發送請求

        generateRecipe(request: request)

    }
    override func viewDidLoad() {

        super.viewDidLoad()
    }


    
    func generateRecipe(request: SuggestRecipeRequest) {

        guard let url = URL(string: "http://\(ViewController.baseURL):8080/api/v1/recipe/suggest") else {
            print("無效的 URL")

            return

        }

        // 創建 URLRequest 物件

        var urlRequest = URLRequest(url: url)

        urlRequest.httpMethod = "POST"

        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // 將資料編碼為 JSON

        let encoder = JSONEncoder()

        do {

            let jsonData = try encoder.encode(request) // 編碼 RecipeRequest

            urlRequest.httpBody = jsonData

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("✅ 傳送的 JSON：\n\(jsonString)")
            }
        } catch {

            print("無法編碼請求資料：\(error)")

            return

        }

        // 使用 URLSession 發送請求

        let task = URLSession.shared.dataTask(with: urlRequest) { data, response, error in

            // 偵錯：檢查錯誤

            if let error = error as NSError? {

                print("錯誤：\(error.localizedDescription)")

                print("錯誤碼：\(error.code)") // 輸出錯誤碼

                return

            }
            // 偵錯：檢查回應

            if let httpResponse = response as? HTTPURLResponse {

                print("回應狀態碼：\(httpResponse.statusCode)")

                // 這裡可以根據 statusCode 判斷回應是否成功

                if httpResponse.statusCode != 200 {

                    print("伺服器回應錯誤，狀態碼：\(httpResponse.statusCode)")

                }

            }

            // 偵錯：檢查資料

            guard let data = data else {

                print("沒有收到回應資料")

                return

            }

            // 嘗試解析 JSON 回應

            do {

                let decoder = JSONDecoder()

                let recipeResponse = try decoder.decode(SuggestRecipeResponse.self, from: data)

                print("食譜名稱：\(recipeResponse.dish_name)")

                print("食譜描述：\(recipeResponse.dish_description)")

                for step in recipeResponse.recipe {
                    print("步驟：\(step.step_number), 溫度：\(step.temperature), 描述：\(step.description))")
                }

            } catch {

                print("解析 JSON 失敗：\(error)")

            }

        }

        // 偵錯：請求開始前

        print("發送請求：\(urlRequest)")

        // 啟動請求

        task.resume()

    }

}
