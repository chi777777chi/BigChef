//
//  HistoryView.swift
//  ChefHelper
//
//  Created by 陳泓齊 on 2025/5/8.
//


import SwiftUI

struct HistoryView: View {
    @ObservedObject var viewModel: HistoryViewModel

    var body: some View {
        VStack(spacing: 16) {
            // 上方 Logo 與齒輪
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                Spacer()
                Image("QuickFeatLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 40)
            }
            .padding(.horizontal)

            // 月曆選擇器
            DatePicker(
                "選擇日期",
                selection: $viewModel.selectedDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .accentColor(.brandOrange)
            .padding(.horizontal)

            // 餐點紀錄清單
            List {
                ForEach(viewModel.categories, id: \.self) { category in
                    let records = viewModel.records(for: category)
                    if !records.isEmpty {
                        Section(header: Text(category)) {
                            ForEach(records) { record in
                                Text(record.item)
                            }
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .padding(.top, 16)
        
    }
}
#Preview {
    HistoryView(viewModel: HistoryViewModel())
        
}

