//
//  HistoryViewModel.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/8.
//

import Foundation
import SwiftUI

struct DailyRecord: Identifiable {
    let id = UUID()
    let category: String    // e.g., "Breakfast"
    let item: String        // e.g., "Salad"
    let date: Date          // for filtering by selected day
}

final class HistoryViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var records: [DailyRecord] = []
    
    var categories: [String] {
        ["Breakfast", "Lunch", "Dinner", "Others"]
    }
    
    func records(for category: String) -> [DailyRecord] {
        records.filter { $0.category == category && Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    init() {
        loadSampleData()
    }
    
    private func loadSampleData() {
        let today = Date()
        
        records = [
            DailyRecord(category: "Breakfast", item: "salad", date: today),
            DailyRecord(category: "Lunch", item: "pizza", date: today),
            DailyRecord(category: "Dinner", item: "pasta", date: today),
            DailyRecord(category: "Others", item: "蛋糕", date: today),
        ]
    }
}
